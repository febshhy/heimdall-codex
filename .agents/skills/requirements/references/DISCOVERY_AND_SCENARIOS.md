# Discovery and Scenario Reasoning

Use this reference when the required behavior is new, under-specified or costly to get wrong. The purpose is to establish the **product contract** before selecting software, GUI or database structures. It is a reasoning aid, not a form required for every task.

## 1. Start with the outcome and contrary evidence

Ask only the questions that can change the decision:

- **Who and why?** Primary/secondary actors, their goal, the observed problem, and evidence that the problem exists. A requested solution can be authorized scope without being evidence that it solves the problem.
- **What is already true?** Approved Baseline requirements, current behavior, actual constraints, existing contracts, and stated user decisions. Current code and stakeholder opinions are evidence with different authority.
- **What is inside and outside scope?** User-visible outcome, exclusion, data sensitivity, business rules, time boundaries, and applicable platforms.
- **What alternatives or counterexamples matter?** Could an existing workflow satisfy the goal? What is the smallest useful behavior? What observation would disprove the preferred interpretation?

Keep **Verified fact / Inference / Assumption / Proposed decision / Approved requirement / Unknown** distinct. An unknown acceptance target stays unknown. Do not invent stakeholder consent.

## 2. Select paths by consequence and uncertainty

Start with one main **happy path**: trigger, preconditions, actor, observable result and completion rule. Add other paths when their consequences, probability or uncertainty justify examination:

| Lens | Probe | Example |
| --- | --- | --- |
| Unhappy: invalid/rejected | What if input is malformed, a rule rejects it, or access is denied? | Invalid input, unauthorized report access |
| Missing/empty | What if required data does not exist, is stale or is incomplete? | Empty history, deleted entity |
| Dependency/degraded | What if an upstream source is slow, unavailable or inconsistent? | Identity service unavailable |
| Interrupted | What if the user cancels or a process stops midway? | Navigation or process restart |
| Concurrent/repeated | What if two actors change the same item or the request repeats? | Conflicting edits, duplicate command |
| Security/abuse | What if a caller bypasses the expected interface or misuses a privilege? | Direct API request outside team scope |
| Recovery/evolution | What survives retries, restore, rollout or policy/data changes? | Failed export resumption, revoked permissions |

For each **material** path, capture `trigger/preconditions -> expected externally observable response -> rule that must remain true -> evidence/check`. Use a decision table when conditions overlap or conflict. Include lifecycle/time transitions when relevant. Some scenarios may produce several requirements; others need only a test or an explicit out-of-scope decision. Do not force a one-to-one mapping.

Prefer a few high-impact cases and a counterexample to a broad, speculative edge-case inventory. For a critical path, include failure and recovery and the point at which the system can no longer guarantee the outcome. Negative scenarios require explicit authorized behavior, not a default policy invented by the agent.

## 3. Separate dependency types

| Type | Requirements question | Handoff |
| --- | --- | --- |
| Product/precondition | What must be true before the user can proceed? Who authorizes it? | Requirements |
| External authority/integration | Who owns the source of truth? What contract or availability is assumed? | Requirements for promised behavior; Software Design Thinking for runtime effects |
| Domain/data | Which facts, invariants and resources must be consistent? | Software Design Thinking, then Database Design for storage |
| Delivery/work | Which task or decision must be accepted before implementation starts? | Software Factory / Graph Protocol |

A dependency can impose a required behavior, but choosing its API, retry algorithm, table or task edge is usually a *design* decision. Record failure, timeout and staleness consequences as candidate product requirements only when they affect observable behavior or acceptance. Keep uncertainties explicit.

**Authority boundary:** This reference owns *discovery of product-level questions*, not the implementation of every dependency it identifies. Accepted product obligations come from the applicable Baseline record or explicit authorized user scope; a Proposed scenario is not a requirement, and Provisional does not mean guessed approval. Domain constraints belong to Software Design Thinking, persisted representation to Database Design, UI events to GUI Design Thinking, and task sequencing/A/E/R to Graph Protocol. If a downstream design reveals a different product rule, return it through the Question Gate and Change procedure instead of silently changing the accepted behavior. See `AGENTS.md` for the project-wide authority map.

## 4. Compact discovery record (when worthwhile)

```text
Feature / outcome: <name and success criterion>
Actors and scope: <who, context, exclusions>
Evidence: <verified source and current behavior>
Assumptions / unknowns: <which missing facts change acceptance>
Key scenarios: <happy and the selected consequential alternatives>
  - <trigger/preconditions> -> <observable response> | invariant=<rule> | check=<method>
Dependencies: <product prerequisites, external authorities, design/work handoffs>
Candidate requirements: <proposed, not approved; reference accepted IDs when present>
Decisions needed: <question, decision owner if known, impact of delaying>
Coverage rationale: <why these paths, what was deliberately not expanded>
Next action: <Question Gate | Change authorized requirement | Design from existing requirements | Blocked>
```

Keep this in task notes unless the project has a suitable durable research/requirements convention. Never write candidate behavior directly into the Baseline file. Where direction is explicitly approved but an acceptance detail is unresolved, the Change procedure may record a **Provisional** requirement; otherwise mark the candidate **Proposed** in the discovery note without assigning it a normative ID.

## 5. Reasonable stopping and handoff

Discovery is ready to hand off when:

- The actor, outcome, explicit scope and source of authority are clear enough for the next task.
- Consequential happy, rejected/failed and dependency paths are represented, or justified as not relevant.
- Product rules and acceptance checks are observable; thresholds are sourced or explicitly unknown.
- High-impact contradictions or expensive-to-reverse decisions have an owner and a question, or block further work.
- Design/implementation details remain with their proper owners rather than becoming accidental requirements.

The stop rule is **decision sufficiency**, not scenario count. Reopen discovery if design, testing or production evidence exposes a missing rule.

## 6. Illustrative example (not project requirements)

**Request:** "Allow users to export reports for their teams."

- Happy: A permitted member requests an export and receives an authorized result.
- Rejected: A caller requests a different team's report through the API; expected denial and disclosure policy require confirmation if not already specified.
- Dependency: Team membership must come from an identified authoritative source; availability and staleness promises are unknown until established.
- Temporal: Membership changes while an export runs; whether authorization is evaluated at submission, execution or delivery is a **product/security decision**, not an assumed answer.
- Recovery: A failed export retries; repeat effects and access checks need explicit design once the required semantics are approved.

**Handoff:** Confirm the authorization/consistency policy with its owner. Do not invent a requirement ID, time target, service name or storage schema. Once accepted, specify observable requirements and let Software Design Thinking determine state/effects and Database Design determine persistence where needed.
