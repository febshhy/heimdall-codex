---
name: gui-design-thinking
description: >-
  Use when designing, building, or reviewing any user interface: screens, forms, flows,
  dashboards, lists, components, design systems, or interaction behavior, and when checking a UI
  for missing states, edge cases, focus, keyboard, or accessibility gaps. Make sure to use this
  whenever the user asks to build or review a GUI, even if they never say "design" or "state".
  Pairs with software-design-thinking for the logic behind the interface. Not for pure visual
  styling tweaks.
---

# GUI Design Thinking

An interface is a state machine rendered to a surface. The screen is a function of state.

```text
view     = render(S)                     pure, total
(S', F*) = update(S, Ev)                 Ev = move | signal | result

S state · Ev event · F* requested effects
move = person acts · signal = platform, clock, network · result = effect outcome
```

```text
Inv(S) ∧ update(S, Ev) = (S', _)  ⇒  Inv(S')
```

```text
No hidden state: view and update depend only on (S, Ev, P).
Every datum is exactly one of: constant | S | derived(S) | P.
P = platform-owned: focus, scroll, caret, IME composition, pointer, in-flight animation. Declared, never copied.
Anything else is hidden. Derived is computed, never stored.
```

```text
view ≅ S. Every S with Inv(S) has a view. Every view shown has an S.
A surface that can show what S cannot name is lying.
```

**Artifact:** one page containing job, state model, invariants, flow graph, void table, behavior ledger. If it doesn't fit, split the screen.

**Scale:** full guide for forms, flows, async data, destructive actions, shared state. Static content: §1–5 only. Visual style is a wrapper (§13); fix structure and behavior first.

---

## 1. Job

```text
Job · Person · Moves · Data · Constraints
```

Constraints: devices, input modalities, viewport range, locale, latency, connectivity, access level, accessibility. Stakes: reversible? how often?

Partition every statement into **Known | Unknown | Assumption | Decision**. An unknown only real data or a real person can answer: test it early.

## 2. Vocabulary

- **Surface:** an addressable place (page, pane, list, drawer). Has a name and one owner.
- **Unit:** a repeated shape (row, field, metric). Defined once.
- **Move:** what the person does. **Signal:** what the system emits.
- **Token:** a constant named by role (`text-muted`), never by value (`grey-500`).

A system that names colors but not surfaces is a palette, not a vocabulary.

## 3. State

```text
Class       Holds                                       Home
Domain      data the server owns                        Remote<T>
Navigation  where the person is                         URL
View        filter, sort, tab, selection, expanded      URL if shareable, else local S
Draft       input not yet committed                     (base, draft)
Platform    focus, scroll, caret, pointer, animation    P
```

- One owner per datum. Others read or request.
- Derived never stored: `dirty = draft ≠ base`, `empty = |items| = 0`, `canSubmit = valid ∧ ¬Submitting`.
- Shareable or restorable ⇒ URL. Reload, back, and a deep link reproduce the view.
- Draft ≠ domain. Edit a copy, commit explicitly.
- State lives at the lowest common owner of its readers.
- Persisted client state is versioned and parsed on read.

Exclusive ⇒ variant. Independent ⇒ separate axis. No Boolean pairs.

```text
Remote<T> = Idle | Loading | Ready(T) | Refreshing(T) | Failed(E, T?) | Denied
Submit    = Editing | Submitting | Succeeded | Failed(E)
Select    = None | One(id) | Many(set)
```

`isLoading ∧ isError` is representable. `Remote<T>` has no such value.

## 4. Invariants

```text
selected ∈ ids(items) ∪ {none}
0 ≤ page < pageCount
overlays form a stack; at most one is topmost
focus ∈ focusable(view) ∪ {document}
total = Σ rows                       derived, one source
```

- An event that breaks an invariant repairs it in the same update: delete the selected row ⇒ selection := neighbor | none.
- The same fact shown twice ⇒ both derive from one source.
- Prefer types that make violation unrepresentable.

## 5. Happy path

Nodes are surfaces, edges are moves. Success only.

```text
Rail(scope) → List → Detail → Commit
```

Per node: needs, In, Out, ΔS, cardinality ∈ {one, many, live}.

```text
one    detail: full record, one primary move
many   list: uniform rows, stable order, must hold 0, 1, N ≫ screen (paginate or virtualize)
live   values change while read: show age, never move an item under the pointer
```

A screen not on the graph was not requested. A node with one edge in and one out may not need to be a screen. The same surface twice ⇒ a component.

## 6. Interaction machine

