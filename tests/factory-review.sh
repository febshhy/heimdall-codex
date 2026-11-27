#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
FACTORY="$ROOT/scripts/factory"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/factory-review.XXXXXX")
trap 'rm -rf -- "$TMP"' EXIT

fail(){ printf 'FAIL: %s\n' "$1" >&2; exit 1; }
ok(){ printf 'ok: %s\n' "$1"; }
hash(){ sha256sum "$1" | cut -d' ' -f1; }
run(){ bash "$FACTORY" "$@"; }
fixture(){
  local dir=$1
  mkdir -p "$dir"
  git -C "$dir" init -q
  git -C "$dir" config user.name 'Review Fixture'
  git -C "$dir" config user.email 'review-fixture@example.invalid'
  printf '.work/\nsrc/forced-ignored-*\n' >"$dir/.gitignore"
  mkdir -p "$dir/src" "$dir/.work/graphs" "$dir/.work/review"
  printf 'remove me\n' >"$dir/src/delete.txt"
  printf 'plain\n' >"$dir/src/mode.sh"
  printf 'start\n' >"$dir/src/stage.txt"
  git -C "$dir" add .gitignore src
  git -C "$dir" commit -qm 'fixture base'
}
write_plan(){
  local dir=$1
  cat >"$dir/.work/plan.json" <<'JSON'
{
  "schema_version":3,
  "review_contract":"candidate-bound/v1",
  "planned_nodes":[
    {"id":"N1","domain":"factory_runtime","owner":"heimdall_routine","mode":"WRITE","task":"write scoped fixture changes","depends_on":[],"requires":[],"produces":["change_set"],"write_set":["src/"],"verifies":[],"gate":"none","delegation":{"A":{"nodes":[{"id":"write","domain":"factory_runtime","inputs":[],"outputs":["change_set"]}],"edges":[]},"E":[{"at":"write","kind":"wrong_context","mitigation":"Keep every candidate path inside src"}],"R":{"method":"repository-work and testing","verification":[["git","diff","--check"]],"why":"Provide a bounded change to verify","inputs":["approved fixture change"]}}},
    {"id":"N2","domain":"quality","owner":"heimdall_reviewer","mode":"RUN","task":"review exact candidate evidence","depends_on":["N1"],"requires":[{"from":"N1","output":"change_set"}],"produces":["review_result"],"write_set":[],"verifies":["N1"],"gate":"review","delegation":{"A":{"nodes":[{"id":"inspect","domain":"quality","inputs":["change_set"],"outputs":["review_result"]}],"edges":[]},"E":[{"at":"inspect","kind":"missing_input","mitigation":"Stop when candidate or checks are absent"}],"R":{"method":"independent read-only review and testing","verification":[["git","diff","--check"]],"why":"Accept only the reviewed candidate and exact check evidence","inputs":["N1.change_set"]}}},
    {"id":"N3","domain":"quality","owner":"heimdall_routine","mode":"RUN","task":"consume accepted review","depends_on":["N2"],"requires":[{"from":"N2","output":"review_result"}],"produces":["result"],"write_set":[],"verifies":[],"gate":"none","delegation":{"A":{"nodes":[{"id":"consume","domain":"quality","inputs":["review_result"],"outputs":["result"]}],"edges":[]},"E":[{"at":"consume","kind":"missing_input","mitigation":"Require the accepted review result"}],"R":{"method":"graph-protocol","verification":[["true"]],"why":"Demonstrate downstream consumption after accepted review","inputs":["N2.review_result"]}}}
  ]
}
JSON
}
make_return(){
  local plan=$1 id=$2 output=$3 file=$4
  jq -n --arg id "$id" --arg out "$output" --slurpfile p "$plan" \
    '($p[0].planned_nodes[]|select(.id==$id)) as $n | {node_id:$id,implemented:$n.delegation,outputs:{($n.produces[0]):$out},summary:"fixture return"}' >"$file"
}
negative(){
  local label=$1; shift
  if "$@" >"$TMP/negative.out" 2>&1; then fail "$label unexpectedly passed"; fi
  ok "$label rejected"
}
make_candidate_evidence(){
  local root=$1 candidate=$2 checks_out=$3 verdict_out=$4 log_rel=$5
  (cd "$root" && git diff --check) >"$root/$log_rel" 2>&1
  jq -n --arg id "$(jq -r .identity_sha256 "$candidate")" --arg manifest "$(hash "$candidate")" \
    --arg log "$log_rel" --arg sha "$(hash "$root/$log_rel")" \
    '{schema_version:1,candidate_identity:$id,candidate_manifest_sha256:$manifest,checks:[{argv:["git","diff","--check"],exit_code:0,log_path:$log,log_sha256:$sha}]}' >"$checks_out"
  jq -n --arg identity "$(jq -r .identity_sha256 "$candidate")" --arg manifest "$(hash "$candidate")" \
    --arg diff "$(jq -r .diff_sha256 "$candidate")" --arg checks "$(hash "$checks_out")" \
    '{schema_version:1,verdict:"accept",node_id:"N2",write_node:"N1",reviewer_owner:"heimdall_reviewer",candidate_identity:$identity,candidate_manifest_sha256:$manifest,evidence_sha256:$diff,checks_sha256:$checks,findings:[]}' >"$verdict_out"
}

