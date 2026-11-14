#!/usr/bin/env bash
# Heimdall user-scoped installation for Codex on Linux.
# No sudo, network access, or changes to arbitrary Git repositories.
set -euo pipefail
umask 077

SOURCE=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
ACTION=install
DRY=0
INTEGRATE=0
START='<!-- Heimdall global: begin -->'
END='<!-- Heimdall global: end -->'
BLOCK=$(cat <<'MARK'
<!-- Heimdall global: begin -->
## Heimdall (user-level)
For software work, use the relevant Heimdall skills installed in `~/.agents/skills/`.
Respect repository instructions, current code, approved requirements, and actual test results.
Do not treat guidance as evidence that any test or deployment passed.
Shared Heimdall release: `~/.local/share/heimdall/release/`.
For skill references to `.agents/skills/`, `scripts/`, or `docs/design/`, use
project-local files when present; otherwise read the matching paths in that release.
Keep generated project work in the project, not in the shared release.
For delegated-work evidence, use `~/.local/share/heimdall/release/scripts/factory`
from the Git repository root, and ignore `.work/` in that repository.
For team-shared, repository-local guidance, install the release into the project separately.
<!-- Heimdall global: end -->
MARK
)
usage(){ cat <<'HELP'
Usage: bash install-global.sh [--dry-run] [--integrate-agents]
       bash install-global.sh --verify
       bash install-global.sh --remove

Install Heimdall for the current Linux user, across Codex projects:
  ~/.agents/skills/                      Shared reusable skills
  ~/.codex/AGENTS.md (or active override) Short instruction reference
  ~/.local/share/heimdall/release/       Complete release, including project installer

  --dry-run           Check conflicts without modifying install locations
  --integrate-agents  Approve appending to an existing active global AGENTS file
  --verify            Verify installed hashes and Codex instruction reference
  --remove            Remove unchanged managed files and the reference
  --help              Show this help

Global installation does not modify any existing project. Run the project
installer separately when you want repo-tracked policy, templates, or scripts.
HELP
}
fail(){ printf 'Heimdall global: %s\n' "$*" >&2; exit 1; }
note(){ printf 'Heimdall global: %s\n' "$*"; }
while (($#)); do
  case "$1" in
    --dry-run) DRY=1; shift;;
    --integrate-agents) INTEGRATE=1; shift;;
    --verify) ACTION=verify; shift;;
    --remove) ACTION=remove; shift;;
    --help|-h) usage; exit 0;;
    *) fail "Unknown option: $1";;
  esac
done
if [[ $ACTION != install && ( $INTEGRATE -eq 1 || $DRY -eq 1 ) ]]; then
  fail "--dry-run and --integrate-agents apply to installation only."
fi
[[ $EUID -ne 0 ]] || fail 'Run as your normal user, without sudo.'
((BASH_VERSINFO[0]>4 || (BASH_VERSINFO[0]==4 && BASH_VERSINFO[1]>=4))) || fail 'Bash 4.4+ required.'
for exe in git jq sha256sum flock mktemp find sort cp mv cmp grep sed rm awk chmod timeout; do
  command -v "$exe" >/dev/null || fail "Missing required command: $exe"
done
[[ -n ${HOME:-} && -d $HOME ]] || fail 'HOME must be a user directory.'
HOME=$(cd -- "$HOME" && pwd -P)
DATA="$HOME/.local/share/heimdall"
SKILLS="$HOME/.agents/skills"
CODEX="$HOME/.codex"
CACHE="$HOME/.cache/heimdall"
MANIFEST="$DATA/manifest.json"
AGENTS=AGENTS.md
if [[ -e "$CODEX/AGENTS.override.md" || -L "$CODEX/AGENTS.override.md" ]]; then
  [[ -f "$CODEX/AGENTS.override.md" && ! -L "$CODEX/AGENTS.override.md" ]] || fail 'Global AGENTS.override.md must be a regular file.'
  [[ -s "$CODEX/AGENTS.override.md" ]] && AGENTS=AGENTS.override.md
