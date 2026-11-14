# Anti-slop review — visual work and copywriting

**Definition for this skill:** A design or message that looks plausible but lacks task-specific intent, substance, evidence, or critical evaluation. It is a quality assessment, not a reliable detector of whether AI was used. There is no universal “slop aesthetic.”

## 1. Visual failure patterns — investigate, do not ban styles

| Signal | Diagnostic question | Repair |
| --- | --- | --- |
| Reusable hero template | Would the layout still work unchanged for an unrelated product? | Ground composition in the actual product, audience, and key information. |
| Generic abstract gradients, glow, stock people, 3D blobs | Does the imagery encode a real idea, feature, relationship, or identity? | Replace with useful product evidence, real data, or remove. |
| Cards everywhere | Do borders and boxes express hierarchy or group meaningful items? | Use whitespace, tables, lists, typography, or fewer groups when clearer. |
| Weak hierarchy | Can a first-time user locate the main purpose and next action in seconds? | Reorder content and adjust scale/contrast/spacing. |
| Beautiful single state | Are error, empty, loading, focus, long text, and narrow screens usable? | Implement all upstream states and examine realistic content. |
| Fake dashboards | Are charts, metrics, customers, maps, or logos real and labeled? | Use provided data or clearly label a demonstration; don't disguise placeholders as evidence. |
| Contrived visual novelty | Does deviation from platform conventions improve the actual task? | Prefer familiar affordances unless evidence justifies change. |
| Copy pasted visual system | Can each major choice be traced to a documented brief or existing system? | Record deliberate decisions; inherit established tokens where valid. |

A gradient, card, sans-serif font, or neutral palette can be the right choice. Never use a lexical/style blacklist as a substitute for design critique.

## 2. Copywriting failure patterns

- **Unsupported superlatives:** “best,” “industry-leading,” “10x faster,” “trusted by millions” without evidence. Mark provisional or remove.
- **Empty promises:** “Transform your workflow,” “Unlock potential,” “The future of X.” Name a concrete action/result if verified.
- **Vague CTA:** “Get started,” “Learn more,” “Experience magic” when a precise action is available. Use “Create invoice,” “Compare plans,” or the actual verb.
- **Brand swap:** If replacing the product name with a competitor preserves the entire claim, the copy probably lacks product-specific facts.
- **Inflated helpfulness:** Long introductions before the answer, repetitive enthusiasm, pseudo-insight, invented stories, and wordy apologies. Lead with what users need.
- **False social proof:** Testimonials, named customers, screenshots, quotes, author identities, case studies, counts, and review stars require real sources and permission where appropriate.
- **Manipulative pressure:** False scarcity, hidden terms, deceptive confirm-shaming, sneaky recurring costs, misleading comparisons. Correct the interface, not just the text.
- **Failure copy without recovery:** Say what happened, what remains safe, and what the user can do next, in language the UI state actually supports.
- **Decorative metaphor:** A story sounds distinctive but its cause and effect cannot be mapped accurately to the product. Retain only a supported mapping and name its limits.
- **Synthetic cadence:** Every paragraph repeats the same three-step rhythm, contrast slogan, flourish, or concluding summary. Vary only where it improves comprehension, and cut repetition.
- **Illustration presented as proof:** A hypothetical scenario, screenshot-like artwork, or fictional story seems to demonstrate tested product behavior. State the evidence status nearby.
- **Process inversion:** The narrative rearranges implementation, review, checks, reporting, and warning merely to match a metaphor. Preserve the real sequence; let the metaphor remain subordinate.

For substantive human-facing documents, apply `../../content-writing/references/WRITING_QUALITY.md`. These are **diagnostic signals**, not proof of AI authorship or a prohibition on creative writing.

## 3. Five practical tests

1. **Swap test:** Cover the brand and replace the name. Identify every sentence/visual that could belong to anything; replace generic parts with *true* specifics or cut them.
2. **Evidence test:** For each quantitative or comparative claim, provide a real source. Record `Verified`, `Provisional`, or `Remove`.
3. **Squint test:** Blur or distance the interface. The intended purpose and groupings should be more prominent than decoration.
4. **Delete test:** Remove each sentence/section. If the user's decision or task is unchanged, consider cutting it.
5. **Reality test:** Use actual domain data, long names, zero items, failures, localization, keyboard-only navigation, and assistive technologies; a single polished mockup is not proof.

## 4. Evaluation boundary

Use qualitative review and task testing, not an invented numeric “AI slop score.” Record which concrete failure was found and what changed. The designer may choose a conventional solution when it is best. Distinctiveness must not defeat accessibility or usability.

## 5. Source basis

- Nielsen Norman Group, *The Custodial Era of UX: Cleaning Up After AI*: https://www.nngroup.com/articles/ai-ux-debt/
- Nielsen Norman Group, *5 Principles of Visual Design in UX*: https://www.nngroup.com/articles/principles-visual-design/
- Nielsen Norman Group, *Proximity Principle in Visual Design*: https://www.nngroup.com/articles/gestalt-proximity/
- GOV.UK, *Writing for user interfaces*: https://www.gov.uk/service-manual/design/writing-for-user-interfaces
- Google Search Central, *Creating helpful, reliable, people-first content*: https://developers.google.com/search/docs/fundamentals/creating-helpful-content
- Nielsen Norman Group, *Artificial Intelligence: Glossary* (“AI Slop”): https://www.nngroup.com/articles/artificial-intelligence-glossary/