# New bound plans must place all consumers behind review. Non-WRITE evidence
# preparation may be a transitive predecessor of the review gate.
order_fixture="$TMP/order"
fixture "$order_fixture"
write_plan "$order_fixture"
order_plan="$order_fixture/.work/plan.json"
jq '.planned_nodes += [{"id":"N4","domain":"quality","owner":"heimdall_routine","mode":"RUN","task":"consume WRITE output without review","depends_on":["N1"],"requires":[{"from":"N1","output":"change_set"}],"produces":["result"],"write_set":[],"verifies":[],"gate":"none","delegation":{"A":{"nodes":[{"id":"consume","domain":"quality","inputs":["change_set"],"outputs":["result"]}],"edges":[]},"E":[{"at":"consume","kind":"missing_input","mitigation":"Require the WRITE output"}],"R":{"method":"testing","verification":[["true"]],"why":"Consume the WRITE result","inputs":["N1.change_set"]}}}]' \
  "$order_plan" >"$order_fixture/.work/illegal-order.json"
negative 'consumer bypasses WRITE review gate at init' run init --root "$order_fixture" --plan "$order_fixture/.work/illegal-order.json" --graph "$order_fixture/.work/graphs/illegal.json"
jq '.planned_nodes += [{"id":"N4","domain":"quality","owner":"heimdall_routine","mode":"RUN","task":"prepare pre-review evidence","depends_on":["N1"],"requires":[{"from":"N1","output":"change_set"}],"produces":["pre_review_check"],"write_set":[],"verifies":[],"gate":"none","delegation":{"A":{"nodes":[{"id":"prepare","domain":"quality","inputs":["change_set"],"outputs":["pre_review_check"]}],"edges":[]},"E":[{"at":"prepare","kind":"missing_input","mitigation":"Stop if the WRITE output is absent"}],"R":{"method":"testing","verification":[["true"]],"why":"Prepare evidence before independent review","inputs":["N1.change_set"]}}}] | .planned_nodes[1].depends_on=["N1","N4"] | .planned_nodes[1].requires += [{"from":"N4","output":"pre_review_check"}] | .planned_nodes[1].delegation.R.inputs += ["N4.pre_review_check"]' \
  "$order_plan" >"$order_fixture/.work/precursor-plan.json"
run init --root "$order_fixture" --plan "$order_fixture/.work/precursor-plan.json" --graph "$order_fixture/.work/graphs/precursor.json" >/dev/null
ok 'non-WRITE evidence precursor remains valid before review'

