# Contract with GUI Design Thinking

## Status

The canonical GUI Design Thinking method is now packaged at `../../gui-design-thinking/SKILL.md`; the canonical software method is `../../software-design-thinking/SKILL.md`. This mapping describes **method responsibilities**. It does not certify any particular application's UI implementation or accessibility.

## Ownership

| Owner | Supplies | Visual Design may do |
| --- | --- | --- |
| Software Design Thinking | domain types, errors, capabilities and effects | represent trusted facts without changing their meaning |
| GUI Design Thinking | job/surfaces, state classes, `update(S, Ev)`, moves, signals, voids, attention/focus contract and behavior ledger | map legal states to presentation variants; report missing state coverage |
| Content Writing | labels, explanations, exact error/status copy | place and style approved language; request a change if wording would alter behavior |
| Graph Protocol | delegated A/E/R scope and verification | implement within the owned subgraph; confirm return at the boundary |
| Existing product system | tokens, components, brand and terminology | reuse when fit; document justified deviations |

## Integration adapter

For each actual surface, use:

`Surface | Job | GUI state/event ID | Real content | Visual representation | Exact copy | Accessibility expectation | Verification | Status`

- Use identifiers from the concrete GUI state model; never invent fake canonical IDs. If the GUI contract is absent and the task needs functional decisions, invoke `$gui-design-thinking` to establish it. For a purely cosmetic change, inspect existing visible states and leave behavior unchanged.
- The GUI method makes state, navigation, transient effects, focus, keyboard behavior and error recovery authoritative. Visual Design owns spacing, type, color, grouping, images, focus **appearance**, and layout that preserves reachability and meaning.
- A responsive change that moves a pane into a drawer can alter navigation and focus; coordinate this with GUI Design Thinking. Pure responsive reflow remains local to Visual Design.
- The original GUI specification uses a 44 px touch-target default. For WCAG 2.2 AA web conformance, SC 2.5.8 uses 24 CSS px or sufficient spacing with exceptions; do not confuse that minimum with the method's stricter recommendation or platform-specific standards. Record which requirement was tested.
- If changes would alter an event, permission, error meaning, state transition, or domain promise, stop and obtain an updated upstream model.

## Evidence limits

A screenshot demonstrates appearance in one captured state/viewport. It does not establish keyboard behavior, focus correctness, screen-reader usability, all transitions, or truth of product claims. Automated accessibility checking is partial. Report each check as Passed / Failed / Not tested against its real target.
