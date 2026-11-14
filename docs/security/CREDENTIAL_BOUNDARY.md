# Credential boundary for Heimdall (November 2026)

## Guarantee and scope

**Heimdall cannot guarantee that Codex sees credential names but cannot read values when Codex has unrestricted access to the same user account, filesystem, shell or environment.** A prompt, piping, `chmod 600` under the same UID, `.gitignore`, redaction, `env -i`, masked output, or a package-manager hook does not create such a guarantee. A user can also leak credentials inadvertently in tracked source code or build/test output.

OpenAI's [Agents API sandbox security guidance](https://developers.openai.com/api/docs/guides/agents-api/environments/security) says agent-generated code can access files and credentials available in its environment. It recommends keeping third-party keys outside the environment and using a trusted proxy/server. [Vault-backed credentials](https://developers.openai.com/api/docs/guides/agents-api/tools/vaults) can substitute placeholders for real secrets at an approved network destination in supported hosted environments. Check feature availability and domain controls for your actual Codex product before use.

## Default onboarding: names only

From a project with Heimdall installed:

```bash
# This records the variable NAME and scope. It asks for no value.
python3 scripts/heimdall-secrets --project . add ACME_API_KEY \
  --provider external-vault --scope read-only --write
python3 scripts/heimdall-secrets --project . list
```

This stores **only names and enumerated provider/scope types** in `.heimdall/credential-names.json`. Do not put actual credential values into flags, shell history, registry fields, prompts, `.env` inside the agent workspace, or task output. In a separate trusted **human-operated** vault UI or trusted CLI session, add the real value and scope it to the specific endpoint/action. The user manually types or pastes into that trusted UI, not into Codex.

The metadata registry is an inventory, not a secrets store, authenticator, proxy, access-control mechanism or proof of isolation.

## Supported security architectures

| Requirement | Isolation mechanism | Exposure limit |
|---|---|---|
| Local interactive Codex, no service access | Start with no project API secrets in the Codex environment, host or mounted paths. | Codex may still access other host credentials if its sandbox permits it. |
| Third-party API calls without readable key values | Keep credentials in an operator-side secret manager. Run a trusted, **separately isolated** broker/proxy that injects a scoped key to allowlisted HTTPS endpoints or exposes narrow functions. | The agent can still **use** the delegated capability; review methods, path, budget, scopes and responses. |
| Hosted Agents API sandbox where available | Vault credential placeholder + host-restricted egress proxy (supported configuration only). | The placeholder is readable; substitution applies to approved network destinations. |
| Self-hosted automation | Run agent executor as a separate unprivileged UID/container/VM with no secret mount, inherited key, Docker socket, host process access, broad network, or permission to invoke a vault directly. | A separate host-side service authorizes requests; audit and revoke access. |

## Operator-side proxy requirements

For a production proxy, use a mature gateway or a small audited server **outside** the agent trust boundary. It must independently enforce an allowlist of exact destination hosts and API paths, allowed HTTP methods, action scope, request body size, response sanitization, redirect denial, network egress, timeouts, audit logging without secrets, and authentication of the caller. Prefer read-only endpoints and separate short-lived scoped keys. For sensitive writes, require user approval; prevent cross-project use and replay. Do not operate such a server under the same UID and unrestricted filesystem namespace as the agent.

**Piping** a secret via stdin does not hide it from an agent that can launch or inspect the consuming process; child processes, open file descriptors, process memory, output and outbound traffic can reveal it. Pipe values only within the trusted external broker or vault UI, never through an agent-controlled process.

## Human verification before starting Codex

1. Confirm the sandbox/user boundary. Running `codex` as your normal full-access desktop account is **not** strict secret isolation.
2. Check that `OPENAI_API_KEY`, project service tokens, cloud credentials, private keys and `.env` values are absent from the agent execution environment. Codex's own authentication requires care; do not claim it is opaque to its runtime.
3. Review credential **names** with `scripts/heimdall-secrets list`. Enter real values only in the external vault/host application.
4. Restrict network access and mounted directories. Check the gateway refuses unauthorized methods, hosts and paths and does not echo credential values.
5. Test a canary secret **outside** the agent's workspace and identity. Verify an agent attempt to read that canary fails; this test is a point-in-time check, not proof against all bypasses.
6. Rotate or revoke any secret previously exposed through code, logs, environment or model context.

**Unknown until deployed:** specific Codex CLI sandbox settings, network policy, agent authentication storage, OS isolation, configured vaults and their effective permissions. Heimdall's local installer cannot configure or verify those remotely.
