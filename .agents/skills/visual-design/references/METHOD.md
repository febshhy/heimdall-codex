# Design Method — platform agnostic

This is a **visual/content layer** on top of GUI behavior. It must not become a competing state machine.

## 1. Problem and people

Record goal, user outcome, audiences, contexts, platform/input modes, existing brand, content/data inventory, constraints, and success signals. Classify each as Known / Unknown / Assumption / Decision. Consult real users or product evidence where possible. An AI-generated persona is a hypothesis, not user research.

Apply **Discover → Define → Develop → Deliver** as an iterative way to widen options then test and narrow them. Do not require workshop ceremony for a small task.

## 2. Information architecture and mental model

- Identify what users expect to find, what they already know, and what they must learn.
- Name the primary user job for each surface. A dashboard's job may be *monitor and decide*, rather than one button.
- Start with actual content, realistic length variation, and honest empty-data scenarios.
- Group by meaning using proximity, common region, consistent labels, and progressive disclosure.
- Preserve navigation conventions; do not replace discoverable controls with clever icons without a reason.
- Make each decision reversibility explicit: reversible visual preference versus costly identity or navigation change.

## 3. Visual hierarchy before decoration

Specify an intended reading order, information priority, dominant element, secondary detail, and action affordances. Use scale, placement, contrast, white space, alignment, shape, and typography intentionally. Check the squint/blur test: the correct areas should dominate. Inspect dense data, long text, small screens, and large type.

Produce at least one layout with real copy before considering illustration, animation, gradients, or decorative components. A valid product-specific visual may be expressive; minimalism is not mandatory.

## 4. Visual system

- **Type:** role-based hierarchy (heading, body, annotation, controls), real writing systems/locales, legibility at zoom; avoid decorative type for primary tasks.
- **Color:** functional semantic roles, tested contrast and noncolor meanings; color conveys identity and emphasis only when it serves a purpose.
- **Space/grids:** deliberate grouping and rhythm; responsive rules preserve semantic relationships, not just stacking order.
- **Imagery/illustration:** relevant and licensed or authored, truthful to product/domain, with appropriate text alternatives. Avoid synthetic proof imagery.
- **Motion:** explain state changes or orientation; support reduced motion; never make essential information motion-only.
- **Components:** reuse platform conventions and existing components; design each relevant GUI state and interaction modality.
- **Tokens:** one authoritative source; avoid ad-hoc inconsistent values across surfaces.

Do not prescribe one particular component library, framework, font, grid size, or visual fashion.

## 5. Copy design

Use `$content-writing`. Define a voice from audience, context, and existing brand. Write content before final polish: exact labels, instructions, errors, recovery, confirmation, privacy information, and calls to action. Put critical facts first. Claims require proof. Avoid manipulative urgency and unnecessary pressure.

## 6. Deliberate choice record

Use a compact table: `Decision | Default | Choice | Reason from user/problem/evidence | How to verify`. A choice equal to the default is valid if justified. “Modern”, “premium”, and “clean” are not reasons. If there is no meaningful alternative, do not manufacture a second design solely for process compliance.

## 7. Verify outcomes, not merely appearance

Check task success, findability, information comprehension, input usability, accessible interaction, error recovery, realistic data, consistency, visual hierarchy, and copy accuracy. Use automated tools where available, then manual keyboard/screen-reader/zoom checks on relevant web work. Test with affected users for high-stakes or inclusive-design decisions. If the environment does not support a test, say `Not tested`.

For indexable public pages, apply the separate SEO gate: helpful unique content, descriptive titles, crawlable navigation, appropriate indexing, structured data only when eligible and accurate. No blanket SEO requirement for apps.

## 8. Handoff to GUI Design Thinking

Map each designed component to the GUI-owned state/event identifiers and relevant data needs. Surface any missing state. Deliver layouts, copy, tokens, responsive behavior, and accessibility expectations as a **presentation contract**. Leave event timing, action authorization, and failure transitions to GUI Design Thinking.
