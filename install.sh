#!/usr/bin/env bash
# Heimdall repository-local installer. Linux, Bash 4.4+, jq, Git and coreutils.
set -euo pipefail
umask 077

SOURCE=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
# Global installation uses a separate user-scoped lifecycle and manifest.
if [[ ${1:-} == --global ]]; then
  shift
  exec bash "$SOURCE/install-global.sh" "$@"
fi
ACTION=install
TARGET=.
INTEGRATE=0
DRY=0
BEND_CHOICE=retain
BEND2=0
BEND_PIN=
ACTIVE_AGENTS=AGENTS.md
START='<!-- Heimdall integration: begin -->'
END='<!-- Heimdall integration: end -->'
BLOCK=$(cat <<'MARK'
<!-- Heimdall integration: begin -->
## Heimdall
For software tasks, read `.heimdall/AGENTS.md` and load the applicable skills in `.agents/skills/`. Keep this repository's existing architecture, commands, and security rules.
<!-- Heimdall integration: end -->
MARK
)
GITBLOCK=$(cat <<'MARK'
# Heimdall local execution evidence
.work/
MARK
)
usage(){ cat <<'HELP'
Usage: bash install.sh [--project DIR] [--integrate-agents] [--with-bend2|--without-bend2] [--dry-run]
       bash install.sh --verify [--project DIR]
       bash install.sh --remove [--project DIR]
       bash install.sh --global [--dry-run] [--integrate-agents]
       bash install.sh --global --verify|--remove

  --global             Install shared guidance, skills, and release for this user
  --project DIR        Git repository root (default: current directory)
  --integrate-agents   Approve adding a bounded reference to active project instructions
  --with-bend2         Enable proofs (requires an installed Bend 2 binary and passing smoke proof)
  --without-bend2      Disable proof support (retain selection on same-schema reinstalls)
  --dry-run            Check and report intended changes without writing
  --verify             Check installed files and Codex instruction integration
  --remove             Remove unchanged Heimdall-managed files and integration
  --help               Show this help

Run this script from a locally inspected Heimdall release. It does not download
or execute remote code. Conflicting files and edited managed files are preserved.
HELP
}
fail(){ printf 'Heimdall: %s\n' "$*" >&2; exit 1; }
note(){ printf 'Heimdall: %s\n' "$*"; }
while (($#)); do
  case "$1" in
    --project) (($#>=2)) || fail '--project needs a directory'; TARGET=$2; shift 2;;
    --integrate-agents) INTEGRATE=1; shift;;
    --with-bend2) [[ $BEND_CHOICE == retain ]] || fail "Choose only one Bend2 flag"; BEND_CHOICE=on; shift;;
    --without-bend2) [[ $BEND_CHOICE == retain ]] || fail "Choose only one Bend2 flag"; BEND_CHOICE=off; shift;;
    --dry-run) DRY=1; shift;;
    --verify) ACTION=verify; shift;;
    --remove) ACTION=remove; shift;;
    --help|-h) usage; exit 0;;
    *) fail "Unknown option: $1";;
  esac