# The accepted review RUN implementation supports one WRITE per gate. Bound
# plans reject a wider verifications set before a graph can be initialized.
jq '.planned_nodes += [{"id":"N4","domain":"factory_runtime","owner":"heimdall_routine","mode":"WRITE","task":"second scoped change","depends_on":[],"requires":[],"produces":["second_change"],"write_set":["src/second.txt"],"verifies":[],"gate":"none","delegation":{"A":{"nodes":[{"id":"write_second","domain":"factory_runtime","inputs":[],"outputs":["second_change"]}],"edges":[]},"E":[{"at":"write_second","kind":"wrong_context","mitigation":"Keep the second change in src"}],"R":{"method":"repository-work and testing","verification":[["git","diff","--check"]],"why":"Provide a second bounded change","inputs":["approved second change"]}}}] | .planned_nodes[1].depends_on += ["N4"] | .planned_nodes[1].requires += [{"from":"N4","output":"second_change"}] | .planned_nodes[1].verifies += ["N4"] | .planned_nodes[1].delegation.R.inputs += ["N4.second_change"]' \
  "$order_plan" >"$order_fixture/.work/multi-review-plan.json"
negative 'candidate-bound review gate cannot verify multiple WRITEs' run init --root "$order_fixture" --plan "$order_fixture/.work/multi-review-plan.json" --graph "$order_fixture/.work/graphs/multi-review.json"
multi_graph="$order_fixture/.work/graphs/multi-tampered.json"
multi_repo=$(git -C "$order_fixture" rev-parse --path-format=absolute --git-common-dir)
multi_sha=$(jq -cS --arg id "$multi_repo" --arg marker 'candidate-bound/v1' '{schema_version,planned_nodes,repository_id:$id,review_contract:$marker}' "$order_fixture/.work/multi-review-plan.json" | sha256sum | cut -d' ' -f1)
jq -cS --arg id "$multi_repo" --arg sha "$multi_sha" --arg marker 'candidate-bound/v1' '. + {repository_id:$id,review_contract:$marker,plan_sha256:$sha}' "$order_fixture/.work/multi-review-plan.json" >"$multi_graph"
mkdir -p "${multi_graph%.json}.evidence"
printf '0\n' >"${multi_graph%.json}.evidence/sequence"
negative 'checkgraph rejects self-consistent multi-WRITE review graph' run status --root "$order_fixture" --graph "$multi_graph"

fx="$TMP/review"
fixture "$fx"
write_plan "$fx"
graph="$fx/.work/graphs/review.json"
plan="$fx/.work/plan.json"
run init --root "$fx" --plan "$plan" --graph "$graph" >/dev/null
jq -e '.review_contract=="candidate-bound/v1"' "$graph" >/dev/null || fail 'init did not stamp review compatibility marker'
n1return="$fx/.work/N1.json"
make_return "$plan" N1 '$candidate' "$n1return"
run begin --root "$fx" --graph "$graph" --node N1 >/dev/null
printf 'staged\n' >"$fx/src/stage.txt"
git -C "$fx" add src/stage.txt
printf 'staged then unstaged\n' >"$fx/src/stage.txt"
printf 'untracked with spaces\n' >"$fx/src/untracked space.txt"
printf 'force-added ignored content\n' >"$fx/src/forced-ignored-file.txt"
git -C "$fx" add -f src/forced-ignored-file.txt
ln -s stage.txt "$fx/src/link"
chmod +x "$fx/src/mode.sh"
rm "$fx/src/delete.txt"
run end --root "$fx" --graph "$graph" --node N1 --return "$n1return" >/dev/null
jq -e '(.finish_tree.schema_version==1) and (.finish_tree.tree_sha|test("^[a-f0-9]{40,64}$")) and (.finish_tree.head_sha==.before.head)' "$fx/.work/graphs/review.evidence/N1.receipt.json" >/dev/null || fail 'WRITE receipt omitted or misbound its prospective finish tree'

