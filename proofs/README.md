# Bend 2 proofs

For selected product rules, Heimdall can use **approved Bend laws as the formal specification**. This is optional: ordinary application work does not require Bend 2.

The responsibilities are separate:

- **`LAWS.bend`** states the approved behavior and assumptions.
- **`SPEC.bend`** optionally defines a pure reference model.
- **`PROOF.bend`** provides proof evidence about that Bend program or model.
- **Production conformance tests** check that the application implements the proven behavior.

A proof over a model does not establish that a separate API, database, UI, or deployment behaves correctly.

## Work from approved laws

```text
User goal and scenarios
  → draft LAWS.bend
  → review and approval of exact laws and assumptions
  → model and PROOF.bend
  → Bend proof check
  → production implementation
  → conformance and integration tests
  → review
```

Do not weaken a law to make the proof pass. If the intended behavior changes, get the new law reviewed and rerun affected proofs and conformance checks. A proof result cannot approve its own requirements.

For the selected behavior, reviewed laws replace a duplicate product requirements document. Other requirements remain governed by their normal approval and testing process.

## Directory structure

```text
proofs/
  BEND_VERSION
  smoke/
    PROOF.bend
  <rule-name>/
    LAWS.bend
    SPEC.bend    # Optional model
    PROOF.bend
```

Use stable rule names. Keep the approval record in normal project code review and link each law to the production behavior and conformance checks it governs.

`smoke/PROOF.bend` checks the tool only. It never satisfies a product proof requirement. A product proof without a corresponding `LAWS.bend` is invalid.

## Verification boundary

Install a trusted Bend 2 executable outside agent control. Set `proofs/BEND_VERSION` to the observed output of `bend --version`, then use `scripts/factory proof` for selected application laws. The gate checks the version pin, law/proof pairs, and proof verdicts; a version string alone does not authenticate the executable.

Report the checked laws, model assumptions, proof results, and production conformance evidence separately. [Read the Bend proof skill](../.agents/skills/bend-proof/SKILL.md) for the full contract, or [return to setup](../marketing/SETUP.md#optional-bend-2-proofs).
