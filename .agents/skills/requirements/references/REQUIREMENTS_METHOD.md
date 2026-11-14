# Requirements Method

Use this reference for non-trivial requirement work.

## 1. Separate information types

Keep these types separate:

- Need: stakeholder expectation.
- Requirement: approved product obligation.
- Scenario: example interaction or workflow.
- Rationale: reason for a requirement.
- Design: selected implementation approach.
- Verification: method used to check a requirement.
- Open item: information that is not yet approved.

Do not turn a scenario, finding, or design choice into a requirement without approval. For material new or unclear behavior, use `DISCOVERY_AND_SCENARIOS.md` before writing obligations; discovery records are not normative.

## 2. Write atomic requirements

Use one stable identifier and one observable obligation.

Use one `shall` statement.

Prefer explicit nouns over pronouns that depend on surrounding prose.

Avoid implementation detail unless the implementation is itself an approved constraint.

Use these condition forms when appropriate:

- `The product shall <response>.`
- `When <event>, the product shall <response>.`
- `While <state>, the product shall <response>.`
- `If <unwanted condition>, then the product shall <response>.`
- `Where <feature is enabled>, the product shall <response>.`

## 3. Make quality requirements measurable

Define the stimulus, operating condition, product response, and response measure when they affect acceptance.

Do not invent a target. Use Provisional when the measure is unresolved.

Write performance, availability, and recovery targets here as measurable requirements. Do not put them in a design card.

## 4. Preserve traceability

Keep identifiers stable.

Do not reuse a retired identifier for a different meaning.

Use repository search for reverse traceability.

Do not create a separate traceability database unless the project demonstrates a need for one.

## 5. Connect discovery to acceptance

For non-trivial new behavior, trace the relevant need and scenario to an approved requirement and a feasible verification method. A scenario may support multiple requirements, and a requirement may cover multiple scenarios. Do not create fabricated identifiers for proposed decisions.

Check a counterexample and at least the consequential failure/dependency path before declaring a new workflow understood. Record intentionally unexamined paths when their risk matters. This is a proportional review, not an instruction to produce a complete scenario matrix for every task.

If discovery exposes an unresolved material policy or target, use the Question Gate. A **Provisional** requirement requires an approved direction with an unresolved acceptance detail; an unapproved candidate remains a proposal in discovery notes. Design details and delivery-graph edges do not become product obligations unless explicitly required.