done
[[ $EUID -ne 0 ]] || fail 'Run as your normal user, without sudo.'
for exe in git jq sha256sum flock mktemp find sort cp mv cmp grep sed rm awk chmod timeout; do command -v "$exe" >/dev/null || fail "Missing required command: $exe"; done
((BASH_VERSINFO[0] > 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 4))) || fail 'Bash 4.4+ required'
[[ -d "$TARGET" && ! -L "$TARGET" ]] || fail "Project directory does not exist or is a symlink: $TARGET"
TARGET=$(cd -- "$TARGET" && pwd -P)
[[ "$TARGET" != '/' && "$TARGET" != "$HOME" ]] || fail 'Choose a specific project directory, not / or your home directory.'
if [[ $ACTION != install && $BEND_CHOICE != retain ]]; then fail "Bend2 flags apply to installation and updates only"; fi
if [[ $ACTION == install ]]; then
  [[ "$SOURCE" != "$TARGET" && "$SOURCE" != "$TARGET"/* && "$TARGET" != "$SOURCE"/* ]] || fail 'Run install.sh from an extracted release outside the project.'
fi
ROOT=$(git -C "$TARGET" rev-parse --show-toplevel 2>/dev/null) || fail 'Initialize a Git repository first: git init'
ROOT=$(cd -- "$ROOT" && pwd -P)
[[ "$ROOT" == "$TARGET" ]] || fail 'Install at the Git repository root (not a nested directory).'
# The lock is stored outside the project. Failed preflight leaves the repository untouched.
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/heimdall/locks
mkdir -p -- "$CACHE"
LOCKID=$(printf %s "$TARGET" | sha256sum | cut -c1-32)
exec 9>"$CACHE/$LOCKID.lock"
flock -x 9 || fail 'Cannot lock installation'
MANIFEST="$TARGET/.heimdall/manifest.json"
# Codex uses AGENTS.override.md in preference to AGENTS.md at the same scope.
# Never alter an inactive instruction file and claim successful integration.
if [[ -e "$TARGET/AGENTS.override.md" || -L "$TARGET/AGENTS.override.md" ]]; then
  [[ -f "$TARGET/AGENTS.override.md" && ! -L "$TARGET/AGENTS.override.md" ]] || fail 'AGENTS.override.md must be a regular file.'
  # Codex skips an empty override, so it must not shadow a nonempty AGENTS.md.
  [[ -s "$TARGET/AGENTS.override.md" ]] && ACTIVE_AGENTS=AGENTS.override.md
fi

safe_path(){
  local rel=$1 part accum=''
  [[ $rel != /* && $rel != *$'\n'* && $rel != *$'\t'* && $rel != *'\\'* && $rel != *'..'* ]] || fail "Unsafe path: $rel"
  IFS='/' read -ra parts <<<"$rel"
  for part in "${parts[@]}"; do
    [[ -n "$part" && "$part" != '.' && "$part" != '..' ]] || fail "Unsafe path: $rel"
    accum+="/$part"
    [[ ! -L "$TARGET$accum" ]] || fail "Symlink in destination path: $rel"
  done
}
check_manifest(){
  [[ -f "$MANIFEST" && ! -L "$MANIFEST" ]] || fail 'No Heimdall installation manifest found.'
  jq -e '(.schema == 1) and (.managed|type == "array") and
    all(.managed[]; (.path|type=="string") and (.path|startswith("docs/")|not) and
      (.sha256|type=="string") and (.sha256|test("^[0-9a-f]{64}$"))) and
    (.root_agents == "created" or .root_agents == "appended") and
    (.agents_file == "AGENTS.md" or .agents_file == "AGENTS.override.md") and
    (.bend2 | type == "boolean") and
    (.gitignore == "appended" or .gitignore == "existing") and (.gitignore_created|type == "boolean")' "$MANIFEST" >/dev/null || fail 'Invalid install manifest.'
}
root_mode=''
gi_mode=''
gi_created=false
# Hashes detect edits before same-schema refreshes and removal; they are not publisher signatures.
verify_files(){
  local rel sha dest found
  while IFS=$'\t' read -r rel sha; do
    [[ -n $rel ]] || continue
    safe_path "$rel"
    case "$rel" in .heimdall/AGENTS.md|.heimdall/install.sh|.agents/skills/*|.codex/agents/*|scripts/*|proofs/*) ;; *) fail "Unexpected managed path: $rel";; esac
    dest="$TARGET/$rel"
    [[ -f "$dest" && ! -L "$dest" ]] || fail "Missing managed file: $rel"
    found=$(sha256sum -- "$dest"); found=${found:0:64}
    [[ "$found" == "$sha" ]] || fail "Managed file changed: $rel. Review it before updating or removing Heimdall."
  done < <(jq -r '.managed[]|[.path,.sha256]|@tsv' "$MANIFEST")
}
block_is_suffix(){
  local f=$1 suffix=$2 content
  [[ -f "$f" && ! -L "$f" ]] || return 1
  # Exact bounded suffix only. A changed integration requires manual review.
  content=$(cat -- "$f")
  [[ "$content" == *"$suffix" ]]
}
verify_integration(){
  local mode expected_agents
  expected_agents=$(jq -r .agents_file "$MANIFEST")
  [[ "$ACTIVE_AGENTS" == "$expected_agents" ]] || fail "Active Codex instructions changed: expected $expected_agents, now $ACTIVE_AGENTS. Review before continuing."
  safe_path "$expected_agents"
  [[ -f "$TARGET/$expected_agents" && ! -L "$TARGET/$expected_agents" ]] || fail "Missing $expected_agents"
  block_is_suffix "$TARGET/$expected_agents" "$BLOCK" || fail "Heimdall instruction block changed or missing. Review $expected_agents."
  [[ $(grep -Fc "$START" "$TARGET/$expected_agents") == 1 && $(grep -Fc "$END" "$TARGET/$expected_agents") == 1 ]] || fail 'Multiple Heimdall instruction blocks found.'
  mode=$(jq -r .gitignore "$MANIFEST")
  if [[ $mode == appended ]]; then
    safe_path .gitignore
    block_is_suffix "$TARGET/.gitignore" "$GITBLOCK" || fail 'Heimdall .gitignore block changed. Review .gitignore.'
    [[ $(grep -Fc '# Heimdall local execution evidence' "$TARGET/.gitignore") == 1 ]] || fail 'Multiple Heimdall .gitignore blocks found.'
  else
    git -C "$TARGET" check-ignore -q .work/graphs/example.json || fail '.work/ is no longer Git-ignored.'
  fi
}
if [[ $ACTION == verify || $ACTION == remove ]]; then
  check_manifest
  verify_files
  verify_integration
  if [[ $ACTION == verify ]]; then
    note "Verified installed files and Codex instructions in $TARGET"
    for entry in scripts/factory scripts/heimdall scripts/heimdall-secrets scripts/heimdall-bootstrap; do
      [[ -x "$TARGET/$entry" ]] || fail "Required tool is not executable: $entry"
    done
    "$TARGET/scripts/factory" tools >/dev/null || fail 'Factory dependency check failed'
    note 'Factory dependency check passed.'
    if [[ $(jq -r .bend2 "$MANIFEST") == true ]]; then
      [[ -f "$TARGET/proofs/BEND_VERSION" ]] || fail 'Bend2 pin is missing'
      command -v bend >/dev/null || fail 'Bend2 enabled but bend is unavailable'
      expected_bend=$(cat "$TARGET/proofs/BEND_VERSION")
      current_bend=$(bend --version 2>&1) || fail 'Bend2 version check failed'
      [[ "$expected_bend" == "$current_bend" ]] || fail 'Bend2 version differs from pinned version'
    fi
    exit 0
  fi
  # Removal is a transaction: save every file that may be deleted or edited.
  # Ordinary errors and caught interrupts restore earlier deletions.
  REMOVE_STAGE=$(mktemp -d "$TARGET/.heimdall-remove.XXXXXXXX")
  REMOVE_BACKUP="$REMOVE_STAGE/backup"
  mkdir -p -- "$REMOVE_BACKUP"
  declare -a REMOVE_FILES=()
  while IFS=$'\t' read -r rel sha; do
    [[ -n $rel ]] || continue
    safe_path "$rel"
    mkdir -p -- "$(dirname -- "$REMOVE_BACKUP/$rel")"
    cp -p -- "$TARGET/$rel" "$REMOVE_BACKUP/$rel"
    REMOVE_FILES+=("$rel")
  done < <(jq -r '.managed[]|[.path,.sha256]|@tsv' "$MANIFEST")
  instruction_file=$(jq -r .agents_file "$MANIFEST")
  for rel in "$instruction_file" .gitignore .heimdall/manifest.json; do
    [[ -f "$TARGET/$rel" ]] || continue
    safe_path "$rel"
    mkdir -p -- "$(dirname -- "$REMOVE_BACKUP/$rel")"
    cp -p -- "$TARGET/$rel" "$REMOVE_BACKUP/$rel"
    REMOVE_FILES+=("$rel")
  done
  remove_committed=0
  remove_rollback(){
    local file restored=1
    if ((remove_committed==0)); then
      for file in "${REMOVE_FILES[@]}"; do
        mkdir -p -- "$(dirname -- "$TARGET/$file")"
        if ! cp -p -- "$REMOVE_BACKUP/$file" "$TARGET/$file"; then
          restored=0
          printf 'Heimdall: failed to restore %s\n' "$file" >&2
        fi
      done
      if ((restored==0)); then
        printf 'Heimdall: recovery files remain at %s\n' "$REMOVE_BACKUP" >&2
      fi
    fi
    if ((restored==1)); then rm -rf -- "$REMOVE_STAGE"; fi
  }
  trap remove_rollback EXIT
  trap 'exit 130' INT
  trap 'exit 143' TERM
  note 'Removing unchanged Heimdall-managed files.'
  for rel in "${REMOVE_FILES[@]}"; do
    case "$rel" in "$instruction_file"|.gitignore|.heimdall/manifest.json) continue;; esac
    rm -- "$TARGET/$rel"
  done
  sed -i '/^<!-- Heimdall integration: begin -->$/,/^<!-- Heimdall integration: end -->$/d' "$TARGET/$instruction_file"
  if [[ $(jq -r .root_agents "$MANIFEST") == created ]] && \
       [[ ! -s "$TARGET/$instruction_file" || -z $(tr -d '[:space:]' <"$TARGET/$instruction_file") ]]; then
    rm -- "$TARGET/$instruction_file"
  fi
  if [[ $(jq -r .gitignore "$MANIFEST") == appended ]]; then
    sed -i '/^# Heimdall local execution evidence$/,/^\.work\/$/d' "$TARGET/.gitignore"
    if [[ $(jq -r .gitignore_created "$MANIFEST") == true ]] &&
       [[ -z $(tr -d '[:space:]' <"$TARGET/.gitignore") ]]; then
      rm -- "$TARGET/.gitignore"
    fi
  fi
  # Prepare the directory list before deleting the manifest.
  jq -r '.managed[].path' "$MANIFEST" | awk -F/ '{if (NF>1) {NF--; OFS="/"; print $0}}' | sort -r -u > "$REMOVE_STAGE/dirs"
  rm -- "$MANIFEST"
  remove_committed=1
  while IFS= read -r subdir; do
    [[ -z "$subdir" ]] && continue
    rmdir -- "$TARGET/$subdir" 2>/dev/null || true
  done < "$REMOVE_STAGE/dirs"
  trap - EXIT INT TERM
  rm -rf -- "$REMOVE_STAGE"
  note 'Removed. Empty directories can be deleted as needed.'
  exit 0
fi

# Build an explicit install plan. All source files are regular files; symlinks fail.
declare -a RELS=()
# Retain the selected optional feature on repeat installs with the same manifest schema.
if [[ -e "$MANIFEST" ]]; then
  check_manifest
  old_bend=$(jq -r .bend2 "$MANIFEST")
  case "$BEND_CHOICE" in retain) [[ $old_bend == true ]] && BEND2=1 || BEND2=0;; on) BEND2=1;; off) BEND2=0;; esac
else
  [[ $BEND_CHOICE == on ]] && BEND2=1 || BEND2=0
fi
if ((BEND2)); then
  command -v bend >/dev/null || fail 'Bend2 requested: install and review Bend 2 first, then retry.'
  BEND_PIN=$(bend --version 2>&1) || fail 'Could not determine Bend2 version.'
  [[ -n "$BEND_PIN" && "$BEND_PIN" != *$'\n'* && ${#BEND_PIN} -le 200 ]] || fail 'Bend2 version output must be one nonempty line.'
  if [[ -e "$TARGET/proofs/BEND_VERSION" ]]; then
    current_pin=$(grep -v '^[[:space:]]*#' "$TARGET/proofs/BEND_VERSION" | sed '/^[[:space:]]*$/d' | head -1)
    [[ $current_pin == "$BEND_PIN" ]] || fail 'Installed Bend2 version differs from project pin. Review the pinned proofs and environment before proceeding.'
  fi
  [[ -f "$SOURCE/proofs/smoke/PROOF.bend" && ! -L "$SOURCE/proofs/smoke/PROOF.bend" ]] || fail 'Release is missing Bend2 smoke proof.'
  # A proof gate is meaningful only when Bend can execute this released smoke model.
  (cd "$SOURCE" && bend proofs/smoke/PROOF.bend) >/dev/null || fail 'Bend2 smoke proof failed; no files installed.'
fi
for dir in .agents/skills .codex/agents scripts; do
  [[ -d "$SOURCE/$dir" && ! -L "$SOURCE/$dir" ]] || fail "Release is missing $dir"
  while IFS= read -r -d '' item; do
    rel=${item#"$SOURCE"/}
    [[ $rel == */__pycache__/* || $rel == *.pyc ]] && continue
    [[ $rel == .agents/skills/bend-proof/* && $BEND2 -eq 0 ]] && continue
    safe_path "$rel"
    [[ -f "$item" && ! -L "$item" ]] || fail "Unsupported source entry: $rel"
    RELS+=("$rel")
  done < <(find "$SOURCE/$dir" \( -type f -o -type l \) -print0 | sort -z)
done
if ((BEND2)); then
  [[ -d "$SOURCE/proofs" && ! -L "$SOURCE/proofs" ]] || fail 'Release is missing proofs/'
  while IFS= read -r -d '' item; do
    rel=${item#"$SOURCE"/}
    safe_path "$rel"
    [[ -f "$item" && ! -L "$item" ]] || fail "Unsupported proof entry: $rel"
    RELS+=("$rel")
  done < <(find "$SOURCE/proofs" \( -type f -o -type l \) -print0 | sort -z)
fi
[[ -f "$SOURCE/AGENTS.md" && ! -L "$SOURCE/AGENTS.md" ]] || fail 'Release has no AGENTS.md'
RELS+=(.heimdall/AGENTS.md .heimdall/install.sh)
((${#RELS[@]} > 2)) || fail 'Release contains no installable files'
safe_path .heimdall/manifest.json
safe_path "$ACTIVE_AGENTS"
safe_path .gitignore

# Repeat installation: accept only the current manifest schema and unchanged managed files.
declare -A OLD=()
if [[ -e "$MANIFEST" ]]; then
  check_manifest
  verify_files
  verify_integration
  while IFS=$'\t' read -r rel sha; do
    OLD["$rel"]=$sha
  done < <(jq -r '.managed[]|[.path,.sha256]|@tsv' "$MANIFEST")
  installed_agents=$(jq -r .agents_file "$MANIFEST")
  [[ "$installed_agents" == "$ACTIVE_AGENTS" ]] || fail "Codex's active instruction file changed to $ACTIVE_AGENTS. Resolve this explicitly before reinstalling."
  root_mode=$(jq -r .root_agents "$MANIFEST")
  gi_mode=$(jq -r .gitignore "$MANIFEST")
  gi_created=$(jq -r .gitignore_created "$MANIFEST")
else
  [[ ! -e "$TARGET/.heimdall/AGENTS.md" ]] || fail 'Existing .heimdall instructions are not managed by Heimdall.'
  if [[ -e "$TARGET/$ACTIVE_AGENTS" ]]; then
    [[ -f "$TARGET/$ACTIVE_AGENTS" && ! -L "$TARGET/$ACTIVE_AGENTS" ]] || fail "Existing $ACTIVE_AGENTS is not a regular file."
    if grep -Fq "$START" "$TARGET/$ACTIVE_AGENTS" || grep -Fq "$END" "$TARGET/$ACTIVE_AGENTS"; then fail "Existing Heimdall markers without a manifest in $ACTIVE_AGENTS. Review them."; fi
    ((INTEGRATE)) || fail "Existing $ACTIVE_AGENTS is protected. Preview --dry-run --integrate-agents, then rerun with --integrate-agents to authorize an append."
    root_mode=appended
  else
    root_mode=created
  fi
  if [[ -f "$TARGET/.gitignore" ]]; then
    grep -Eq '^[[:space:]]*/?\.work/[[:space:]]*$' "$TARGET/.gitignore" && gi_mode=existing || gi_mode=appended
  elif [[ -e "$TARGET/.gitignore" ]]; then
    fail 'Existing .gitignore is not a regular file.'
  else
    gi_mode=appended
    gi_created=true
  fi
fi
# The desired package files must not overwrite unrelated project files.
for rel in "${RELS[@]}"; do
  case "$rel" in .heimdall/AGENTS.md) from="$SOURCE/AGENTS.md";; .heimdall/install.sh) from="$SOURCE/install.sh";; *) from="$SOURCE/$rel";; esac
  dest="$TARGET/$rel"
  if [[ -e "$dest" ]]; then
    [[ -f "$dest" && ! -L "$dest" ]] || fail "Path is not a regular file: $rel"
    if [[ -z ${OLD[$rel]+x} ]]; then fail "Unmanaged file exists: $rel. Review it before installing."; fi
  fi