base=$(git -C "$fx" rev-parse HEAD)
manifest="$fx/.work/review/candidate.json"
diff="$fx/.work/review/candidate.diff"
dirty_sub="$fx/.work/review/dirty-substitution.json"
printf 'post-WRITE dirty substitution\n' >"$fx/src/stage.txt"
run candidate-capture --root "$fx" --graph "$graph" --node N1 --base "$base" --manifest "$dirty_sub" --diff-out "$fx/.work/review/dirty-substitution.diff" >/dev/null
dirty_checks="$fx/.work/review/dirty-substitution-checks.json"
dirty_verdict="$fx/.work/review/dirty-substitution-verdict.json"
make_candidate_evidence "$fx" "$dirty_sub" "$dirty_checks" "$dirty_verdict" '.work/review/dirty-substitution.log'
negative 'fresh dirty same-path substitution rejected' run review-check --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$dirty_sub" --check-evidence "$dirty_checks" --review-verdict "$dirty_verdict"
printf 'staged then unstaged\n' >"$fx/src/stage.txt"
run candidate-capture --root "$fx" --graph "$graph" --node N1 --base "$base" --manifest "$manifest" --diff-out "$diff" >/dev/null
jq -e '.dirty==true and .base_sha=="'"$base"'" and (.changed_paths|index("src/untracked space.txt"))!=null and (.changed_paths|index("src/delete.txt"))!=null' "$manifest" >/dev/null || fail 'capture omitted worktree path state'
jq -e '.changed_paths|index("src/forced-ignored-file.txt")!=null' "$manifest" >/dev/null || fail 'capture omitted force-added ignored index path'
[[ $(git -C "$fx" show "$(jq -r .tree_sha "$manifest"):src/stage.txt") == 'staged then unstaged' ]] || fail 'prospective tree missed unstaged bytes'
[[ $(git -C "$fx" show "$(jq -r .tree_sha "$manifest"):src/forced-ignored-file.txt") == 'force-added ignored content' ]] || fail 'prospective tree missed force-added ignored bytes'
[[ $(git -C "$fx" ls-tree "$(jq -r .tree_sha "$manifest")" src/link) == *'120000'* ]] || fail 'prospective tree missed symlink mode'
[[ $(git -C "$fx" ls-tree "$(jq -r .tree_sha "$manifest")" src/mode.sh) == *'100755'* ]] || fail 'prospective tree missed executable mode'
[[ $(hash "$diff") == "$(jq -r .diff_sha256 "$manifest")" ]] || fail 'diff digest mismatch'
ok 'prospective tree captures staged and unstaged content, deletions, symlink and mode'

candidate_tree=$(jq -r .tree_sha "$manifest")
git -C "$fx" add -A
git -C "$fx" commit -qm 'fixture candidate'
candidate_commit=$(git -C "$fx" rev-parse HEAD)
bound="$fx/.work/review/bound.json"
run candidate-bind --manifest "$manifest" --commit "$candidate_commit" --output "$bound" >/dev/null
jq -e --arg commit "$candidate_commit" --arg parent "$base" --arg tree "$candidate_tree" '.dirty==false and .commit_sha==$commit and .commit_parent==$parent and .tree_sha==$tree' "$bound" >/dev/null || fail 'dirty capture did not bind exact commit parent and tree'
ok 'dirty capture binds exact later commit, parent, tree and base'
clean="$fx/.work/review/clean.json"
run candidate-capture --root "$fx" --graph "$graph" --node N1 --base "$base" --manifest "$clean" --diff-out "$fx/.work/review/clean.diff" >/dev/null
jq -e --arg commit "$candidate_commit" '.dirty==false and .commit_sha==$commit and .head_sha==$commit' "$clean" >/dev/null || fail 'clean committed candidate did not bind current HEAD'
ok 'clean committed candidate binds directly to HEAD'

log="$fx/.work/review/check.log"
(cd "$fx" && git diff --check) >"$log" 2>&1
checks="$fx/.work/review/checks.json"
jq -n --arg id "$(jq -r .identity_sha256 "$bound")" --arg manifest "$(hash "$bound")" \
  --arg log '.work/review/check.log' --arg sha "$(hash "$log")" \
  '{schema_version:1,candidate_identity:$id,candidate_manifest_sha256:$manifest,checks:[{argv:["git","diff","--check"],exit_code:0,log_path:$log,log_sha256:$sha}]}' >"$checks"
