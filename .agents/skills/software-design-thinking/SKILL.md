---
name: software-design-thinking
description: >-
  Use when designing, architecting, or reviewing the design of software: new features, services,
  workflows, state machines, payment, sync, or ordering flows, refactors, or any question about
  how to structure a system or model a domain. Make sure to use this whenever the user asks how to
  build, structure, or model something non-trivial, even if they never say "design". Not for small
  bug fixes or one-line edits.
---

# Software Design Thinking

A program is a graph: nodes are typed steps, edges are data flow. The code is the graph.

```text
node : (S, In) → Ok(S', Out, F*) | Err(E)      requires R

S state · In input · Out output · F* requested effects · E expected errors · R needs
```

```text
Inv(S) ∧ node(S, In) = Ok(S', _, _)  ⇒  Inv(S')
```

```text
No hidden state: (Out, S', F*) depends only on (S, In, ρ), where ρ = responses from R.
Every datum is exactly one of: constant | input | S | owned resource in R.
Anything else is hidden.
```

```text
code ≅ graph. If they differ, fix the graph first, then the code.
```

**Artifact:** one page containing shapes, invariants, graph, errors, needs, owners. If it doesn't fit, split the problem.

**Scale:** full guide for stateful, effectful, or costly-to-fail problems. Simple glue: §1–4 only. Add a component only if the graph requires it.

---

## 1. Problem

```text
Goal · In · Out · Rules · State · External · Constraints
```

Constraints: latency, throughput, cost, availability, security, observability.

Inventory every datum that outlives a call. Classify each: constant | input | S | owned resource. No fifth category.

Partition every statement into **Known | Unknown | Assumption | Decision**. An unknown that only running code can answer: spike it, feed the result back.

## 2. Shapes

Types: records, IDs, variants, commands, events, errors.

- Different meaning ⇒ different type.
- Exclusive states ⇒ variant, never Booleans.
- Errors are values, not strings.
- Shapes that are persisted or transmitted are versioned.

```text
PaymentState = Unpaid | Authorized(AuthId) | Captured(PaymentId) | Refunded(RefundId)
OrderError   = OrderNotFound(OrderId) | InvalidTransition(State, Cmd) | PaymentRejected(Reason)
```

## 3. Invariants

Predicates true in every state.

```text
balance ≥ 0        start ≤ end        state = Paid(p) ⇒ p exists
```

Make violations unrepresentable. The same check in two places ⇒ the model is wrong.

## 4. Happy path

Draw the graph over success only.

```text
PlaceOrder → Validate → ReserveStock → CapturePayment → ConfirmOrder
```

Per node: In, Out, ΔS, cardinality ∈ {one, many, windowed}.

## 5. Lifecycle

When state determines legality: `δ : Q × C → Q' | Err`. Specify Q, C, δ, initial state, terminal states, in one model.

```text
Draft     --Submit-->          Submitted
Submitted --PaymentAccepted--> Paid
Submitted --Cancel-->          Cancelled
Paid      --Refund-->          Refunded
```

## 6. Pure decisions

```text
decide(S, C) → Ok(S', F*) | Err(E)
```

`decide` depends on its arguments only: no database, network, clock, files, randomness, or LLM. Facts in, effects out. A trivial decision gets no `decide`.

## 7. Errors

Each expected error gets exactly one strategy: **propagate | translate | recover | retry**.

```text
OutOfStock      → propagate
SqlTimeout      → translate to StoreUnavailable
CacheMiss       → recover
ConnectionReset → retry
```

- A defect (impossible state) ∉ E. Fail loudly.
- Each layer maps `E_below → E_own` exhaustively. Callers never see deeper errors.
- A node's error handling lives in one place, so the happy path reads alone. Exception: two uses of one node need different failure semantics. Handle each locally, mark it, keep it rare.
- Multi-step flow, step k of n fails ⇒ undo | compensate | resume.

## 8. Needs and effects

`R(n)` is the set of capabilities node n requires. The core defines the contract; the outside provides it.

```text
decide → (S', F*) → execute F* → typed result → decide
```

- Executors never mutate domain state.
- If losing an effect breaks correctness, persist its intent first.
- A contract exists only at a real boundary: external system, independent failure, independent ownership, security, or replaceable implementation.

## 9. Boundary

```text
unknown → parse → trusted
```

Parse once, at the edge. Inside, trust the types.

## 10. Ownership

`|Owner(r)| = 1` for every mutable resource r. The owner defines who mutates, ordering, consistency, and failure behavior. Others request.

Acquire and release are bound to scope, so cleanup holds on success, error, and cancellation.

## 11. Idempotency

```text
run(k) ; run(k) ≡ run(k)
```

Retry iff transient ∧ repeat-safe ∧ bounded count ∧ bounded time. One layer owns the policy.

## 12. Wrappers

Cross-cutting behavior w (retry, timeout, auth, tracing, caching) wraps a node from outside.

```text
meaning(w(n)) = meaning(n)
```

This holds for results only, not for state. A wrapper that keeps state (cache, breaker, dedupe table, retry counter) is a resource: owned, declared in R.

## 13. Modules

A stable subgraph becomes one interface that hides more than it exposes.

```text
BuildRequest → Sign → Send → Decode → MapStatus   ⇒   PaymentGateway.capture
```

A wrapper that only renames is deleted.

## 14. Verification

Every claim has a check. A claim without one is a hope.

```text
Claim                           Check
Invalid shapes don't exist      types reject them
Nodes preserve Inv              properties over generated sequences
Every error has a strategy      every branch exercised
Boundary contract holds         real system
Repeats are safe                run twice, compare
Graph independent of R          swap R: same graph, same outputs, same errors
No hidden state                 same (S, In, ρ) ⇒ same result: replay, fresh process, shuffled order, parallel
```

If the graph fails under swapped R, it has a hidden dependency. Stand-ins verify the graph, not the boundary. Confidence is not proof.

## 15. Iteration

Build a thin end-to-end slice early. On new knowledge or a changed requirement: update the graph, then propagate through §2–14.

---

## Pipeline

```text
PROBLEM
  -> "How much design?"                 -> scale
  -> "What must hold, under what limits?" -> behavior, constraints, unknowns
  -> "What is remembered, and where?"   -> inventory, classify, no fifth category
  -> "What are the shapes?"             -> types, variants, versions
  -> "What is always true?"             -> Inv
  -> "What is the happy path?"          -> graph, cardinality
  -> "Does state change legality?"      -> δ
  -> "What is pure?"                    -> decide
  -> "Where does it break?"             -> E: strategy per error, per layer
  -> "What does each node need?"        -> R, effects, persisted intent
  -> "Where does untrusted data enter?" -> parse
  -> "Who owns each resource?"          -> one owner, scoped
  -> "What if it runs twice?"           -> idempotency, bounded retry
  -> "What wraps without changing?"     -> wrappers
  -> "What is stable?"                  -> modules
  -> "Does each claim have a check?"    -> verification, swap R
  -> CODE                               -> code ≅ graph
```
