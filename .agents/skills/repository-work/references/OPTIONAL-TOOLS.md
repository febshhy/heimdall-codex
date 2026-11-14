# Optional CLI capabilities for the AI agent

Probe availability when a task would benefit from an external CLI:

```sh
scripts/factory tools
```

The command prints machine-readable JSON. `required.jq` must be available;
`optional.*.available` tells the agent which local commands it may use.
Discovery does not modify the project, graph, A/E/R contract, or worker scope.
Do not install tools automatically. Use the exact `command` field, not a guessed
binary name. Tool presence does not establish authentication or repository scope.

| Tool | Availability / use | If absent |
| --- | --- | --- |
| `jq` **required** | Parse and validate JSON; factory core requires it. | Stop factory commands and report missing dependency. |
| `ast-grep` | Structural code search and checked AST rewrites in supported languages. Prefer `ast-grep`; use `sg` only if its version identifies ast-grep. | Use repository search (`rg`, `grep`) for textual investigation; do not claim semantic equivalence to AST matching. |
| `fd` | Quick filename and directory discovery; `fdfind` is an acceptable alias. Hidden/ignored files depend on options. | Use `rg --files` if available, or `git ls-files` / `find` appropriate to the scope. |
| `gh` | Read GitHub issue/PR metadata, review changes, and perform approved GitHub workflows. | Use local `git` for local operations. Report unavailable remote operations. |
| `yq` | Read or change YAML and supported non-JSON formats. Use `jq` for JSON. | Do not parse YAML with ad hoc `sed`, `grep`, or `jq`; report a missing YAML parser when exact YAML processing is necessary. |

## Variant handling

Two different `yq` implementations are common. The probe reports `variant`:

- `mikefarah`: Go implementation. Example: `yq -o=json '.' file.yaml`.
- `kislyuk`: Python-based `jq` wrapper. Example: `yq '.' file.yaml` (JSON output by default).
- `unknown`: inspect `yq --help` before using it; do not assume syntax.
- `none`: not installed.

Use `yq` primarily for YAML, and only use XML/TOML commands that the installed
variant documents. Avoid in-place modification unless the task requires it;
inspect the resulting diff and run the project's verification.

`gh` may be installed without being authenticated. Run `gh auth status` before
authenticated operations. Never push, publish, open/merge a PR, or mutate remote
state without the needed approval. A missing optional tool does not block
ordinary delegation. **If an optional tool is named in an approved node's exact
`R.verification` argv, the command is mandatory for that node.** Do not silently
skip or substitute it: correct the approved plan at a new graph boundary.

Maintain the canonical Graph Protocol: **trust nothing at the boundary; trust
everything inside** the delegated worker's subgraph. Capability discovery is
informational and cannot direct the worker while it owns that subgraph.