When state decides what a move does: `δ : Q × Ev → Q' | ignored`. Specify Q, Ev, δ, initial state, terminal states. Every (state, event) cell is **handled | ignored | impossible**. No blanks.

```text
Editing    --Submit [valid]-->    Submitting     effect: save(key)
Editing    --Submit [invalid]-->  Editing        focus first invalid
Submitting --Ok-->                Succeeded
Submitting --Err(e)-->            Failed(e)      draft kept
Submitting --Submit-->            Submitting     ignored
Submitting --Cancel-->            Editing        cancel save
Failed(e)  --Edit-->              Editing
```

Independent axes multiply the state space:

```text
Axis          Values                                Home
mode          Editing | Submitting | ...            S
availability  Enabled | Disabled(reason) | ReadOnly  derived
pointer       Rest | Hover | Pressed                P
focus         Blur | Focus | FocusVisible           P
```

List the illegal products (Disabled × Pressed, ReadOnly × Editing). Every legal product is styled. None is left to the browser default.

## 7. Voids

V is every way content can be absent. Each region enumerates its own. Each is a designed surface, derived from S.

```text
Void      Condition                  Surface rule
Idle      Idle                       nothing, or the move that begins
Loading   Loading, no T              skeleton in the final layout
Empty     Ready(T), |T| = 0          what will appear here, and the move that fills it
Partial   Ready(T), field absent     show T, mark the absent field in place
Stale     Refreshing(T) | Failed(E,T)  keep T, mark age or failure, never blank
Error     Failed(E)                  what failed, next to it, with a retry move
Denied    Denied                     unreachable preferred; else the move to gain access
Offline   no connectivity            show cached, queue moves, mark pending
```

- Loading appears after delay d and, once shown, holds for at least m (d ≈ 200 ms, m ≈ 400 ms).
- Resolving a void causes no layout shift.
- A surface with one designed state and four undesigned ones is 20% designed.

## 8. Needs

`N(surface)`: data, permission, prior step, viewport, connectivity. Satisfied on the edge that reaches the surface.

- Unmet need ⇒ the move is absent, not a runtime branch.
- No selection is a different node, not an empty pane.
- Disabled is a last resort and carries a visible reason.
- Viewport unmet ⇒ re-route (pane becomes drawer). Never squeeze.
- A deep link is input: check the target's needs.
- Unreachable beats reachable and broken.

## 9. Boundary

Input enters at the control, and from URL, storage, server, clipboard, and drag and drop.

```text
raw → parse → trusted
```

- One field definition yields label, constraint, error text, input type, autocomplete.
- Validate on commit (blur or Enter), not per keystroke. Once an error shows, re-validate on change and clear it when fixed. Submit validates all and focuses the first invalid.
- Never discard input on failure. Keep the draft across error, navigation, and reload when retyping is costly.
- Normalize (trim, case, whitespace, Unicode) in the parse, not the view. IME composition is not input until committed. Paste takes the same parse as typing.
- URL and storage are untrusted: parse, version, fall back to the initial state on failure.

## 10. Effects

```text
move → update → (S', F*) → run F* → result → update
```

- Every request has an id. A result applies only if its id is current. Stale and out-of-order results are dropped.
- Leaving a surface cancels its in-flight effects and timers.
- Double activation yields one effect: stable idempotency key, and `Submitting` ignores `Submit`.
- Optimistic: apply to the view, keep `Pending(op, base)`. Ok ⇒ reconcile. Err ⇒ roll back to base and surface the error.
- Time is an event: delay, debounce, timeout, tick. Timers are owned and cancelled with their surface.
- Reversible beats confirmed: a destructive move offers undo. Confirm only when irreversible.
- Retry: bounded, visible, and available to the person after `Failed`.

## 11. Attention

Focus, overlays, scroll, and selection are resources: one owner, acquire, release.

- Overlay opens ⇒ focus enters, contained while modal. Escape and the close move release. Focus returns to the origin, or a defined successor if the origin is gone.
- The focused element is removed ⇒ focus moves to the next sibling, else the parent. Never silently to the document.
- Route change ⇒ focus the new surface's heading and announce it.
- Back and forward restore scroll. Live updates never jump scroll. New content out of view is announced, not injected.
- Toasts take no focus, are announced politely, and are never the only path to a move.
- Submit with errors ⇒ focus the first invalid field.

## 12. Behavior ledger

For every unit and surface, answer each row: handled | ignored | impossible.

