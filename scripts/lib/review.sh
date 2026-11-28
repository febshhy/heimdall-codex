# Candidate-bound review support. The factory remains the owner of Git effects
# and lifecycle state; this file validates the review evidence at that boundary.
REVIEW_CONTRACT='candidate-bound/v1'

review_hash(){ sha256sum "$1" | cut -d' ' -f1; }
review_hash_text(){ sha256sum | cut -d' ' -f1; }
review_canonical_hash(){ jq -cS . "$1" | review_hash_text; }
review_abs(){ case "$1" in /*) printf '%s\n' "$1";; *) printf '%s/%s\n' "$PWD" "$1";; esac; }
review_descendants(){
  jq -c --arg id "$2" '
    def descendants($nodes;$frontier;$seen):
      if ($frontier|length)==0 then $seen else
        ([$nodes[]|select(any(.depends_on[]; . as $d | ($frontier|index($d))!=null))|.id]|unique-$seen) as $next |
        descendants($nodes;$next;($seen+$next)|unique)
      end;
    .planned_nodes as $nodes | descendants($nodes;[$id];[])' "$1"
}
review_contains(){ jq -e --arg id "$2" 'index($id)!=null' <<<"$1" >/dev/null; }
review_validate_ordering(){
  local plan=$1 write gates gate descendants precursors downstream node mode
  while IFS= read -r write; do
    gates=$(jq -c --arg write "$write" '[.planned_nodes[]|select(.gate=="review" and .verifies==[$write])|.id]' "$plan")
    [[ $(jq 'length' <<<"$gates") -gt 0 ]] || continue
    descendants=$(review_descendants "$plan" "$write")
    while IFS= read -r node; do
      review_contains "$gates" "$node" && continue
      mode=$(jq -r --arg id "$node" '.planned_nodes[]|select(.id==$id)|.mode' "$plan")
      precursors=true; downstream=true
      if [[ $mode == WRITE ]]; then precursors=false; fi
      local node_desc; node_desc=$(review_descendants "$plan" "$node")
      while IFS= read -r gate; do
        review_contains "$node_desc" "$gate" || precursors=false
        local gate_desc; gate_desc=$(review_descendants "$plan" "$gate")
        review_contains "$gate_desc" "$node" || downstream=false
      done < <(jq -r '.[]' <<<"$gates")
      [[ $precursors == true || $downstream == true ]] || fail CONTRACT "node $node can consume WRITE $write before its review gate"
    done < <(jq -r '.[]' <<<"$descendants")
  done < <(jq -r '.planned_nodes[]|select(.mode=="WRITE")|.id' "$plan")
}
review_check_ignored(){
  local root=$1 path=$2 absolute rel
  absolute=$(review_abs "$path")
  case "$absolute" in "$root"/*)
    rel=${absolute#"$root"/}
    git -C "$root" check-ignore -q -- "$rel" || fail INTEGRITY 'candidate review artifacts inside the worktree must be Git-ignored'
    ;;
  esac
}

review_identity(){
  jq -cS 'del(.identity_sha256,.captured_utc,.diff_path)' "$1" | review_hash_text
}

review_capture_once(){
  local root=$1 base=$2 write_node=$3 diffout=$4 output=$5
  local head index_tree tree status_file staged_file unstaged_file changed_file conflicts=0 item xy
  head=$(git -C "$root" rev-parse --verify HEAD^{commit}) || fail CANDIDATE 'HEAD is not a commit'
  base=$(git -C "$root" rev-parse --verify "$base^{commit}") || fail CANDIDATE 'base is not a commit'
  git -C "$root" merge-base --is-ancestor "$base" "$head" || fail CANDIDATE 'base is not an ancestor of HEAD'
  status_file=$(mktemp); staged_file=$(mktemp); unstaged_file=$(mktemp); changed_file=$(mktemp)
  git -C "$root" -c core.quotePath=false status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none >"$status_file" || fail CANDIDATE 'cannot inspect worktree status'
  while IFS= read -r -d '' item; do
    xy=${item:0:2}
    case "$xy" in *U*|AA|DD) conflicts=1;; esac
  done <"$status_file"
  [[ $conflicts -eq 0 ]] || fail CANDIDATE 'candidate has unresolved merge conflicts'
  index_tree=$(git -C "$root" write-tree) || fail CANDIDATE 'index is unmerged or cannot be written as a tree'
  git -C "$root" diff --cached --binary --full-index HEAD -- >"$staged_file" || fail CANDIDATE 'cannot capture staged diff'
  git -C "$root" diff --binary --full-index -- >"$unstaged_file" || fail CANDIDATE 'cannot capture unstaged diff'
  local staged_sha unstaged_sha status_sha
  staged_sha=$(review_hash "$staged_file"); unstaged_sha=$(review_hash "$unstaged_file"); status_sha=$(review_hash "$status_file")
  local tmpdir tmpindex
  tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/heimdall-candidate.XXXXXX")
  tmpindex="$tmpdir/index"
  # Seed from the real index tree so force-added ignored paths remain in the
  # prospective candidate even though a fresh index based on HEAD would omit them.
  GIT_INDEX_FILE="$tmpindex" git -C "$root" read-tree "$index_tree" || fail CANDIDATE 'cannot initialize temporary candidate index'
  GIT_INDEX_FILE="$tmpindex" git -C "$root" add --all -- || fail CANDIDATE 'cannot build prospective tree from worktree'
  tree=$(GIT_INDEX_FILE="$tmpindex" git -C "$root" write-tree) || fail CANDIDATE 'cannot write prospective candidate tree'
  git -C "$root" diff --no-ext-diff --binary --full-index "$base" "$tree" -- >"$diffout" || fail CANDIDATE 'cannot produce candidate diff'
  git -C "$root" diff --no-ext-diff --name-only -z --no-renames "$base" "$tree" -- >"$changed_file" || fail CANDIDATE 'cannot list candidate paths'
  local changed_json diff_sha dirty commit_sha commit_parent node_task
  changed_json=$(jq -Rs 'split("\u0000")[:-1]' <"$changed_file")
  diff_sha=$(review_hash "$diffout")
  dirty=false; commit_sha=$(jq -cn --arg c "$head" '$c'); commit_parent=null
  if [[ -s "$status_file" || $(git -C "$root" rev-parse "$head^{tree}") != "$tree" ]]; then dirty=true; commit_sha=null; fi
  if [[ $dirty == false ]]; then
    local parent; parent=$(git -C "$root" rev-parse --verify "$head^1" 2>/dev/null || :)
    [[ -n $parent ]] && commit_parent=$(jq -cn --arg p "$parent" '$p')
  fi
  node_task=$(jq -ce --arg id "$write_node" '.planned_nodes[]|select(.id==$id and .mode=="WRITE")' "$GRAPH") || fail REVIEW 'candidate write node is not a WRITE node in this graph'
  jq -ne --argjson paths "$changed_json" --argjson task "$node_task" '
    all($paths[]; . as $p | any($task.write_set[]; . as $s | $p==$s or ($s|endswith("/") and ($p|startswith($s)))))' >/dev/null || fail SCOPE 'candidate diff includes paths outside the WRITE node scope'
  jq -n -S --arg root "$root" --arg base "$base" --arg head "$head" --arg index_tree "$index_tree" \
    --arg staged "$staged_sha" --arg unstaged "$unstaged_sha" --arg status "$status_sha" \
    --arg tree "$tree" --argjson paths "$changed_json" --arg write_node "$write_node" \
    --argjson dirty "$dirty" --argjson commit "$commit_sha" --argjson parent "$commit_parent" \
    --arg diff_path "$(review_abs "$diffout")" --arg diff_sha "$diff_sha" --arg captured "$(date -u +%FT%TZ)" \
    '{schema_version:1,root:$root,base_sha:$base,head_sha:$head,index_tree:$index_tree,
      staged_diff_sha256:$staged,unstaged_diff_sha256:$unstaged,status_sha256:$status,
      tree_sha:$tree,changed_paths:$paths,write_node:$write_node,dirty:$dirty,
      commit_sha:$commit,commit_parent:$parent,diff_path:$diff_path,diff_sha256:$diff_sha,captured_utc:$captured}' >"$output"
  local identity; identity=$(review_identity "$output")
  jq -cS --arg id "$identity" '. + {identity_sha256:$id}' "$output" >"$output.tmp"
  mv -f -- "$output.tmp" "$output"
  rm -rf -- "$tmpdir"; rm -f -- "$status_file" "$staged_file" "$unstaged_file" "$changed_file"
}

review_candidate_capture(){
  local root base write_node out diffout first second firstdiff seconddiff
  root=$(repo "$ROOT"); base=${BASE:-}; write_node=${NODE:-}; out=${MANIFEST:-}; diffout=${DIFF_OUT:-}
  [[ -n $base && -n $write_node && -n $out && -n $diffout ]] || fail USAGE 'candidate-capture requires --base, --node, --manifest, and --diff-out'
  review_check_ignored "$root" "$out"; review_check_ignored "$root" "$diffout"
  first=$(mktemp); second=$(mktemp); firstdiff=$(mktemp); seconddiff=$(mktemp)
  review_capture_once "$root" "$base" "$write_node" "$firstdiff" "$first"
  review_capture_once "$root" "$base" "$write_node" "$seconddiff" "$second"
  [[ $(jq -r .identity_sha256 "$first") == "$(jq -r .identity_sha256 "$second")" && $(review_hash "$firstdiff") == "$(review_hash "$seconddiff")" ]] || fail STALE 'candidate changed during capture'
  mkdir -p "$(dirname "$out")" "$(dirname "$diffout")"
  cp -- "$seconddiff" "$diffout"
  local outtmp; outtmp=$(mktemp "${out}.tmp.XXXXXX")
  jq -cS --arg path "$(review_abs "$diffout")" '.diff_path=$path' "$second" >"$outtmp"
  mv -f -- "$outtmp" "$out"
  rm -f -- "$first" "$second" "$firstdiff" "$seconddiff"
  echo "CANDIDATE: $out"
}

# Freeze the prospective tree at a successful WRITE boundary. Capture twice,
# then confirm the ordinary before/after snapshot still describes the same
# worktree. The real index is only read; the prospective tree uses the same
# temporary-index algorithm as review candidates.
review_write_finish_binding(){
  local root=$1 base=$2 write_node=$3 expected_snapshot=$4 changed_file=$5
  local first second firstdiff seconddiff current_snapshot first_identity second_identity
  first=$(mktemp); second=$(mktemp); firstdiff=$(mktemp); seconddiff=$(mktemp); current_snapshot=$(mktemp)
  review_capture_once "$root" "$base" "$write_node" "$firstdiff" "$first"
  review_capture_once "$root" "$base" "$write_node" "$seconddiff" "$second"
  first_identity=$(jq -r .identity_sha256 "$first"); second_identity=$(jq -r .identity_sha256 "$second")
  [[ $first_identity == "$second_identity" && $(review_hash "$firstdiff") == "$(review_hash "$seconddiff")" ]] || fail STALE 'WRITE candidate changed during finish capture'
  snapshot "$root" >"$current_snapshot"
  [[ $(review_canonical_hash "$current_snapshot") == "$(review_canonical_hash "$expected_snapshot")" ]] || fail STALE 'WRITE worktree moved during finish capture'
  local candidate_paths snapshot_paths
  candidate_paths=$(jq -cS '.changed_paths|sort' "$second"); snapshot_paths=$(jq -cS 'sort' "$changed_file")
  [[ $candidate_paths == "$snapshot_paths" ]] || fail STALE "WRITE finish paths differ from stable snapshot scope: candidate=$candidate_paths snapshot=$snapshot_paths"
  local binding identity
  binding=$(jq -cn --slurpfile capture "$second" --arg root "$root" \
    --arg snapshot_sha "$(review_hash "$current_snapshot")" \
    '{schema_version:1,root:$root,base_sha:$capture[0].base_sha,head_sha:$capture[0].head_sha,
      tree_sha:$capture[0].tree_sha,index_tree:$capture[0].index_tree,
      changed_paths:$capture[0].changed_paths,status_sha256:$capture[0].status_sha256,
      staged_diff_sha256:$capture[0].staged_diff_sha256,unstaged_diff_sha256:$capture[0].unstaged_diff_sha256,
      snapshot_sha256:$snapshot_sha,capture_identity_sha256:$capture[0].identity_sha256}')
  identity=$(jq -cS . <<<"$binding" | review_hash_text)
  jq -cS --arg identity "$identity" '. + {identity_sha256:$identity}' <<<"$binding"
  rm -f -- "$first" "$second" "$firstdiff" "$seconddiff" "$current_snapshot"
}

review_validate_write_finish(){
  local receipt=$1 node=$2 binding expected identity write_task snapshot_sha
  jq -e '.finish_tree|type=="object" and
    (keys|sort)==["base_sha","capture_identity_sha256","changed_paths","head_sha","identity_sha256","index_tree","root","schema_version","snapshot_sha256","staged_diff_sha256","status_sha256","tree_sha","unstaged_diff_sha256"] and
    .schema_version==1 and (.root|type=="string") and (.base_sha|test("^[a-f0-9]{40,64}$")) and
    (.head_sha|test("^[a-f0-9]{40,64}$")) and (.tree_sha|test("^[a-f0-9]{40,64}$")) and
    (.index_tree|test("^[a-f0-9]{40,64}$")) and (.identity_sha256|test("^[a-f0-9]{64}$")) and
    (.capture_identity_sha256|test("^[a-f0-9]{64}$")) and (.snapshot_sha256|test("^[a-f0-9]{64}$")) and
    (.status_sha256|test("^[a-f0-9]{64}$")) and (.staged_diff_sha256|test("^[a-f0-9]{64}$")) and
    (.unstaged_diff_sha256|test("^[a-f0-9]{64}$")) and
    (.changed_paths|type=="array" and all(.[];type=="string") and (unique|length)==length)' "$receipt" >/dev/null || fail REVIEW 'WRITE finish tree binding is missing or malformed'
  binding=$(jq -cS '.finish_tree|del(.identity_sha256)' "$receipt")
  expected=$(jq -cS . <<<"$binding" | review_hash_text)
  identity=$(jq -r '.finish_tree.identity_sha256' "$receipt")
  [[ $expected == "$identity" ]] || fail INTEGRITY 'WRITE finish tree identity digest mismatch'
  snapshot_sha=$(jq -cS '.after' "$receipt" | review_hash_text)
  [[ $snapshot_sha == "$(jq -r '.finish_tree.snapshot_sha256' "$receipt")" ]] || fail INTEGRITY 'WRITE finish snapshot digest mismatch'
  write_task=$(jq -ce --arg id "$node" '.planned_nodes[]|select(.id==$id and .mode=="WRITE")' "$GRAPH") || fail REVIEW 'finish tree belongs to a non-WRITE node'
  jq -e --argjson task "$write_task" '
    .finish_tree.root==.worktree and .finish_tree.base_sha==.before.head and
    .finish_tree.head_sha==.after.head and .before.head==.after.head and
    (.finish_tree.changed_paths|sort)==(.changed|sort) and
    all(.finish_tree.changed_paths[]; . as $p | any($task.write_set[]; . as $s | $p==$s or ($s|endswith("/") and ($p|startswith($s)))))' "$receipt" >/dev/null || fail SCOPE 'WRITE finish tree does not match its receipt scope or boundary'
}

review_candidate_bind(){
  local input=$1 commit=$2 output=$3 root capture_head tree base commit_tree parents parent identity tmp
  [[ -f $input ]] || fail CANDIDATE 'candidate manifest missing'
  root=$(jq -er '.root|select(type=="string")' "$input") || fail CANDIDATE 'candidate manifest has no root'
  review_check_ignored "$root" "$output"
  capture_head=$(jq -er '.head_sha|select(type=="string")' "$input") || fail CANDIDATE 'candidate manifest has no capture HEAD'
  tree=$(jq -er '.tree_sha|select(type=="string")' "$input") || fail CANDIDATE 'candidate manifest has no tree'
  base=$(jq -er '.base_sha|select(type=="string")' "$input") || fail CANDIDATE 'candidate manifest has no base'
  [[ $(review_identity "$input") == "$(jq -r .identity_sha256 "$input")" ]] || fail INTEGRITY 'candidate identity digest mismatch'
  [[ -f $(jq -r .diff_path "$input") && $(review_hash "$(jq -r .diff_path "$input")") == "$(jq -r .diff_sha256 "$input")" ]] || fail INTEGRITY 'candidate diff is missing or changed'
  [[ $(jq -r .dirty "$input") == true && $(jq -r .commit_sha "$input") == null ]] || fail CANDIDATE 'only an unbound dirty candidate can be bound'
  commit=$(git -C "$root" rev-parse --verify "$commit^{commit}") || fail CANDIDATE 'binding target is not a commit'
  commit_tree=$(git -C "$root" rev-parse "$commit^{tree}")
  [[ $commit_tree == "$tree" ]] || fail STALE 'commit tree differs from captured candidate tree'
  parents=$(git -C "$root" rev-list --parents -n 1 "$commit")
  read -r _ parent extra <<<"$parents"
  [[ -n ${parent:-} && -z ${extra:-} && $parent == "$capture_head" ]] || fail STALE 'commit must have exactly the captured HEAD as its parent'
  git -C "$root" merge-base --is-ancestor "$base" "$parent" || fail STALE 'candidate base is not an ancestor of the commit parent'
  tmp=$(mktemp)
  jq -cS --arg commit "$commit" --arg parent "$parent" '. + {commit_sha:$commit,commit_parent:$parent,dirty:false}' "$input" >"$tmp"
  identity=$(review_identity "$tmp")
  local outtmp; outtmp=$(mktemp "${output}.tmp.XXXXXX")
  jq -cS --arg id "$identity" '. + {identity_sha256:$id}' "$tmp" >"$outtmp"
  mv -f -- "$outtmp" "$output"; rm -f -- "$tmp"
  echo "BOUND: $output"
}

review_validate_candidate(){
  local candidate=$1 expected_node=$2 task write_task root diffpath identity expected_diff commit tree parent actual_head actual_tree status_tmp rec xy
  [[ -f $candidate ]] || fail REVIEW 'candidate manifest is missing'
  jq -e '(keys|sort)==["base_sha","captured_utc","changed_paths","commit_parent","commit_sha","diff_path","diff_sha256","dirty","head_sha","identity_sha256","index_tree","root","schema_version","staged_diff_sha256","status_sha256","tree_sha","unstaged_diff_sha256","write_node"] and
    .schema_version==1 and (.root|type=="string") and (.base_sha|test("^[a-f0-9]{40,64}$")) and
    (.head_sha|test("^[a-f0-9]{40,64}$")) and (.tree_sha|test("^[a-f0-9]{40,64}$")) and
    (.index_tree|test("^[a-f0-9]{40,64}$")) and (.identity_sha256|test("^[a-f0-9]{64}$")) and
    (.staged_diff_sha256|test("^[a-f0-9]{64}$")) and (.unstaged_diff_sha256|test("^[a-f0-9]{64}$")) and
    (.status_sha256|test("^[a-f0-9]{64}$")) and (.diff_sha256|test("^[a-f0-9]{64}$")) and
    (.diff_path|type=="string" and length>0) and (.changed_paths|type=="array" and all(.[];type=="string") and (unique|length)==length) and
    (.write_node|type=="string") and (.dirty|type=="boolean") and
    (if .dirty then .commit_sha==null and .commit_parent==null else (.commit_sha|test("^[a-f0-9]{40,64}$")) and (.commit_parent==null or (.commit_parent|test("^[a-f0-9]{40,64}$"))) end)' "$candidate" >/dev/null || fail REVIEW 'candidate manifest is malformed'
  identity=$(review_identity "$candidate"); expected=$(jq -r .identity_sha256 "$candidate")
  [[ $identity == "$expected" ]] || fail INTEGRITY 'candidate identity digest mismatch'
  jq -e --arg node "$expected_node" '.write_node==$node' "$candidate" >/dev/null || fail REVIEW 'candidate is bound to a different WRITE node'
  root=$(jq -r .root "$candidate"); root=$(repo "$root")
  [[ $root == "$ROOT" ]] || fail REVIEW 'candidate belongs to another worktree'
  diffpath=$(jq -r .diff_path "$candidate"); [[ -f $diffpath ]] || fail REVIEW 'candidate diff is missing'
  review_check_ignored "$root" "$diffpath"
  expected_diff=$(jq -r .diff_sha256 "$candidate"); [[ $(review_hash "$diffpath") == "$expected_diff" ]] || fail INTEGRITY 'candidate diff digest mismatch'
  task=$(jq -ce --arg id "$expected_node" '.planned_nodes[]|select(.id==$id)' "$GRAPH")
  write_task=$(jq -ce --arg id "$expected_node" '.planned_nodes[]|select(.id==$id and .mode=="WRITE")' "$GRAPH") || fail REVIEW 'candidate target is not a WRITE node'
  jq -e --argjson task "$write_task" 'all(.changed_paths[]; . as $p | any($task.write_set[]; . as $s | $p==$s or ($s|endswith("/") and ($p|startswith($s)))))' "$candidate" >/dev/null || fail SCOPE 'candidate paths exceed WRITE scope'
  verify_done "$expected_node"
  local write_receipt write_base write_head write_changed finish_tree candidate_head candidate_parent
  write_receipt=$(receiptfile "$expected_node")
  write_base=$(jq -r '.before.head' "$write_receipt"); write_head=$(jq -r '.after.head' "$write_receipt")
  write_changed=$(jq -cS '.changed|sort' "$write_receipt")
  finish_tree=$(jq -r '.finish_tree.tree_sha' "$write_receipt")
  [[ $(jq -r .base_sha "$candidate") == "$write_base" ]] || fail STALE 'candidate base differs from WRITE receipt start HEAD'
  [[ $(jq -r .tree_sha "$candidate") == "$finish_tree" ]] || fail STALE 'candidate tree differs from the WRITE finish tree'
  candidate_head=$(jq -r .head_sha "$candidate"); candidate_parent=$(jq -r .commit_parent "$candidate")
  if [[ $(jq -r .commit_sha "$candidate") == null ]]; then
    [[ $candidate_head == "$write_head" ]] || fail STALE 'dirty candidate HEAD differs from WRITE receipt finish HEAD'
  else
    [[ $candidate_parent == "$write_head" ]] || fail STALE 'committed candidate parent differs from WRITE receipt finish HEAD'
  fi
  jq -e --argjson receipt_paths "$write_changed" '(.changed_paths|sort)==$receipt_paths' "$candidate" >/dev/null || fail SCOPE 'candidate paths differ from the WRITE finish scope'
  local candidate_commit; candidate_commit=$(jq -r .commit_sha "$candidate")
  if [[ $candidate_commit != null ]]; then
    commit=$(git -C "$root" rev-parse --verify "$candidate_commit^{commit}") || fail STALE 'candidate commit is unavailable'
    tree=$(git -C "$root" rev-parse "$commit^{tree}"); parent=$(git -C "$root" rev-parse "$commit^1" 2>/dev/null || :)
    [[ $tree == "$(jq -r .tree_sha "$candidate")" ]] || fail STALE 'candidate commit tree changed'
    if [[ $(jq -r .dirty "$candidate") == false && $commit == "$(jq -r .head_sha "$candidate")" ]]; then
      actual_head=$(git -C "$root" rev-parse HEAD)
      [[ $actual_head == "$commit" ]] || fail STALE 'committed candidate is no longer HEAD'
      status_tmp=$(mktemp); git -C "$root" status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none >"$status_tmp"
      [[ ! -s $status_tmp ]] || { rm -f "$status_tmp"; fail STALE 'committed candidate worktree is no longer clean'; }
      rm -f "$status_tmp"
    else
      [[ $parent == "$(jq -r .head_sha "$candidate")" ]] || fail STALE 'bound commit parent differs from captured HEAD'
      actual_head=$(git -C "$root" rev-parse HEAD); [[ $actual_head == "$commit" ]] || fail STALE 'bound candidate commit is no longer HEAD'
      status_tmp=$(mktemp); git -C "$root" status --porcelain=v1 -z --untracked-files=all --ignore-submodules=none >"$status_tmp"
      [[ ! -s $status_tmp ]] || { rm -f "$status_tmp"; fail STALE 'bound candidate worktree is not clean'; }
      rm -f "$status_tmp"
    fi
  else
    actual_head=$(git -C "$root" rev-parse HEAD); [[ $actual_head == "$(jq -r .head_sha "$candidate")" ]] || fail STALE 'dirty candidate HEAD moved'
    local checkdiff checkmanifest fresh_identity; checkdiff=$(mktemp); checkmanifest=$(mktemp)
    review_capture_once "$root" "$(jq -r .base_sha "$candidate")" "$expected_node" "$checkdiff" "$checkmanifest"
    # The fresh capture identity includes status, index, staged/unstaged bytes and prospective tree.
    fresh_identity=$(jq -r .identity_sha256 "$checkmanifest")
    rm -f "$checkdiff" "$checkmanifest"
    [[ $fresh_identity == "$expected" ]] || fail STALE 'dirty candidate changed after capture'
  fi
  git -C "$root" merge-base --is-ancestor "$(jq -r .base_sha "$candidate")" "$(jq -r .head_sha "$candidate")" || fail STALE 'candidate base is no longer an ancestor'
}

review_validate_checks(){
  local candidate=$1 checks=$2 node=$3 expected_candidate root log rel sha argv_json
  [[ -f $checks ]] || fail REVIEW 'check evidence is missing'
  jq -e '(keys|sort)==["candidate_identity","candidate_manifest_sha256","checks","schema_version"] and .schema_version==1 and (.candidate_identity|type=="string") and (.candidate_manifest_sha256|type=="string") and (.checks|type=="array") and (.checks|length>0)' "$checks" >/dev/null || fail REVIEW 'check evidence is malformed'
  expected_candidate=$(jq -r .identity_sha256 "$candidate")
  jq -e --arg id "$expected_candidate" --arg sha "$(review_hash "$candidate")" '.candidate_identity==$id and .candidate_manifest_sha256==$sha' "$checks" >/dev/null || fail STALE 'check evidence belongs to another candidate'
  root=$(jq -r .root "$candidate")
  while IFS= read -r -d '' rel; do
    [[ $rel != /* && -f "$root/$rel" && ! -L "$root/$rel" ]] && [[ ! "/$rel/" == *"/../"* ]] || fail REVIEW 'check log path is invalid or missing'
    local resolved; resolved=$(readlink -f -- "$root/$rel") || fail REVIEW 'cannot resolve check log path'
    case "$resolved" in "$root"/*) :;; *) fail REVIEW 'check log resolves outside candidate worktree';; esac
    sha=$(jq -r --arg rel "$rel" '.checks[]|select(.log_path==$rel)|.log_sha256' "$checks")
    [[ $(review_hash "$root/$rel") == "$sha" ]] || fail INTEGRITY 'check log digest mismatch'
  done < <(jq -rj '.checks[] | .log_path,"\u0000"' "$checks")
  jq -e 'all(.checks[]; (keys|sort)==["argv","exit_code","log_path","log_sha256"] and (.argv|type=="array" and length>0 and all(.[]; type=="string")) and .exit_code==0 and (.log_path|type=="string") and (.log_sha256|test("^[a-f0-9]{64}$"))) and ([.checks[].argv]|unique|length)==(.checks|length) and ([.checks[].log_path]|unique|length)==(.checks|length)' "$checks" >/dev/null || fail REVIEW 'check evidence has an invalid, duplicate, or failed result'
  local expected actual
  expected=$(jq -cS --arg node "$node" '.planned_nodes[]|select(.id==$node)|.delegation.R.verification|unique|sort' "$GRAPH")
  actual=$(jq -cS '[.checks[].argv]|unique|sort' "$checks")
  [[ $expected == "$actual" ]] || fail REVIEW 'check evidence argv set differs from declared verification inputs'
}

review_preflight(){
  local node=$1 candidate=$2 checks=$3 verdict=$4 task owner write_node writer_owner evidence_sha checks_sha candidate_sha verdict_sha
  [[ -f $candidate && -f $checks && -f $verdict ]] || fail REVIEW 'candidate, check evidence, and verdict are required before a review command can start'
  local root; root=$(jq -er '.root|select(type=="string")' "$candidate") || fail REVIEW 'candidate root is missing'
  review_check_ignored "$root" "$candidate"; review_check_ignored "$root" "$checks"; review_check_ignored "$root" "$verdict"
  task=$(jq -ce --arg id "$node" '.planned_nodes[]|select(.id==$id and .gate=="review")' "$GRAPH") || fail REVIEW 'review prerequisites supplied for a non-review node'
  owner=$(jq -r .owner <<<"$task")
  local verifies; verifies=$(jq -r '.verifies[]' <<<"$task"); [[ $(wc -l <<<"$verifies") -eq 1 ]] || fail REVIEW 'a review gate must verify exactly one WRITE node'
  write_node=$verifies; writer_owner=$(jq -r --arg id "$write_node" '.planned_nodes[]|select(.id==$id)|.owner' "$GRAPH")
  [[ $owner != "$writer_owner" ]] || fail REVIEW 'reviewer owner must differ from WRITE owner'
  review_validate_candidate "$candidate" "$write_node"
  review_validate_checks "$candidate" "$checks" "$node"
  candidate_sha=$(review_hash "$candidate"); checks_sha=$(review_hash "$checks"); evidence_sha=$(jq -r .diff_sha256 "$candidate")
  jq -e --arg node "$node" --arg writer "$write_node" --arg owner "$owner" \
    --arg identity "$(jq -r .identity_sha256 "$candidate")" --arg candidate_sha "$candidate_sha" \
    --arg evidence_sha "$evidence_sha" --arg checks_sha "$checks_sha" '
    (keys|sort)==["candidate_identity","candidate_manifest_sha256","checks_sha256","evidence_sha256","findings","node_id","reviewer_owner","schema_version","verdict","write_node"] and
    .schema_version==1 and .verdict=="accept" and .node_id==$node and .write_node==$writer and
    .reviewer_owner==$owner and .candidate_identity==$identity and .candidate_manifest_sha256==$candidate_sha and
    .evidence_sha256==$evidence_sha and .checks_sha256==$checks_sha and (.findings|type=="array")' "$verdict" >/dev/null || fail REVIEW 'verdict is rejected, malformed, or bound to different evidence'
  jq -cn --arg write_node "$write_node" --arg reviewer "$owner" \
    --arg identity "$(jq -r .identity_sha256 "$candidate")" --arg candidate_sha "$candidate_sha" \
    --arg evidence_sha "$evidence_sha" --arg checks_sha "$checks_sha" \
    --arg verdict_sha "$(review_hash "$verdict")" \
    '{write_node:$write_node,reviewer_owner:$reviewer,verdict:"accept",candidate_identity:$identity,
      candidate_manifest_sha256:$candidate_sha,evidence_sha256:$evidence_sha,checks_sha256:$checks_sha,
      verdict_sha256:$verdict_sha}'
}

review_copy_artifacts(){
  local node=$1 candidate=$2 checks=$3 verdict=$4 review_json=$5 basename candidate_diff logrels logrel index=0
  basename=$node
  local candidate_artifact="$EV/$basename.candidate.json" diff_artifact="$EV/$basename.diff" checks_artifact="$EV/$basename.checks.json" verdict_artifact="$EV/$basename.verdict.json"
  [[ ! -e $candidate_artifact && ! -e $diff_artifact && ! -e $checks_artifact && ! -e $verdict_artifact ]] || fail LIFECYCLE 'review artifacts already exist for this node'
  while IFS= read -r -d '' logrel; do
    [[ ! -e "$EV/$basename.check.$index.log" ]] || fail LIFECYCLE 'review check log artifact already exists for this node'
    index=$((index+1))
  done < <(jq -rj '.checks[] | .log_path,"\u0000"' "$checks")
  index=0
  cp -- "$candidate" "$candidate_artifact" || { review_cleanup_artifacts "$node"; fail EVIDENCE 'cannot copy candidate manifest'; }
  cp -- "$(jq -r .diff_path "$candidate")" "$diff_artifact" || { review_cleanup_artifacts "$node"; fail EVIDENCE 'cannot copy candidate diff'; }
  cp -- "$checks" "$checks_artifact" || { review_cleanup_artifacts "$node"; fail EVIDENCE 'cannot copy check evidence'; }
  cp -- "$verdict" "$verdict_artifact" || { review_cleanup_artifacts "$node"; fail EVIDENCE 'cannot copy review verdict'; }
  local copied_logs='[]' root; root=$(jq -r .root "$candidate")
  while IFS= read -r -d '' logrel; do
    local dest="$EV/$basename.check.$index.log"; cp -- "$root/$logrel" "$dest" || { review_cleanup_artifacts "$node"; fail EVIDENCE 'cannot copy review check log'; }
    copied_logs=$(jq -cn --argjson prior "$copied_logs" --arg file "${dest##*/}" --arg sha "$(review_hash "$dest")" '$prior+[{file:$file,sha256:$sha}]')
    index=$((index+1))
  done < <(jq -rj '.checks[] | .log_path,"\u0000"' "$checks")
  jq -cn --argjson review "$review_json" --arg candidate "${candidate_artifact##*/}" \
    --arg candidate_sha "$(review_hash "$candidate_artifact")" --arg diff "${diff_artifact##*/}" \
    --arg diff_sha "$(review_hash "$diff_artifact")" --arg checks "${checks_artifact##*/}" \
    --arg checks_sha "$(review_hash "$checks_artifact")" --arg verdict "${verdict_artifact##*/}" \
    --arg verdict_sha "$(review_hash "$verdict_artifact")" --argjson logs "$copied_logs" \
    '$review + {artifacts:{candidate:{file:$candidate,sha256:$candidate_sha},diff:{file:$diff,sha256:$diff_sha},
      checks:{file:$checks,sha256:$checks_sha},verdict:{file:$verdict,sha256:$verdict_sha},logs:$logs}}'
}

