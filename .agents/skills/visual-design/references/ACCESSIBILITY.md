# Inclusive and accessible interface design — acceptance checklist

**Scope.** Applies functional inclusive-design principles across platforms. For web use current applicable WCAG 2.2 success criteria as a baseline and check the actual standard. Native interfaces should use equivalent platform accessibility APIs and guidance. Claim compliance only after testing the implemented UI against the declared standard and scope; a checklist or automated tool alone is insufficient.

## People and context

- Recognize permanent, temporary, and situational disabilities: low vision/blindness, color-vision differences, limited motor control, hearing differences, cognitive/reading needs, and constrained bandwidth/devices.
- Test multiple input methods: pointer/touch, keyboard/switch, screen reader, voice where supported. Avoid pointer-only affordances or hover-only instructions.
- Support readable language and localization: maintain layout with long labels, other scripts, right-to-left where used, and date/number conventions.
- Do not assume a generic persona represents an affected user. Seek real feedback where material.

## Functional checks for web (WCAG 2.2, where applicable)

| Concern | Requirement/check | Reference |
| --- | --- | --- |
| Text contrast | At least 4.5:1 for normal text; 3:1 for large text, subject to exceptions | WCAG SC 1.4.3 |
| Non-text contrast | At least 3:1 for relevant graphical objects and UI component state indicators, subject to exceptions | SC 1.4.11 |
| Color alone | Do not convey status or instructions by color alone | SC 1.4.1 |
| Zoom / reflow | Text resizes to 200% without lost functionality; relevant content reflows at narrow equivalent widths | SC 1.4.4, 1.4.10 |
| Keyboard | Reach and operate every function; logical focus order and no keyboard trap | SC 2.1.1, 2.1.2, 2.4.3 |
| Focus visibility | Keyboard focus is visible and not fully obscured | SC 2.4.7, 2.4.11 |
| Target size | WCAG 2.2 AA 2.5.8 has a 24×24 CSS px target size or sufficient spacing, with exceptions; do not mistake this for 44 px AAA target guidance | SC 2.5.8 |
| Labels / roles | Persistent meaningful names and instructions, programmatic relationships, name/role/value | SC 1.3.1, 3.3.2, 4.1.2 |
| Errors | Identify errors and provide correction help; important status changes communicated to assistive tech | SC 3.3.1, 3.3.3, 4.1.3 |
| Motion | Honor reduced-motion preferences as a design default; avoid animation that is essential to understand state | Relevant WCAG motion criteria + platform preference |
| Authentication | Avoid unnecessary cognitive-function tests; support accessible authentication options per applicable SC | SC 3.3.8 |

The table is an engineering aid, **not a complete conformance audit**; exceptions and definitions matter. For example, 24 CSS px is not a universal recommended touch size or a native-platform requirement.

## State-by-state evaluation

For each state ID from GUI Design Thinking, inspect visual and assistive interpretation: default, focus, selected, busy, empty, success, error, disabled, or other states present in the contract. Confirm consistent announcements, labels, recovery text, contrast, affordance and alternative input. Do not create new state-transition requirements in this skill.

## Verification levels

1. **Design checks:** review contrast estimates, grouping, textual alternatives, meaning, focus plan, reflow, target sizing, error copy.
2. **Implementation checks:** automated checks when available, plus manual keyboard navigation, zoom/reflow, screen-reader inspection, reduced-motion and localization checks.
3. **User research:** where important, ask relevant people to perform real tasks. Simulated disability personas are not substitutes.

Report `Passed`, `Failed`, or `Not tested` per check and platform. Avoid an unsupported “100% accessible” claim.

## Sources

- WCAG 2.2 specification: https://www.w3.org/TR/WCAG22/
- WCAG 2.2 quick reference: https://www.w3.org/WAI/WCAG22/quickref/
- W3C ARIA Authoring Practices: https://www.w3.org/WAI/ARIA/apg/
- W3C form labeling: https://www.w3.org/WAI/tutorials/forms/labels/
- Microsoft Inclusive Design: https://learn.microsoft.com/en-us/learn/modules/write-inclusive-windows-apps/