```text
Axis          Decide
Activation    single, double, repeat, hold; ignored while Submitting
Input         paste, IME, trim, max length, autofill, drag
Timing        delay before Loading, minimum hold, debounce, timeout, retry
Order         duplicate, out-of-order, cancelled, late result after leaving
Interrupt     Escape, blur, back, navigate away, close tab with a dirty draft
Focus         after open, close, delete, submit, error, route change
Persistence   reload, back and forward, deep link, second tab, offline
Feedback      acknowledge ≤ 100 ms, progress > 1 s, completion, failure, undo
Content       0, 1, N, huge, long text, missing, RTL, locale, time zone
Environment   viewport, touch, zoom, contrast, reduced motion, theme
Access        every move by keyboard, pointer, touch; role, name, state, value
```

The accessibility tree is derived from S. It is not maintained separately. Color is never the only carrier of meaning. Touch targets are at least 44 px.

## 13. Wrappers

Motion, feedback, density, theme, sound, and haptics wrap a surface from outside.

```text
meaning(w(surface)) = meaning(surface)
```

Remove all wrappers: same information, same reachability. Reduced motion equals remove all. If removing an animation loses information, the animation carried content: put it in S.

For animated UI artwork, use compact, reusable vector/parametric geometry independent of output pixel density. Animate properties of existing shapes rather than exporting frame-by-frame SVGs or dense path keyframes; avoid duplicating shapes across frames. The motion wrapper follows the upstream transition; playback and interruption remain platform-owned `P`. Choose a platform-native implementation by the compact vector-motion rules in `references/RENDERING-AND-MOTION.md`; never make a file format or animation player part of the functional state contract. When the surface genuinely needs interactive 3D, treat the 3D scene as another presentation wrapper over the same `S` and event model: choose PBR (physical material/light response), NPR (stylized depiction), or an intentional combination; keep renderer-specific mesh buffers, shaders, hit testing, reduced motion and fallback in platform-owned `P`; meaningful geometry, selection and edits remain in the upstream `S`/domain model and picking emits explicit events. Do not introduce 3D solely for ornament or assume 3D mesh assets must be SVG/Lottie.

## 14. Components

A stable subgraph becomes a component: inputs (a named slice of S) and outputs (events). Cut along reasons to change. Its description has no "and".

- Values flow down, events flow up. No reach into global or sibling state.
- One definition per unit. One variant per legal product (§6). Variants over copies.
- Folder = feature or surface. Layers live inside it, never as top-level folders. Imports are acyclic and point toward the core.
- A wrapper that only forwards props is deleted.

## 15. Verification

Every claim has a check. A claim without one is a hope.

```text
Claim                          Check
Invalid states don't exist     types reject them: variants, no Boolean pairs
update preserves Inv           properties over generated event sequences
δ is total                     every (state, event) cell has an outcome
view = render(S)               same S ⇒ same view; reload and restore reproduce it
No hidden state                fresh load, second tab, replay: same S ⇒ same view
Every void is designed         render each void in each region
Graph independent of N         swap N: day one, year three, least access, small and slow
Results are safe               replay stale, duplicate, reordered, delayed, cancelled
Keyboard and AT parity         finish every move by keyboard only; screen-reader pass
Focus is never lost            open and close each overlay; delete the focused item; submit with errors
Extremes hold                  0, 1, 10⁵ items; long text; RTL; 200% zoom; reduced motion
Change is local                each plausible change touches ≤ 1 module
```

Swap N four ways: day one (empty account), year three (10⁵ records, titles twice as long as the mock), least access (read-only member), small and slow (one hand, poor network, reduced motion). If the design only works with ideal data, it is a screenshot.

## 16. Iteration

Build a thin slice with real data early. On new knowledge or a changed requirement: update the state model, then propagate through §2–15.

---

## Pipeline

```text
JOB
  -> "How much design?"                       -> scale
  -> "What must the person get done?"         -> job, constraints, unknowns
  -> "What are the surfaces and moves?"       -> vocabulary
  -> "What is remembered, and by whom?"       -> state classes, owners, derived
  -> "What is always true?"                   -> Inv, repaired in the same update
  -> "What is the happy path?"                -> flow graph, cardinality
  -> "What does state change?"                -> δ per control, axes, illegal products
  -> "How can content be absent?"             -> V, designed per region
  -> "What must hold to show this?"           -> N on the edge
  -> "Where does input enter?"                -> parse at the field
  -> "What leaves update?"                    -> effects: ids, cancel, optimistic, undo
  -> "Who holds attention?"                   -> focus, overlays, scroll: acquire and release
  -> "What are the small behaviors?"          -> ledger
  -> "What wraps without changing?"           -> motion, feedback, theme
  -> "What is stable, what changes together?" -> components
  -> "Does each claim have a check?"          -> verification, swap N
  -> INTERFACE                                -> view ≅ S
```