fi
# Refuse symlinks in destinations; do not follow them while installing or deleting.
safe_dest(){
  local path=$1 part accum=''
  [[ $path == "$HOME"/* ]] || fail "Destination outside HOME: $path"
  path=${path#"$HOME"/}
  IFS='/' read -ra parts <<<"$path"
  for part in "${parts[@]}"; do
    [[ -n $part && $part != '.' && $part != '..' ]] || fail "Unsafe destination: $path"
    accum+=/$part
    [[ ! -L "$HOME$accum" ]] || fail "Symlink in destination: $path"
  done
}
resolve(){
  case "$1" in
    release/*) printf '%s/release/%s' "$DATA" "${1#release/}";;
    skills/*) printf '%s/%s' "$SKILLS" "${1#skills/}";;
    *) fail "Unsafe manifest path: $1";;
  esac
}
check_rel(){
  [[ -n $1 && $1 != *$'\n'* && $1 != *$'\t'* && $1 != *'..'* && $1 != *'\\'* && $1 != /* ]] || fail "Unsafe source path: $1"
}
block_suffix(){
  [[ -f $1 && ! -L $1 ]] || return 1
  local content expected=${2:-$BLOCK}
  content=$(cat -- "$1")
  [[ $content == *"$expected" ]]
}
check_manifest(){
  [[ -f $MANIFEST && ! -L $MANIFEST ]] || fail 'No global installation manifest found.'
  jq -e '(.schema==1) and (.agents_file=="AGENTS.md" or .agents_file=="AGENTS.override.md") and
    (.agents_mode=="created" or .agents_mode=="appended") and
    (.agents_block|type=="string") and (.agents_block|contains("<!-- Heimdall global: begin -->")) and
    (.agents_block|contains("<!-- Heimdall global: end -->")) and (.managed|type=="array") and
    all(.managed[]; (.path|type=="string") and (.path|test("^(release|skills)/[^\\n\\t]+$")) and
      (.sha256|type=="string") and (.sha256|test("^[0-9a-f]{64}$")))' "$MANIFEST" >/dev/null || fail 'Invalid global manifest.'
}
verify_install(){
  check_manifest
  local rel sha path found expected previous_block
  while IFS=$'\t' read -r rel sha; do
    [[ -n $rel ]] || continue
    check_rel "$rel"
    path=$(resolve "$rel")
    safe_dest "$path"
    [[ -f $path && ! -L $path ]] || fail "Missing managed file: $path"
    found=$(sha256sum -- "$path"); found=${found:0:64}
    [[ $found == "$sha" ]] || fail "Managed file changed: $path"
  done < <(jq -r '.managed[]|[.path,.sha256]|@tsv' "$MANIFEST")
  expected=$(jq -r .agents_file "$MANIFEST")
  [[ $AGENTS == "$expected" ]] || fail "Active Codex instructions changed: expected $expected, now $AGENTS"
  safe_dest "$CODEX/$AGENTS"
  previous_block=$(jq -r .agents_block "$MANIFEST")
  block_suffix "$CODEX/$AGENTS" "$previous_block" || fail "Global Heimdall instruction block is missing or modified: $CODEX/$AGENTS"
  [[ $(grep -Fc "$START" "$CODEX/$AGENTS") == 1 && $(grep -Fc "$END" "$CODEX/$AGENTS") == 1 ]] || fail 'Duplicate instruction markers.'
}
safe_dest "$MANIFEST"
safe_dest "$CODEX/$AGENTS"
# The lock is outside the installation. Serialization also covers --verify/--remove.
safe_dest "$CACHE/install.lock"
mkdir -p -- "$CACHE"
exec 9>"$CACHE/install.lock"
flock -x 9 || fail 'Could not lock global installation.'
if [[ $ACTION == verify ]]; then
  verify_install
  for entry in scripts/factory scripts/heimdall scripts/heimdall-secrets scripts/heimdall-bootstrap; do
    [[ -x "$DATA/release/$entry" ]] || fail "Shared tool is not executable: $entry"
  done
  "$DATA/release/scripts/factory" tools >/dev/null || fail 'Shared factory dependency check failed'
  note "Verified shared skills, release, and $CODEX/$AGENTS"
  exit 0
fi
# Set up rollback before any managed locations change.
STAGE=$(mktemp -d "$CACHE/stage.XXXXXXXX")
declare -a WRITTEN=()
restore(){
  local path backup
  for path in "${WRITTEN[@]}"; do
    backup="$STAGE/backup/${path#"$HOME"/}"
    if [[ -f $backup ]]; then
      mkdir -p -- "$(dirname -- "$path")"
      cp -p -- "$backup" "$path" || note "RECOVERY NEEDED: $path"
    else
      rm -f -- "$path"
    fi
  done
}
committed=0
cleanup(){
  if ((committed==0)); then restore; fi
  rm -rf -- "$STAGE"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
backup_then_write(){
  local path=$1 src=$2 backup="$STAGE/backup/${1#"$HOME"/}" temp
  safe_dest "$path"
  if [[ -e $path ]]; then
    [[ -f $path && ! -L $path ]] || fail "Not a regular file: $path"
    mkdir -p -- "$(dirname -- "$backup")"
    cp -p -- "$path" "$backup"
  fi
  WRITTEN+=("$path")
  mkdir -p -- "$(dirname -- "$path")"
  temp=$(mktemp "$(dirname -- "$path")/.heimdall-new.XXXXXXXX")
  cp -p -- "$src" "$temp"
  # Correct the mode even when the source archive stripped POSIX mode metadata.
  case "$path" in "$DATA/release/scripts/factory"|"$DATA/release/scripts/heimdall"|"$DATA/release/scripts/heimdall-secrets"|"$DATA/release/scripts/heimdall-bootstrap") chmod 0755 "$temp";; esac
  mv -f -- "$temp" "$path"
}
if [[ $ACTION == remove ]]; then
  verify_install
  local_mode=$(jq -r .agents_mode "$MANIFEST")
  agentfile="$CODEX/$AGENTS"
  # Copy every file that removal may touch before deleting anything.
  while IFS=$'\t' read -r rel sha; do
    [[ -n $rel ]] || continue
    path=$(resolve "$rel")
    safe_dest "$path"
    backup="$STAGE/backup/${path#"$HOME"/}"
    mkdir -p -- "$(dirname -- "$backup")"
    cp -p -- "$path" "$backup"
    WRITTEN+=("$path")
  done < <(jq -r '.managed[]|[.path,.sha256]|@tsv' "$MANIFEST")
  for path in "$MANIFEST" "$agentfile"; do
    backup="$STAGE/backup/${path#"$HOME"/}"
    mkdir -p -- "$(dirname -- "$backup")"
    cp -p -- "$path" "$backup"
    WRITTEN+=("$path")
  done
  while IFS=$'\t' read -r rel sha; do
    [[ -n $rel ]] || continue
    path=$(resolve "$rel")
    rm -- "$path"
  done < <(jq -r '.managed[]|[.path,.sha256]|@tsv' "$MANIFEST")
  sed -i '/^<!-- Heimdall global: begin -->$/,/^<!-- Heimdall global: end -->$/d' "$agentfile"
  if [[ $local_mode == created && -z $(tr -d '[:space:]' < "$agentfile") ]]; then rm -- "$agentfile"; fi
  rm -- "$MANIFEST"
  committed=1
  # Remove empty, now-unneeded directories without touching user content.
  # Only remove directories belonging to managed files; leave unrelated user directories.
  while IFS=$'\t' read -r rel sha; do
    [[ -n $rel ]] || continue
    path=$(resolve "$rel")
    dir=${path%/*}
    while [[ $dir == "$DATA/release"/* || $dir == "$SKILLS"/* ]]; do
      rmdir -- "$dir" 2>/dev/null || break
      dir=${dir%/*}
    done
  done < <(jq -r '.managed[]|[.path,.sha256]|@tsv' "$STAGE/backup/${MANIFEST#"$HOME"/}")
  rmdir -- "$DATA/release" "$DATA" 2>/dev/null || true
  note 'Removed unchanged user-scoped Heimdall files.'
  exit 0
fi

[[ $ACTION == install ]] || fail "Unknown action: $ACTION"
[[ "$SOURCE" != "$DATA" && "$SOURCE" != "$DATA"/* && "$DATA" != "$SOURCE"/* ]] || fail 'Extract release outside the global installation directory.'
[[ -d "$SOURCE/.agents/skills" && -f "$SOURCE/install.sh" && -f "$SOURCE/AGENTS.md" ]] || fail 'Incomplete Heimdall release.'
declare -a RELS=()
declare -A OLD=()
if [[ -e $MANIFEST ]]; then
  verify_install
  while IFS=$'\t' read -r rel sha; do OLD["$rel"]=$sha; done < <(jq -r '.managed[]|[.path,.sha256]|@tsv' "$MANIFEST")
  agents_mode=$(jq -r .agents_mode "$MANIFEST")
else
  if [[ -e "$CODEX/$AGENTS" ]]; then
    [[ -f "$CODEX/$AGENTS" && ! -L "$CODEX/$AGENTS" ]] || fail 'Active global AGENTS file is not a regular file.'
    if grep -Fq "$START" "$CODEX/$AGENTS" || grep -Fq "$END" "$CODEX/$AGENTS"; then
      fail 'Existing Heimdall global markers have no manifest; review the file.'
    fi
    ((INTEGRATE)) || fail "Existing $CODEX/$AGENTS: preview --dry-run --integrate-agents, then approve --integrate-agents."
    agents_mode=appended
  else
    agents_mode=created
  fi
fi
while IFS= read -r -d '' item; do
  rel=${item#"$SOURCE"/}
  check_rel "$rel"
  [[ $rel != .git/* ]] || continue
  [[ $rel == */__pycache__/* || $rel == *.pyc ]] && continue
  [[ -f $item && ! -L $item ]] || fail "Unsupported release entry: $rel"
  RELS+=("release/$rel")
  if [[ $rel == .agents/skills/* && $rel != .agents/skills/bend-proof/* ]]; then
    RELS+=("skills/${rel#.agents/skills/}")
  fi
done < <(find "$SOURCE" \( -type f -o -type l \) -print0 | sort -z)
((${#RELS[@]}>10)) || fail 'Release contains no skills.'
declare -A WANTED=()
for rel in "${RELS[@]}"; do
  [[ -z ${WANTED[$rel]+x} ]] || fail "Duplicate path in package: $rel"
  WANTED[$rel]=1
  path=$(resolve "$rel")
  safe_dest "$path"
  if [[ -e $path ]]; then
    [[ -f $path && ! -L $path ]] || fail "Not a regular file: $path"
    [[ -n ${OLD[$rel]+x} ]] || fail "Existing unmanaged file: $path. Inspect it; installer will not overwrite."
  fi
done
# No automatic migration across package layouts. Refuse to delete files
# merely because they do not exist in this release.
for rel in "${!OLD[@]}"; do
  [[ -n ${WANTED[$rel]+x} ]] || fail "Installed file absent from release: $rel. Automatic migration is unsupported; use a fresh installation."
done
if ((DRY)); then
  note "Plan OK: ${#RELS[@]} managed files; user skills: $SKILLS; release: $DATA/release"
  note "Active instructions: $CODEX/$AGENTS ($agents_mode). No install locations changed."
  if [[ -e $MANIFEST && $(jq -r .agents_block "$MANIFEST") != "$BLOCK" ]]; then
    note 'Existing managed global instruction block will be updated; other instructions are preserved.'
  fi
  if [[ $agents_mode == appended && ! -e $MANIFEST ]]; then
    printf '%s\n' '--- Proposed global Codex instruction addition ---' "$BLOCK" '--- End proposed addition ---'
  fi
  exit 0
fi
TAB="$STAGE/managed.tsv"
: > "$TAB"
for rel in "${RELS[@]}"; do
  if [[ $rel == release/* ]]; then sourcefile="$SOURCE/${rel#release/}"; else sourcefile="$SOURCE/.agents/skills/${rel#skills/}"; fi
  path=$(resolve "$rel")
  sha=$(sha256sum -- "$sourcefile"); sha=${sha:0:64}
  printf '%s\t%s\n' "$rel" "$sha" >> "$TAB"
  needs_exec=0
  case "$rel" in release/scripts/factory|release/scripts/heimdall|release/scripts/heimdall-secrets|release/scripts/heimdall-bootstrap) needs_exec=1;; esac
  if [[ -f $path ]] && cmp -s -- "$sourcefile" "$path" && \
     { ((needs_exec==0)) || [[ -x "$path" ]]; }; then continue; fi
  backup_then_write "$path" "$sourcefile"
done
if [[ -e $MANIFEST ]]; then
  old_block=$(jq -r .agents_block "$MANIFEST")
  if [[ $old_block != "$BLOCK" ]]; then
    sed '/^<!-- Heimdall global: begin -->$/,$d' "$CODEX/$AGENTS" > "$STAGE/existing-prefix"
    { cat -- "$STAGE/existing-prefix"; printf '%s\n' "$BLOCK"; } > "$STAGE/agents"
    backup_then_write "$CODEX/$AGENTS" "$STAGE/agents"
  fi
else
  if [[ $agents_mode == created ]]; then printf '%s\n' "$BLOCK" > "$STAGE/agents";
  else { cat -- "$CODEX/$AGENTS"; printf '\n%s\n' "$BLOCK"; } > "$STAGE/agents"; fi
  backup_then_write "$CODEX/$AGENTS" "$STAGE/agents"
fi
jq -R -s --arg af "$AGENTS" --arg am "$agents_mode" --arg block "$BLOCK" '
  {schema:1,agents_file:$af,agents_mode:$am,agents_block:$block,
   managed:(split("\n")|map(select(length>0)|split("\t")|{path:.[0],sha256:.[1]}))}
' "$TAB" > "$STAGE/manifest.json"
backup_then_write "$MANIFEST" "$STAGE/manifest.json"
committed=1
note "Installed ${#RELS[@]} files for the current user."
note 'Verify: bash ~/.local/share/heimdall/release/install-global.sh --verify'
note 'New project: bash ~/.local/share/heimdall/release/install.sh --project .'
note 'Start Codex in your project: codex'