done
# Optional Bend2 files can be removed when the operator disables that feature.
# No files from previous release layouts are migrated automatically.
declare -A PLANNED=()
for rel in "${RELS[@]}"; do
  [[ -z ${PLANNED[$rel]+x} ]] || fail "Duplicate release path: $rel"
  PLANNED["$rel"]=1
done
declare -a DELETED=()
for rel in "${!OLD[@]}"; do
  if [[ -z ${PLANNED[$rel]+x} ]]; then
    case "$rel" in
      .agents/skills/bend-proof/*|proofs/*)
        [[ $BEND2 -eq 0 ]] || fail "Unexpected release removal: $rel"
        DELETED+=("$rel") ;;
      *) fail "Release does not contain installed file: $rel. Automatic migration is unsupported; use a fresh installation." ;;
    esac
  fi
done
PROOF_BEGIN='<!-- Heimdall Bend2: begin -->'
PROOF_END='<!-- Heimdall Bend2: end -->'
[[ $(grep -Fxc "$PROOF_BEGIN" "$SOURCE/AGENTS.md") == 1 &&
   $(grep -Fxc "$PROOF_END" "$SOURCE/AGENTS.md") == 1 ]] || fail 'Release AGENTS.md Bend2 markers must each occur exactly once.'
if ((DRY)); then
  note "Installation plan OK for $TARGET (${#RELS[@]} managed files; ${#DELETED[@]} optional proof files to remove)."
  note "Project docs/ is reserved for user-authored or explicitly approved emerging documents; this installer never writes there."
  for rel in "${DELETED[@]}"; do note "  disable optional proof: $rel"; done
  note "Active instructions: $ACTIVE_AGENTS ($root_mode); Bend2: $([[ $BEND2 -eq 1 ]] && echo enabled || echo disabled); .gitignore: $gi_mode. No files changed."
  if [[ $root_mode == appended && ! -e "$MANIFEST" ]]; then
    printf '%s\n' '--- Proposed addition to active AGENTS instructions ---' "$BLOCK" '--- End proposed addition ---'
  fi
  exit 0
fi

STAGE=$(mktemp -d "$TARGET/.heimdall-stage.XXXXXXXX")
BACKUP="$STAGE/backup"
# Render installed guidance by stable, uniquely delimited feature sections.
# No line-number rewriting: changes to unrelated invariant numbering are safe.
if ((BEND2)); then
  cp -- "$SOURCE/AGENTS.md" "$STAGE/installed-agents.md"
else
  awk -v start="$PROOF_BEGIN" -v finish="$PROOF_END" '
    $0 == start { if (skip) exit 5; skip=1; next }
    $0 == finish { if (!skip) exit 6; skip=0; next }
    !skip {print}
    END {if (skip) exit 7}
  ' "$SOURCE/AGENTS.md" > "$STAGE/installed-agents.md" || fail 'Failed to remove optional Bend2 instructions.'
fi
if ((BEND2)); then
  printf '%s\n' "$BEND_PIN" > "$STAGE/bend-version"
fi
mkdir -p -- "$BACKUP"
declare -a WRITTEN=()
rollback(){
  local rel
  for rel in "${WRITTEN[@]}"; do
    if [[ -f "$BACKUP/$rel" ]]; then
      cp -p -- "$BACKUP/$rel" "$TARGET/$rel"
    else
      rm -f -- "$TARGET/$rel"
    fi
  done
  # Failed installation must not leave empty phantom skill directories.
  # rmdir refuses directories containing user-created files.
  for rel in "${WRITTEN[@]}"; do
    [[ ! -f "$BACKUP/$rel" ]] || continue
    dir=${rel%/*}
    while [[ $dir == .agents/skills/* || $dir == .codex/agents* ]]; do
      rmdir -- "$TARGET/$dir" 2>/dev/null || break
      dir=${dir%/*}
    done
  done
  # Never remove nonempty user directories; rmdir handles only empty ones.
  rmdir -- "$TARGET/.codex" 2>/dev/null || true
  rm -rf -- "$STAGE"
}
committed=0
on_exit(){ if ((committed==0)); then rollback; fi; }
trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Track backups for rollback. The manifest is published last.
write_file(){
  local rel=$1 src=$2 dest="$TARGET/$1"
  mkdir -p -- "$(dirname -- "$dest")"
  if [[ -f "$dest" ]]; then
    # Recheck owned files at the write boundary; another process may have changed them.
    if [[ -n ${OLD[$rel]+x} ]]; then
      local current
      current=$(sha256sum -- "$dest"); current=${current:0:64}
      [[ $current == "${OLD[$rel]}" ]] || fail "Managed file changed during installation: $rel"
    fi
    mkdir -p -- "$(dirname -- "$BACKUP/$rel")"
    cp -p -- "$dest" "$BACKUP/$rel"
  fi
  WRITTEN+=("$rel")
  local temp
  temp=$(mktemp "$(dirname "$dest")/.heimdall-new.XXXXXXXX")
  cp -p -- "$src" "$temp"
  # GitHub ZIP snapshots may discard executable bits. Installed factory must work
  # regardless of how the release was extracted. The prior mode is backed up.
  case "$rel" in scripts/factory|scripts/heimdall|scripts/heimdall-secrets|scripts/heimdall-bootstrap) chmod 0755 "$temp";; esac
  mv -f -- "$temp" "$dest"
}
TAB="$STAGE/managed.tsv"
: >"$TAB"
for rel in "${RELS[@]}"; do
  case "$rel" in .heimdall/AGENTS.md) from="$STAGE/installed-agents.md";; .heimdall/install.sh) from="$SOURCE/install.sh";; proofs/BEND_VERSION) from="$STAGE/bend-version";; *) from="$SOURCE/$rel";; esac
  sha=$(sha256sum -- "$from"); sha=${sha:0:64}
  printf '%s\t%s\n' "$rel" "$sha" >>"$TAB"
  # Content hashes do not encode permissions. Re-copy when the content matches
  # but a required entrypoint lost its executable bit during extraction.
  needs_exec=0
  case "$rel" in scripts/factory|scripts/heimdall|scripts/heimdall-secrets|scripts/heimdall-bootstrap) needs_exec=1;; esac
  if [[ -f "$TARGET/$rel" ]] && cmp -s -- "$from" "$TARGET/$rel" && \
     { ((needs_exec==0)) || [[ -x "$TARGET/$rel" ]]; }; then continue; fi
  write_file "$rel" "$from"
done
if [[ $root_mode == created ]]; then
  printf '%s\n' "$BLOCK" > "$STAGE/root-agents"
  write_file "$ACTIVE_AGENTS" "$STAGE/root-agents"
elif [[ ! -e "$MANIFEST" ]]; then
  { cat -- "$TARGET/$ACTIVE_AGENTS"; printf '\n%s\n' "$BLOCK"; } > "$STAGE/root-agents"
  write_file "$ACTIVE_AGENTS" "$STAGE/root-agents"
fi
if [[ $gi_mode == appended ]] && [[ ! -e "$MANIFEST" ]]; then
  { [[ ! -f "$TARGET/.gitignore" ]] || cat -- "$TARGET/.gitignore"; printf '\n%s\n' "$GITBLOCK"; } > "$STAGE/gitignore"
  write_file .gitignore "$STAGE/gitignore"
fi
# Remove only optional proof files disabled by an explicit feature change.
# Back them up so caught failures restore the original installation.
for rel in "${DELETED[@]}"; do
  safe_path "$rel"
  [[ -f "$TARGET/$rel" && ! -L "$TARGET/$rel" ]] || fail "Missing managed file before removal: $rel"
  mkdir -p -- "$(dirname -- "$BACKUP/$rel")"
  cp -p -- "$TARGET/$rel" "$BACKUP/$rel"
  WRITTEN+=("$rel")
  rm -- "$TARGET/$rel"
done
mkdir -p -- "$TARGET/.heimdall"
jq -R -s --arg ra "$root_mode" --arg af "$ACTIVE_AGENTS" --argjson b2 "$( ((BEND2)) && echo true || echo false )" --arg gi "$gi_mode" --argjson gc "$gi_created" '
  {schema:1,root_agents:$ra,agents_file:$af,bend2:$b2,gitignore:$gi,gitignore_created:$gc,
   managed: (split("\n")|map(select(length>0)|split("\t")|{path:.[0],sha256:.[1]}))}
' "$TAB" >"$STAGE/manifest.json"
write_file .heimdall/manifest.json "$STAGE/manifest.json"
committed=1
rm -rf -- "$STAGE"
trap - EXIT INT TERM
# Remove empty optional proof directories after commit. Never delete user files.
for rel in "${DELETED[@]}"; do
  dir=${rel%/*}
  while [[ $dir == .agents/skills/* ]]; do
    rmdir -- "$TARGET/$dir" 2>/dev/null || break
    dir=${dir%/*}
  done
done
note "Installed ${#RELS[@]} files in $TARGET (instructions: $ACTIVE_AGENTS; Bend2: $([[ $BEND2 -eq 1 ]] && echo enabled || echo disabled))"
note "Verify: cd '$TARGET' && bash .heimdall/install.sh --verify"
note "Start:  cd '$TARGET' && codex"