verdict="$fx/.work/review/verdict.json"
make_verdict(){
  local output=$1 decision=${2:-accept} owner=${3:-heimdall_reviewer}
  jq -n --arg decision "$decision" --arg owner "$owner" --arg identity "$(jq -r .identity_sha256 "$bound")" \
    --arg manifest "$(hash "$bound")" --arg diff "$(jq -r .diff_sha256 "$bound")" --arg checks "$(hash "$checks")" \
    '{schema_version:1,verdict:$decision,node_id:"N2",write_node:"N1",reviewer_owner:$owner,candidate_identity:$identity,candidate_manifest_sha256:$manifest,evidence_sha256:$diff,checks_sha256:$checks,findings:[]}' >"$output"
}
make_verdict "$verdict"

negative 'missing verdict preflight' run run --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --return "$fx/.work/N2.json" --review-note accepted -- git diff --check
[[ ! -e "$fx/.work/graphs/review.evidence/N2.state.json" ]] || fail 'missing review verdict acquired lease or node state'
ok 'missing review evidence fails before lease and command'

make_verdict "$verdict" reject
negative 'rejected verdict' run review-check --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict"
negative 'rejected verdict run preflight' run run --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict" --return "$fx/.work/N2.json" --review-note rejected -- git diff --check
make_verdict "$verdict" accept wrong-reviewer
negative 'wrong reviewer owner' run review-check --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict"
negative 'wrong reviewer run preflight' run run --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict" --return "$fx/.work/N2.json" --review-note rejected -- git diff --check
make_verdict "$verdict"
jq 'del(.checks_sha256)' "$verdict" >"$fx/.work/review/malformed-verdict.json"
negative 'malformed verdict preflight' run run --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$fx/.work/review/malformed-verdict.json" --return "$fx/.work/N2.json" --review-note rejected -- git diff --check
[[ ! -e "$fx/.work/graphs/review.evidence/N2.state.json" ]] || fail 'invalid verdict acquired lease or node state'
make_verdict "$verdict"

printf 'post-commit mutation\n' >>"$fx/src/stage.txt"
negative 'stale candidate preflight' run review-check --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict"
negative 'stale candidate run preflight' run run --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict" --return "$fx/.work/N2.json" --review-note stale -- git diff --check
git -C "$fx" checkout -- src/stage.txt
run review-check --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict" >/dev/null
ok 'stale candidate rejected and unchanged snapshot accepted'

# A candidate captured in one worktree cannot authorize execution from a linked
# worktree, even though both worktrees share repository identity.
linked="$TMP/linked-review-worktree"
git -C "$fx" worktree add --detach "$linked" "$candidate_commit" >/dev/null
guard_bin="$TMP/guard-bin"
mkdir -p "$guard_bin"
export RUN_SENTINEL="$TMP/review-command-started"
cat >"$guard_bin/timeout" <<'SH'
#!/usr/bin/env bash
: >"$RUN_SENTINEL"
exec /usr/bin/timeout "$@"
SH
chmod +x "$guard_bin/timeout"
negative 'linked worktree cannot run another root candidate' env PATH="$guard_bin:$PATH" bash "$FACTORY" run --root "$linked" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict" --return "$fx/.work/N2.json" --review-note linked -- git diff --check
[[ ! -e "$RUN_SENTINEL" && ! -e "$fx/.work/graphs/review.evidence/N2.state.json" ]] || fail 'linked-worktree mismatch started command or node state'
rm -f "$RUN_SENTINEL"
ok 'linked-worktree mismatch fails before command and lease'

negative 'dependent node before accepted review' run ready --root "$fx" --graph "$graph" --node N3
return2="$fx/.work/N2.json"
make_return "$plan" N2 '$reviewed' "$return2"
run run --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict" --return "$return2" --review-note accepted -- git diff --check >/dev/null
run ready --root "$fx" --graph "$graph" --node N3 >/dev/null
return3="$fx/.work/N3.json"
make_return "$plan" N3 '$consumed' "$return3"
run run --root "$fx" --graph "$graph" --node N3 --return "$return3" -- true >/dev/null
run validate --root "$fx" --graph "$graph" >/dev/null
jq -e '.candidate_review.verdict=="accept" and .check.argv==["git","diff","--check"]' "$fx/.work/graphs/review.evidence/N2.receipt.json" >/dev/null || fail 'receipt lacks accepted evidence or exact argv'
ok 'review run records exact argv, accepted evidence, and opens downstream dependency'