review_cleanup_artifacts(){
  local node=$1 path
  rm -f -- "$EV/$node.candidate.json" "$EV/$node.diff" "$EV/$node.checks.json" "$EV/$node.verdict.json"
  for path in "$EV/$node".check.*.log; do [[ ! -f $path ]] || rm -f -- "$path"; done
}

review_verify_copied_artifacts(){
  local review_json=$1 artifact sha candidate_artifact diff_artifact checks_artifact verdict_artifact check_logs copied_logs
  while IFS=$'\t' read -r artifact sha; do
    [[ -n $artifact && $artifact != */* && -f "$EV/$artifact" && $(review_hash "$EV/$artifact") == "$sha" ]] || fail INTEGRITY 'copied review artifact changed before command execution'
  done < <(jq -r '.artifacts|[.candidate,.diff,.checks,.verdict]|.[]|[.file,.sha256]|@tsv' <<<"$review_json")
  while IFS=$'\t' read -r artifact sha; do
    [[ -n $artifact && $artifact != */* && -f "$EV/$artifact" && $(review_hash "$EV/$artifact") == "$sha" ]] || fail INTEGRITY 'copied review log changed before command execution'
  done < <(jq -r '.artifacts.logs[]|[.file,.sha256]|@tsv' <<<"$review_json")
  jq -ne --arg identity "$(jq -r .candidate_identity <<<"$review_json")" \
    --arg candidate_sha "$(jq -r .candidate_manifest_sha256 <<<"$review_json")" \
    --arg diff_sha "$(jq -r .evidence_sha256 <<<"$review_json")" \
    --arg checks_sha "$(jq -r .checks_sha256 <<<"$review_json")" \
  --arg verdict_sha "$(jq -r .verdict_sha256 <<<"$review_json")" \
    --slurpfile manifest "$EV/$(jq -r '.artifacts.candidate.file' <<<"$review_json")" \
    --slurpfile checks "$EV/$(jq -r '.artifacts.checks.file' <<<"$review_json")" \
    --slurpfile verdict "$EV/$(jq -r '.artifacts.verdict.file' <<<"$review_json")" '
      $manifest[0].identity_sha256==$identity and
      $manifest[0].diff_sha256==$diff_sha and
      $checks[0].candidate_identity==$identity and $checks[0].candidate_manifest_sha256==$candidate_sha and
      $verdict[0].candidate_identity==$identity and $verdict[0].candidate_manifest_sha256==$candidate_sha and
      $verdict[0].evidence_sha256==$diff_sha and $verdict[0].checks_sha256==$checks_sha' >/dev/null || fail INTEGRITY 'copied review artifacts do not match approved evidence'
  candidate_artifact=$(jq -r '.artifacts.candidate.file' <<<"$review_json")
  diff_artifact=$(jq -r '.artifacts.diff.file' <<<"$review_json")
  checks_artifact=$(jq -r '.artifacts.checks.file' <<<"$review_json")
  verdict_artifact=$(jq -r '.artifacts.verdict.file' <<<"$review_json")
  [[ $(review_hash "$EV/$candidate_artifact") == "$(jq -r .candidate_manifest_sha256 <<<"$review_json")" &&
     $(review_hash "$EV/$diff_artifact") == "$(jq -r .evidence_sha256 <<<"$review_json")" &&
     $(review_hash "$EV/$checks_artifact") == "$(jq -r .checks_sha256 <<<"$review_json")" &&
     $(review_hash "$EV/$verdict_artifact") == "$(jq -r .verdict_sha256 <<<"$review_json")" ]] || fail INTEGRITY 'copied review artifact bytes differ from the approved source digests'
  check_logs=$(jq -c '[.checks[].log_sha256]' "$EV/$checks_artifact")
  copied_logs=$(jq -c '[.artifacts.logs[].sha256]' <<<"$review_json")
  [[ $check_logs == "$copied_logs" ]] || fail INTEGRITY 'copied review log set differs from the approved checks'
}

