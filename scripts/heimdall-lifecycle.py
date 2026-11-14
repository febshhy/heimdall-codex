#!/usr/bin/env python3
"""Heimdall operator onboarding: inspected facts -> plan -> approved effects.

Python standard library only. Filesystem actions remain owned by the existing
installer. This controller binds human approval to source and target snapshots,
records write-ahead evidence outside the target, and offers conservative recovery.
It is not a security sandbox or publisher-signature verifier.
"""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import uuid

SCHEMA = 1
MANAGED_DIRS = ('.agents/skills', '.codex/agents', 'scripts')
EXTRA = ('.heimdall/AGENTS.md', '.heimdall/install.sh')
STATE_KINDS = {'prepared', 'applying', 'incomplete', 'installed_verified', 'complete', 'reverting', 'reverted'}

class LifecycleError(Exception):
    pass

def reject(message):
    raise LifecycleError(message)

def canonical_json(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode('ascii')

def hash_bytes(data):
    return hashlib.sha256(data).hexdigest()

def sha_file(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

def safe_regular(path):
    return path.is_file() and not path.is_symlink()

def run(*argv, check=True):
    p = subprocess.run(argv, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
    if check and p.returncode:
        reject('command failed: ' + str(argv[0]) + ' (exit ' + str(p.returncode) + '): ' + p.stderr.decode('utf-8', 'replace').strip()[:300])
    return p

def git(target, *args, check=True):
    return run('git', '-C', str(target), '-c', 'core.fsmonitor=false', '-c', 'core.hooksPath=/dev/null', *args, check=check)

def root_for(raw):
    p = Path(os.path.abspath(os.path.expanduser(raw)))
    if p.is_symlink(): reject('project path is a symlink')
    if p == Path('/') or p == Path.home(): reject('choose a specific project directory')
    if '\n' in str(p) or '\r' in str(p): reject('newlines in project paths are unsupported')
    return p

def state_root(project):
    path = Path(os.environ.get('HEIMDALL_STATE_HOME') or os.path.join(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state')), 'heimdall')).expanduser().absolute()
    if path == project or path.is_relative_to(project):
        reject('state directory must be outside the application repository')
    return path

def state_dir(base):
    for p in (base, base / 'plans', base / 'transactions', base / 'locks', base / 'active'):
        if p.is_symlink(): reject('refusing symlink state path')
        p.mkdir(mode=0o700, parents=True, exist_ok=True)
        if p.is_symlink() or not p.is_dir(): reject('invalid state directory')
        os.chmod(p, 0o700)

def atomic_json(path, document):
    payload = json.dumps(document, sort_keys=True, indent=2, ensure_ascii=True).encode('ascii') + b'\n'
    if path.is_symlink(): reject('refusing symlink state file')
    fd, name = tempfile.mkstemp(prefix='.heimdall-tmp-', dir=str(path.parent))
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(payload)
            f.flush(); os.fsync(f.fileno())
        os.chmod(name, 0o600)
        os.replace(name, path)
    finally:
        if os.path.exists(name): os.unlink(name)

def read_json(path):
    if not safe_regular(path): reject('missing/unsafe state file: ' + str(path))
    try: return json.loads(path.read_text(encoding='utf-8'))
    except (OSError, ValueError) as e: reject('invalid JSON state file: ' + str(e))

def project_key(project):
    return hash_bytes(os.fsencode(str(project)))[:32]

def lock(base, key):
    path = base / 'locks' / (key + '.lock')
    if path.is_symlink(): reject('unsafe lock')
    handle = path.open('a+b'); os.chmod(path, 0o600)
    fcntl.flock(handle, fcntl.LOCK_EX)
    return handle

def within_project(project, rel):
    if not rel or rel.startswith('/') or '\\' in rel or any(part in ('', '.', '..') for part in rel.split('/')):
        reject('unsafe managed path')
    current = project
    for part in rel.split('/'):
        current = current / part
        if current.is_symlink(): reject('symlink in managed path: ' + rel)
    return current

def release_inventory(source, bend2):
    paths = []
    for directory in MANAGED_DIRS + (('proofs',) if bend2 else ()):
        origin = source / directory
        if not origin.is_dir() or origin.is_symlink(): reject('missing/unsafe release directory: ' + directory)
        for base, dirs, names in os.walk(origin, followlinks=False):
            dirs[:] = [d for d in dirs if d != '__pycache__']
            dirs.sort(); names.sort()
            if any((Path(base) / d).is_symlink() for d in dirs): reject('symlink directory in release')
            for name in names:
                file = Path(base) / name
                rel = file.relative_to(source).as_posix()
                if rel.endswith('.pyc') or not bend2 and rel.startswith('.agents/skills/bend-proof/'):
                    continue
                if not safe_regular(file): reject('unsafe release file: ' + rel)
                paths.append(rel)
    paths += list(EXTRA)
    paths.sort()
    return paths

def source_for(source, rel):
    return source / ({'.heimdall/AGENTS.md': 'AGENTS.md', '.heimdall/install.sh': 'install.sh'}.get(rel, rel))

def render_agents(source, bend2):
    text = (source / 'AGENTS.md').read_text()
    if bend2: return text.encode()
    begin = '<!-- Heimdall Bend2: begin -->'
    end = '<!-- Heimdall Bend2: end -->'
    if text.count(begin) != 1 or text.count(end) != 1: reject('invalid optional-proof markers in source')
    # Match the original install.sh awk filter byte-for-byte, including blank
    # lines on both sides of the optional proof section.
    output = []
    skipping = False
    for line in text.splitlines():
        if line == begin:
            skipping = True
        elif line == end:
            skipping = False
        elif not skipping:
            output.append(line)
    return ('\n'.join(output) + '\n').encode()

def expected_content(source, rel, bend2):
    if rel == '.heimdall/AGENTS.md': return render_agents(source, bend2)
    if rel == 'proofs/BEND_VERSION' and bend2:
        if not shutil.which('bend'): reject('Bend 2 not available for selected proof scope')
        p = run('bend', '--version')
        version = (p.stdout + p.stderr).decode('utf-8', 'replace').strip()
        if not version or '\n' in version or len(version) > 200:
            reject('invalid Bend 2 version output')
        return (version + '\n').encode()
    return source_for(source, rel).read_bytes()

def inspect_project(project, mode, allow_dirty):
    if not project.exists():
        if mode == 'adopt': reject('adopt requires an existing Git repository')
        if not project.parent.is_dir(): reject('parent directory does not exist')
        if project.parent.is_symlink(): reject('symlink parent is unsupported')
        if git(project.parent, 'rev-parse', '--show-toplevel', check=False).returncode == 0: reject('cannot create a nested Git repository')
        return {'kind': 'absent', 'head': None, 'git_status': None, 'git_changed_files_hash': None}
    if not project.is_dir() or project.is_symlink(): reject('project must be a real directory')
    found = git(project, 'rev-parse', '--show-toplevel', check=False)
    if found.returncode:
        if mode == 'adopt': reject('adopt requires an existing Git repository')
        if any(project.iterdir()): reject('populated non-Git directory: initialize and baseline Git manually')
        if git(project.parent, 'rev-parse', '--show-toplevel', check=False).returncode == 0: reject('cannot initialize nested Git repository')
        return {'kind': 'empty', 'head': None, 'git_status': None, 'git_changed_files_hash': None}
    git_root = Path(os.fsdecode(found.stdout).strip()).resolve()
    if git_root != project.resolve(): reject('provide the Git repository root')
    if mode == 'new': reject('new requires an absent or empty non-Git directory')
    status = git(project, 'status', '--porcelain=v1', '-z', '--untracked-files=all').stdout
    if status and not allow_dirty: reject('dirty Git worktree: commit/stash or explicitly pass --allow-dirty')
    head = git(project, 'rev-parse', '--verify', 'HEAD', check=False)
    # When dirty is explicitly allowed, the hash includes the content of changed
    # regular files, not just the porcelain status or filename list.
    dirty_hasher = hashlib.sha256()
    if status:
        for item in status.split(b'\0'):
            if not item: continue
            # porcelain has a two-character status, one space, then the path.
            name = os.fsdecode(item[3:])
            path = project / name
            dirty_hasher.update(item)
            if path.is_file() and not path.is_symlink():
                dirty_hasher.update(sha_file(path).encode())
    return {'kind': 'git', 'head': head.stdout.decode().strip() if head.returncode == 0 else None,
            'git_status': hash_bytes(status), 'git_changed_files_hash': dirty_hasher.hexdigest()}

def plan_facts(project, source, mode, integrate, allow_dirty, with_bend2):
    project_state = inspect_project(project, mode, allow_dirty)
    man = project / '.heimdall/manifest.json'
    old = None
    if man.exists() or man.is_symlink():
        old = read_json(man)
        if old.get('schema') != 1 or not isinstance(old.get('managed'), list): reject('unsupported installation manifest; remove the old release manually before using this one')
        if any(item.get('path', '').startswith('docs/') for item in old['managed'] if isinstance(item, dict)):
            reject('unsupported manifest claims docs/; project documents are user-owned and will not be touched')
    bend2 = with_bend2 or (bool(old.get('bend2', False)) if old else False)
    inventory = release_inventory(source, bend2)
    active = 'AGENTS.override.md' if (project / 'AGENTS.override.md').is_file() and (project / 'AGENTS.override.md').stat().st_size > 0 else 'AGENTS.md'
    if (project / 'AGENTS.override.md').is_symlink(): reject('symlink active AGENTS override')
    root_agents_mode = str(old['root_agents']) if old else 'appended' if (project / active).exists() else 'created'
    if root_agents_mode == 'appended' and not old and not integrate:
        reject('existing active instructions require --integrate-agents')
    # Existing releases must have exactly the same managed surface. No migration
    # or retirement of files from older releases is attempted.
    old_managed = {item['path']: item['sha256'] for item in old['managed']} if old else {}
    rels = sorted(set(inventory + [active, '.gitignore', '.heimdall/manifest.json'] + list(old_managed)))
    path_state = {}
    operations = []
    for rel in rels:
        dest = within_project(project, rel)
        if dest.exists():
            if not safe_regular(dest): reject('managed destination is not regular: ' + rel)
            pre_hash = sha_file(dest)
            path_state[rel] = {'exists': True, 'sha256': pre_hash, 'mode': stat.S_IMODE(dest.stat().st_mode)}
        else:
            path_state[rel] = {'exists': False}
        if rel in inventory:
            if dest.exists() and rel not in old_managed: reject('unmanaged destination collision: ' + rel)
            if dest.exists() and rel in old_managed and pre_hash != old_managed[rel]: reject('edited managed file: ' + rel)
            operations.append({'path': rel, 'action': 'update' if dest.exists() else 'add'})
        elif rel in old_managed:
            reject('managed file absent from this release (automatic migration is not supported): ' + rel)
        elif rel == active:
            operations.append({'path': rel, 'action': 'keep' if old else 'append' if dest.exists() else 'add'})
        elif rel == '.gitignore':
            operations.append({'path': rel, 'action': 'keep_or_append'})
        elif rel == '.heimdall/manifest.json':
            operations.append({'path': rel, 'action': 'update' if dest.exists() else 'add'})
    if old:
        if old.get('agents_file') != active: reject('active AGENTS changed since prior installation')
    source_entries = {}
    for rel in inventory:
        content = expected_content(source, rel, bend2)
        source_entries[rel] = hash_bytes(content)
    # Source identity binds the plan to all installed contents, not a mutable branch name.
    release_hash = hash_bytes(canonical_json(source_entries))
    return {'schema': SCHEMA, 'project': str(project), 'mode': mode,
            'project_state': project_state, 'integrate_agents': integrate,
            'allow_dirty': allow_dirty, 'with_bend2': with_bend2, 'active_agents': active,
            'root_agents_mode': root_agents_mode, 'bend2': bend2,
            'source_sha256': release_hash, 'source_entries': source_entries,
            'paths': path_state, 'operations': operations}

def plan_id(body):
    return hash_bytes(canonical_json(body))

def validate_preflight(source, project, facts):
    if facts['project_state']['kind'] != 'git': return
    args = ['bash', str(source / 'install.sh'), '--project', str(project), '--dry-run']
    if facts['integrate_agents']: args.append('--integrate-agents')
    if facts['bend2']: args.append('--with-bend2')
    p = run(*args, check=False)
    if p.returncode:
        reject('installer preflight refused target: ' + p.stderr.decode('utf-8', 'replace')[:400])

def do_plan(source, project, base, key, mode, integrate, allow_dirty, with_bend2):
    if (base / 'active' / (key + '.json')).exists():
        reject('an incomplete operation requires recovery before planning a new installation')
    body = plan_facts(project, source, mode, integrate, allow_dirty, with_bend2)
    validate_preflight(source, project, body)
    plan = {'plan_id': plan_id(body), 'facts': body}
    plan_path = base / 'plans' / (key + '.json')
    atomic_json(plan_path, plan)
    counts = {action: sum(x['action'] == action for x in body['operations'])
              for action in ('add', 'update', 'append', 'keep', 'keep_or_append')}
    print('HEIMDALL PLAN READY')
    print('  id:', plan['plan_id'][:16])
    print('  plan file:', plan_path)
    print('  project:', project)
    print('  project state:', body['project_state']['kind'])
    print('  source content fingerprint:', body['source_sha256'][:16])
    print('  operations:', ', '.join(k + '=' + str(v) for k, v in counts.items() if v))
    print('  active instructions:', body['active_agents'], '(' + body['root_agents_mode'] + ')')
    print('  Bend 2 law-first mode:', 'enabled' if body['bend2'] else 'disabled')
    print('  review: open the saved JSON plan to inspect every proposed managed path')
    print('  docs/: protected user document area (no onboarding writes)')
    print('  architecture investigation: deferred to software-design-thinking skill')
    print('  credentials: NOT isolated by installation')
    print('  target files changed: none')
    print('  next: rerun the SAME command with --apply after reviewing the plan')

def write_journal(base, key, plan, project):
    tx_path = base / 'transactions' / (key + '-' + plan['plan_id'][:20] + '-' + uuid.uuid4().hex[:12])
    if tx_path.exists(): reject('transaction identifier already exists; inspect state')
    tx_path.mkdir(mode=0o700)
    b = tx_path / 'backup'; b.mkdir(mode=0o700)
    for rel, snapshot in plan['facts']['paths'].items():
        if not snapshot['exists']: continue
        dest = within_project(project, rel)
        if not safe_regular(dest) or sha_file(dest) != snapshot['sha256']:
            reject('file drift before backup: ' + rel)
        copy_to = b / rel
        copy_to.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
        shutil.copy2(dest, copy_to)
        if sha_file(copy_to) != snapshot['sha256']: reject('backup verification failed')
    tx = {'schema': SCHEMA, 'plan_id': plan['plan_id'], 'project': str(project),
          'status': 'prepared', 'facts': plan['facts'], 'post_hashes': {}}
    atomic_json(tx_path / 'transaction.json', tx)
    atomic_json(base / 'active' / (key + '.json'), {'transaction': tx_path.name})
    return tx_path, tx

def update_tx(tx_path, tx, status):
    if status not in STATE_KINDS: reject('invalid transaction state')
    tx['status'] = status
    atomic_json(tx_path / 'transaction.json', tx)

def do_apply(source, project, base, key, mode, integrate, allow_dirty, with_bend2):
    plan_file = base / 'plans' / (key + '.json')
    saved = read_json(plan_file)
    body = saved.get('facts')
    if not isinstance(body, dict) or saved.get('plan_id') != plan_id(body):
        reject('invalid plan digest, generate a new plan')
    if body['mode'] != mode or body['integrate_agents'] != integrate or body['allow_dirty'] != allow_dirty or body['with_bend2'] != with_bend2:
        reject('setup options differ from approved plan')
    if (base / 'active' / (key + '.json')).exists():
        reject('incomplete transaction exists; recover before proceeding')
    current = plan_facts(project, source, mode, integrate, allow_dirty, with_bend2)
    if current != body:
        reject('STALE PLAN: source or project state changed; preview again')
    validate_preflight(source, project, body)
    # Reinspect after calling the install preflight (a separate executable).
    if plan_facts(project, source, mode, integrate, allow_dirty, with_bend2) != body:
        reject('STALE PLAN: project changed during preflight')
    tx_path, tx = write_journal(base, key, saved, project)
    try:
        update_tx(tx_path, tx, 'applying')
        kind = body['project_state']['kind']
        if kind == 'absent':
            project.mkdir()  # never mkdir -p; parent must already exist
        if kind in ('absent', 'empty'):
            git(project, 'init', '-q')
        args = ['bash', str(source / 'install.sh'), '--project', str(project)]
        if integrate: args.append('--integrate-agents')
        if body['bend2']: args.append('--with-bend2')
        p = subprocess.run(args, check=False)
        if p.returncode: reject('installer failed; inspect and run recover --revert')
        # Record hashes of what the installer created before verifying. Recovery
        # may safely revert these versions, but never arbitrary later edits.
        tx['post_hashes'] = {}
        for rel in body['paths']:
            dest = within_project(project, rel)
            if safe_regular(dest): tx['post_hashes'][rel] = sha_file(dest)
        atomic_json(tx_path / 'transaction.json', tx)
        p = subprocess.run(['bash', str(project / '.heimdall/install.sh'), '--verify', '--project', str(project)], check=False)
        if p.returncode: reject('post-install verification failed; run recover --revert')
        update_tx(tx_path, tx, 'installed_verified')
        update_tx(tx_path, tx, 'complete')
        (base / 'active' / (key + '.json')).unlink()
        # Backups can include project-owned instructions. Do not retain copies
        # after verification once they are no longer needed for rollback.
        shutil.rmtree(tx_path / 'backup')
        print('HEIMDALL INSTALL VERIFIED')
        print('  architecture: not yet investigated; use the project-adoption skill')
        print('  Codex: launch explicitly from project directory')
    except BaseException:
        if tx['status'] not in ('complete', 'reverted'):
            update_tx(tx_path, tx, 'incomplete')
        raise

def recover(base, project, key, revert):
    active = base / 'active' / (key + '.json')
    if not active.exists():
        print('Heimdall: no incomplete operation recorded for this project')
        return
    pointer = read_json(active)
    txname = pointer.get('transaction', '')
    if not txname or '/' in txname or '..' in txname: reject('unsafe transaction reference')
    tx_path = base / 'transactions' / txname
    tx = read_json(tx_path / 'transaction.json')
    if tx.get('project') != str(project) or tx.get('status') not in STATE_KINDS:
        reject('transaction identity/status mismatch')
    print('Heimdall operation:', tx['status'])
    print('  plan:', tx['plan_id'][:16])
    if tx['status'] in ('complete', 'reverted'):
        if revert:
            active.unlink()  # terminal state cleanup only; no project edits
            print('Heimdall: cleared stale terminal pointer; no rollback performed')
        else:
            print('  Terminal state recorded; use recover --revert only to clear the stale pointer')
        return
    if not revert:
        print('  No changes made. Use recover --revert to restore recorded pre-install files.')
        return
    if tx['status'] not in ('incomplete', 'prepared', 'applying', 'reverting'):
        reject('only incomplete transactions can be reverted')
    # Check EVERY path before changing one. Conservative if interrupted before
    # post-hashes were recorded: existing unrecognized edits are preserved.
    steps = []
    for rel, before in tx['facts']['paths'].items():
        dest = within_project(project, rel)
        if dest.exists() and not safe_regular(dest): reject('recovery conflict (non-file): ' + rel)
        actual = sha_file(dest) if dest.exists() else None
        orig = before.get('sha256')
        installed = tx.get('post_hashes', {}).get(rel)
        allowed = {orig, installed}
        if actual is not None and actual not in allowed:
            # Most managed source files have a known expected hash even if the
            # child process crashed before returning a post-install receipt.
            allowed.add(tx['facts']['source_entries'].get(rel))
            if actual not in allowed: reject('recovery conflict (unrecognized edit): ' + rel)
        if before['exists']:
            backup = tx_path / 'backup' / rel
            if not safe_regular(backup) or sha_file(backup) != orig:
                reject('recovery backup missing/corrupt: ' + rel)
        steps.append((dest, before, tx_path / 'backup' / rel))
    update_tx(tx_path, tx, 'reverting')
    for dest, before, backup in steps:
        if before['exists']:
            dest.parent.mkdir(parents=True, exist_ok=True)
            fd, tmp = tempfile.mkstemp(prefix='.heimdall-restore-', dir=str(dest.parent))
            os.close(fd)
            try:
                shutil.copy2(backup, tmp)
                os.replace(tmp, dest)
            finally:
                if os.path.exists(tmp): os.unlink(tmp)
        elif dest.exists():
            dest.unlink()
    update_tx(tx_path, tx, 'reverted')
    active.unlink()
    shutil.rmtree(tx_path / 'backup')
    print('Heimdall: recorded files reverted. New Git metadata/directories are preserved.')

def discovery(project):
    print('HEIMDALL EXISTING-PROJECT DISCOVERY (AGENT-OWNED)')
    print('Use $software-design-thinking and $requirements to inspect the repository.')
    print('Produce a source-grounded call graph using the Call Graph Output format in AGENTS.md.')
    print('Capture shapes, state, invariants, errors, effects, needs, and owners.')
    print('Distinguish Known / Unknown / Assumption / Decision; label proposed edges.')
    print('Follow $adr: create a Proposed ADR only for a consequential decision; do not invent historical rationale.')
    print('Do not load secret values or execute project code before permission review.')
    print('Project:', project)

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('command', choices=('start', 'new', 'adopt', 'discover', 'doctor', 'recover', 'status'))
    ap.add_argument('--project', required=True)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--integrate-agents', action='store_true')
    ap.add_argument('--allow-dirty', action='store_true')
    ap.add_argument('--with-bend2', action='store_true')
    ap.add_argument('--revert', action='store_true')
    args = ap.parse_args()
    if os.geteuid() == 0: reject('run as normal user, not root')
    project = root_for(args.project)
    if args.command == 'discover':
        if args.apply or args.revert: reject('discovery is an agent-owned read/analysis task; no automatic write')
        discovery(project); return
    if args.command == 'doctor':
        for exe in ('git', 'bash', 'jq', 'sha256sum', 'codex'):
            print(exe + ': ' + ('available' if shutil.which(exe) else 'missing'))
        print('Credential isolation: NOT established by onboarding'); return
    if not shutil.which('git') or not shutil.which('bash'): reject('Git and Bash are required')
    base = state_root(project)
    state_dir(base)
    key = project_key(project)
    lease = lock(base, key)
    try:
        if args.command in ('recover', 'status'):
            recover(base, project, key, args.revert)
            return
        if args.revert: reject('--revert applies only to recover')
        source = Path(__file__).resolve().parent.parent
        if not safe_regular(source / 'install.sh'): reject('full release checkout required')
        mode = args.command if args.command in ('new', 'adopt') else 'auto'
        if args.apply: do_apply(source, project, base, key, mode, args.integrate_agents, args.allow_dirty, args.with_bend2)
        else: do_plan(source, project, base, key, mode, args.integrate_agents, args.allow_dirty, args.with_bend2)
    finally:
        lease.close()

if __name__ == '__main__':
    try: main()
    except (LifecycleError, OSError, ValueError, KeyError) as exc:
        print('Heimdall lifecycle: ' + str(exc), file=sys.stderr)
        sys.exit(2)