# Once a review node is done, a rejected rerun must not replace its archived
# review artifacts before the lifecycle guard notices the completed state.
saved_artifacts=$(sha256sum "$fx/.work/graphs/review.evidence/N2.candidate.json" "$fx/.work/graphs/review.evidence/N2.diff" "$fx/.work/graphs/review.evidence/N2.checks.json" "$fx/.work/graphs/review.evidence/N2.verdict.json" "$fx/.work/graphs/review.evidence/N2.check.0.log")
negative 'completed review node cannot rerun' run run --root "$fx" --graph "$graph" --node N2 --candidate-manifest "$bound" --check-evidence "$checks" --review-verdict "$verdict" --return "$return2" --review-note repeated -- git diff --check
[[ "$saved_artifacts" == "$(sha256sum "$fx/.work/graphs/review.evidence/N2.candidate.json" "$fx/.work/graphs/review.evidence/N2.diff" "$fx/.work/graphs/review.evidence/N2.checks.json" "$fx/.work/graphs/review.evidence/N2.verdict.json" "$fx/.work/graphs/review.evidence/N2.check.0.log")" ]] || fail 'rerun corrupted completed review artifacts'
ok 'completed review artifacts remain unchanged after rejected rerun'

# Corrupt a copied review manifest after cp returns; the final pre-execution
# copy validation must fail while retaining failed state and releasing the lease.
copy_graph="$fx/.work/graphs/copy.json"
copy_plan="$plan"
copy_return="$fx/.work/copy-N1.json"
run init --root "$fx" --plan "$copy_plan" --graph "$copy_graph" >/dev/null
make_return "$copy_plan" N1 '$candidate' "$copy_return"
run begin --root "$fx" --graph "$copy_graph" --node N1 >/dev/null
printf 'second graph candidate\n' >"$fx/src/stage.txt"
run end --root "$fx" --graph "$copy_graph" --node N1 --return "$copy_return" >/dev/null
copy_base=$(git -C "$fx" rev-parse HEAD)
copy_candidate="$fx/.work/review/copy-candidate.json"
copy_diff="$fx/.work/review/copy-candidate.diff"
run candidate-capture --root "$fx" --graph "$copy_graph" --node N1 --base "$copy_base" --manifest "$copy_candidate" --diff-out "$copy_diff" >/dev/null
copy_checks="$fx/.work/review/copy-checks.json"
copy_verdict="$fx/.work/review/copy-verdict.json"
make_candidate_evidence "$fx" "$copy_candidate" "$copy_checks" "$copy_verdict" '.work/review/copy-check.log'
corrupt_bin="$TMP/corrupt-bin"
mkdir -p "$corrupt_bin"
cat >"$corrupt_bin/cp" <<'SH'
#!/usr/bin/env bash
/bin/cp "$@"
dest=${!#}
case "$dest" in *.candidate.json) printf '\ncopy tampered\n' >>"$dest";; esac
SH
chmod +x "$corrupt_bin/cp"
rm -f "$RUN_SENTINEL"
negative 'tampered copied evidence fails under the RUN lease' env PATH="$corrupt_bin:$guard_bin:$PATH" bash "$FACTORY" run --root "$fx" --graph "$copy_graph" --node N2 --candidate-manifest "$copy_candidate" --check-evidence "$copy_checks" --review-verdict "$copy_verdict" --return "$fx/.work/copy-N2.json" --review-note copied -- git diff --check
[[ ! -e "$RUN_SENTINEL" ]] || fail 'command ran with tampered copied evidence'
[[ $(jq -r .status "$fx/.work/graphs/copy.evidence/N2.state.json") == failed ]] || fail 'pre-execution evidence failure was not retained as failed state'
[[ ! -e "$fx/.work/graphs/copy.evidence/N2.candidate.json" && ! -e "$fx/.work/graphs/copy.evidence/N2.diff" && ! -e "$fx/.work/graphs/copy.evidence/N2.checks.json" && ! -e "$fx/.work/graphs/copy.evidence/N2.verdict.json" ]] || fail 'failed pre-execution validation retained copied review artifacts'
copy_gitdir=$(git -C "$fx" rev-parse --path-format=absolute --git-dir)
[[ ! -e "$copy_gitdir/heimdall-factory/active" ]] || fail 'pre-execution evidence failure retained the RUN lease'
ok 'tampered copied evidence fails without command and releases RUN lease'

