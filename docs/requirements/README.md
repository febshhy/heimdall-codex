# Product requirements

Use this folder for **approved, testable product obligations**. Requirements describe behavior and constraints; they do not prescribe implementation detail unless that detail is itself a requirement.

Begin with [the product template](PRODUCT_TEMPLATE.md). Copy it to `product.md` when you have an approved baseline. Use separate domain files only when a single file becomes difficult to review.

## Write a requirement

- Assign a stable ID such as `REQ-CORE-001`. Do not reuse an ID for a different obligation.
- Express one observable behavior or constraint per ID.
- State conditions, actors, denied cases, and relevant failure behavior.
- Name the source or approving decision and a verification approach.
- Mark missing policy decisions as unresolved. Do not implement a guessed default.

## Status

- **Draft:** Proposed material; not approved for implementation.
- **Baseline:** Approved requirement; changes need an authorized review.
- **Provisional:** Approved direction with specific unresolved acceptance details. Do not assume those details.

Research notes, design sketches, tests, and implementation may support a requirement. They do not silently change its approved meaning.