review_verify_receipt(){
  local receipt=$1 node=${2:-}
  jq -e '.candidate_review.verdict=="accept" and (.candidate_review.write_node|type=="string") and
    (.candidate_review.reviewer_owner|type=="string") and (.candidate_review.candidate_identity|test("^[a-f0-9]{64}$"))' "$receipt" >/dev/null || fail REVIEW 'accepted candidate review is missing from receipt'
  local f sha
  while IFS=$'\t' read -r f sha; do
    [[ -n $f && $f != */* && -f "$EV/$f" && $(review_hash "$EV/$f") == "$sha" ]] || fail INTEGRITY 'candidate review artifact changed or is missing'
  done < <(jq -r '.candidate_review.artifacts|[.candidate,.diff,.checks,.verdict]|.[]|[.file,.sha256]|@tsv' "$receipt")
  while IFS=$'\t' read -r f sha; do
    [[ -n $f && $f != */* && -f "$EV/$f" && $(review_hash "$EV/$f") == "$sha" ]] || fail INTEGRITY 'candidate check log changed or is missing'
  done < <(jq -r '.candidate_review.artifacts.logs[]|[.file,.sha256]|@tsv' "$receipt")
  local artifact_dir="$EV" artifact_manifest artifact_checks artifact_verdict expected_owner writer_owner
  artifact_manifest=$(jq -r '.candidate_review.artifacts.candidate.file' "$receipt")
  artifact_checks=$(jq -r '.candidate_review.artifacts.checks.file' "$receipt")
  artifact_verdict=$(jq -r '.candidate_review.artifacts.verdict.file' "$receipt")
  expected_owner=$(jq -r --arg id "$node" '.planned_nodes[]|select(.id==$id)|.owner' "$GRAPH")
  writer_owner=$(jq -r --arg id "$(jq -r .candidate_review.write_node "$receipt")" '.planned_nodes[]|select(.id==$id)|.owner' "$GRAPH")
  [[ $expected_owner != "$writer_owner" ]] || fail REVIEW 'review receipt has no owner separation'
  jq -e --arg node "$node" --arg writer "$(jq -r .candidate_review.write_node "$receipt")" \
    '.planned_nodes[]|select(.id==$node)|.gate=="review" and .verifies==[$writer]' "$GRAPH" >/dev/null || fail REVIEW 'review receipt does not match its declared WRITE dependency'
  jq -ne --arg node "$node" --arg writer "$(jq -r .candidate_review.write_node "$receipt")" \
    --arg owner "$expected_owner" --arg identity "$(jq -r .candidate_review.candidate_identity "$receipt")" \
    --arg candidate_sha "$(jq -r .candidate_review.candidate_manifest_sha256 "$receipt")" \
    --arg diff_sha "$(jq -r .candidate_review.evidence_sha256 "$receipt")" \
    --arg checks_sha "$(jq -r .candidate_review.checks_sha256 "$receipt")" \
    --arg verdict_sha "$(jq -r .candidate_review.verdict_sha256 "$receipt")" \
    --arg manifest_artifact_sha "$(jq -r .candidate_review.artifacts.candidate.sha256 "$receipt")" \
    --arg diff_artifact_sha "$(jq -r .candidate_review.artifacts.diff.sha256 "$receipt")" \
    --arg checks_artifact_sha "$(jq -r .candidate_review.artifacts.checks.sha256 "$receipt")" \
    --arg verdict_artifact_sha "$(jq -r .candidate_review.artifacts.verdict.sha256 "$receipt")" \
    --slurpfile manifest "$artifact_dir/$artifact_manifest" --slurpfile checks "$artifact_dir/$artifact_checks" \
    --slurpfile verdict "$artifact_dir/$artifact_verdict" --slurpfile receipt "$receipt" '
      ($manifest[0].identity_sha256==$identity and $manifest[0].write_node==$writer and
       $candidate_sha==$manifest_artifact_sha and $diff_sha==$manifest[0].diff_sha256 and $diff_sha==$diff_artifact_sha and
       $checks_sha==$checks_artifact_sha and $verdict_sha==$verdict_artifact_sha and
       $checks[0].candidate_identity==$identity and $checks[0].candidate_manifest_sha256==$candidate_sha and
       ([$checks[0].checks[].log_sha256]==[$receipt[0].candidate_review.artifacts.logs[].sha256]) and
       $verdict[0].schema_version==1 and $verdict[0].verdict=="accept" and $verdict[0].node_id==$node and
       $verdict[0].write_node==$writer and $verdict[0].reviewer_owner==$owner and
       $verdict[0].candidate_identity==$identity and $verdict[0].candidate_manifest_sha256==$candidate_sha and
       $verdict[0].evidence_sha256==$diff_sha and $verdict[0].checks_sha256==$checks_sha)'
    >/dev/null || fail INTEGRITY 'candidate review artifacts do not match accepted receipt'
}