# Mutating the source candidate after copy but before execution is caught by
# the post-copy candidate revalidation under the same lease.
candidate_graph="$fx/.work/graphs/candidate-move.json"
candidate_return="$fx/.work/candidate-move-N1.json"
run init --root "$fx" --plan "$plan" --graph "$candidate_graph" >/dev/null
make_return "$plan" N1 '$candidate' "$candidate_return"
run begin --root "$fx" --graph "$candidate_graph" --node N1 >/dev/null
printf 'third graph candidate\n' >"$fx/src/stage.txt"
run end --root "$fx" --graph "$candidate_graph" --node N1 --return "$candidate_return" >/dev/null
candidate_base=$(git -C "$fx" rev-parse HEAD)
moving_candidate="$fx/.work/review/moving-candidate.json"
moving_diff="$fx/.work/review/moving-candidate.diff"
run candidate-capture --root "$fx" --graph "$candidate_graph" --node N1 --base "$candidate_base" --manifest "$moving_candidate" --diff-out "$moving_diff" >/dev/null
moving_checks="$fx/.work/review/moving-checks.json"
moving_verdict="$fx/.work/review/moving-verdict.json"
make_candidate_evidence "$fx" "$moving_candidate" "$moving_checks" "$moving_verdict" '.work/review/moving-check.log'
cat >"$corrupt_bin/cp" <<'SH'
#!/usr/bin/env bash
/bin/cp "$@"
dest=${!#}
case "$dest" in *.candidate.json) printf '\nsource candidate moved\n' >>"$MUTATE_CANDIDATE";; esac
SH
chmod +x "$corrupt_bin/cp"
export MUTATE_CANDIDATE="$moving_candidate"
rm -f "$RUN_SENTINEL"
negative 'candidate moved after copy fails under the RUN lease' env PATH="$corrupt_bin:$guard_bin:$PATH" bash "$FACTORY" run --root "$fx" --graph "$candidate_graph" --node N2 --candidate-manifest "$moving_candidate" --check-evidence "$moving_checks" --review-verdict "$moving_verdict" --return "$fx/.work/moving-N2.json" --review-note moved -- git diff --check
[[ ! -e "$RUN_SENTINEL" && $(jq -r .status "$fx/.work/graphs/candidate-move.evidence/N2.state.json") == failed ]] || fail 'moved candidate ran or failed state was not retained'
[[ ! -e "$fx/.work/graphs/candidate-move.evidence/N2.candidate.json" && ! -e "$fx/.work/graphs/candidate-move.evidence/N2.diff" && ! -e "$fx/.work/graphs/candidate-move.evidence/N2.checks.json" && ! -e "$fx/.work/graphs/candidate-move.evidence/N2.verdict.json" ]] || fail 'candidate movement failure retained copied review artifacts'
[[ ! -e "$copy_gitdir/heimdall-factory/active" ]] || fail 'candidate movement failure retained the RUN lease'
ok 'moved candidate fails before command and releases RUN lease'

committed_sub_fx="$TMP/committed-substitution"
fixture "$committed_sub_fx"
write_plan "$committed_sub_fx"
committed_sub_graph="$committed_sub_fx/.work/graphs/review.json"
committed_sub_plan="$committed_sub_fx/.work/plan.json"
run init --root "$committed_sub_fx" --plan "$committed_sub_plan" --graph "$committed_sub_graph" >/dev/null
committed_sub_return="$committed_sub_fx/.work/N1.json"
make_return "$committed_sub_plan" N1 '$candidate' "$committed_sub_return"
run begin --root "$committed_sub_fx" --graph "$committed_sub_graph" --node N1 >/dev/null
printf 'approved at WRITE finish\n' >"$committed_sub_fx/src/stage.txt"
run end --root "$committed_sub_fx" --graph "$committed_sub_graph" --node N1 --return "$committed_sub_return" >/dev/null
committed_sub_base=$(git -C "$committed_sub_fx" rev-parse HEAD)
printf 'post-WRITE committed substitution\n' >"$committed_sub_fx/src/stage.txt"
committed_dirty="$committed_sub_fx/.work/review/substituted-dirty.json"
run candidate-capture --root "$committed_sub_fx" --graph "$committed_sub_graph" --node N1 --base "$committed_sub_base" --manifest "$committed_dirty" --diff-out "$committed_sub_fx/.work/review/substituted-dirty.diff" >/dev/null
git -C "$committed_sub_fx" add src/stage.txt
git -C "$committed_sub_fx" commit -qm 'post-WRITE substituted candidate'
substituted_commit=$(git -C "$committed_sub_fx" rev-parse HEAD)
committed_bound="$committed_sub_fx/.work/review/substituted-bound.json"
run candidate-bind --manifest "$committed_dirty" --commit "$substituted_commit" --output "$committed_bound" >/dev/null
bound_checks="$committed_sub_fx/.work/review/substituted-bound-checks.json"
bound_verdict="$committed_sub_fx/.work/review/substituted-bound-verdict.json"
make_candidate_evidence "$committed_sub_fx" "$committed_bound" "$bound_checks" "$bound_verdict" '.work/review/substituted-bound.log'
negative 'bound committed same-path substitution rejected' run review-check --root "$committed_sub_fx" --graph "$committed_sub_graph" --node N2 --candidate-manifest "$committed_bound" --check-evidence "$bound_checks" --review-verdict "$bound_verdict"
committed_direct="$committed_sub_fx/.work/review/substituted-direct.json"
run candidate-capture --root "$committed_sub_fx" --graph "$committed_sub_graph" --node N1 --base "$committed_sub_base" --manifest "$committed_direct" --diff-out "$committed_sub_fx/.work/review/substituted-direct.diff" >/dev/null
direct_checks="$committed_sub_fx/.work/review/substituted-direct-checks.json"
direct_verdict="$committed_sub_fx/.work/review/substituted-direct-verdict.json"
make_candidate_evidence "$committed_sub_fx" "$committed_direct" "$direct_checks" "$direct_verdict" '.work/review/substituted-direct.log'
negative 'direct committed same-path substitution rejected' run review-check --root "$committed_sub_fx" --graph "$committed_sub_graph" --node N2 --candidate-manifest "$committed_direct" --check-evidence "$direct_checks" --review-verdict "$direct_verdict"
ok 'bound and direct commits cannot replace the WRITE finish tree'

legacy="$TMP/legacy"
fixture "$legacy"
write_plan "$legacy"
jq 'del(.review_contract)' "$legacy/.work/plan.json" >"$legacy/.work/legacy-plan.json"
legacy_graph="$legacy/.work/graphs/old.json"
legacy_repo=$(git -C "$legacy" rev-parse --path-format=absolute --git-common-dir)
legacy_sha=$(jq -cS --arg id "$legacy_repo" '{schema_version,planned_nodes,repository_id:$id}' "$legacy/.work/legacy-plan.json" | sha256sum | cut -d' ' -f1)
jq -cS --arg id "$legacy_repo" --arg sha "$legacy_sha" '. + {repository_id:$id,plan_sha256:$sha}' "$legacy/.work/legacy-plan.json" >"$legacy_graph"
mkdir -p "$legacy/.work/graphs/old.evidence"
printf '0\n' >"$legacy/.work/graphs/old.evidence/sequence"
run status --root "$legacy" --graph "$legacy_graph" >/dev/null
negative 'legacy graph cannot capture new review' run candidate-capture --root "$legacy" --graph "$legacy_graph" --node N1 --base "$(git -C "$legacy" rev-parse HEAD)" --manifest "$legacy/.work/old-candidate.json" --diff-out "$legacy/.work/old.diff"
ok 'historical markerless schema-3 graph remains inspectable without review fallback'

printf 'PASS: candidate-bound review regression suite\n'
