---
name: content-writing
description: Write and review clear, accurate, inclusive user-facing copy in English, Bahasa Indonesia, and other project languages: UI messages, microcopy, README files, guides, release notes, and public pages. Preserve the product voice, state contract, and source evidence.
---

# Copy and content design — information contract

**Authority:** wording and reader comprehension; never change product behavior, domain promises, access, permission or GUI transitions. Use for UI copy and standalone guides, README, public pages and documentation. Pair with `$gui-design-thinking` for functional UI wording, `$visual-design` for presentation, `$repository-work` for repository documents. A standalone document does not need a UI state machine.

```text
Reader + locale + task + approved product state + source evidence
  → What must reader learn or do? (Known | Inferred | Unknown | Example)
    → Draft reader-first, precise, inclusive copy
      → Verify reality and UI state/permission semantics
        → Writing-quality review (+ RASA for en/id)
          → Revise → Deliver copy deck | Document
```

## Information and state contract

| Content | Required source/guard | Output |
| --- | --- | --- |
| UI labels/buttons | Real action and state; labels not placeholders | Action-oriented text. |
| Error/empty/loading/success | Actual outcome and supported recovery | What happened + next step, no blame or invented recovery/progress. |
| Destructive/permission | Known consequences and timing | Explain before irreversible effect or system prompt. |
| Technical guides | Inspected current code, prerequisites and commands | Accurate executable instructions; mark examples and unknowns. |
| Marketing/public copy | Verified capabilities, audience and product voice | Useful benefits with defensible limits, no fabricated claims. |

**Truth guards:** distinguish documented fact, inference, hypothetical example, unverified behavior and opinion. Never invent users, testimonials, benchmarks, sources, log outputs, approvals or safety guarantees. Source-check illustrative analogies and their real-world limits. Do not include internal editorial notes, draft prompts, private reasoning or publisher-only residue in public copy; do not hide consequential product limits.

## Writing and review

Establish audience, locale, job, context, voice and terminology. Put useful result/action first; use meaningful headings, descriptive links, specific nouns, natural active sentences, examples that show real behavior and no filler. Preserve precision and technical meaning. Check inclusive, non-stigmatizing language, number comprehension, localization, translation expansion, screen-reader comprehension and noncolor meaning. Length/style preferences are heuristics; never override evidence or approved product voice.

For substantial work load `references/WRITING_QUALITY.md` and `../visual-design/references/SLOP.md`; English/Bahasa Indonesia additionally use `references/PLAIN_LANGUAGE_AND_RASA.md`: **Ritmis/Rhythmic → Akurat/Accurate → Sarat makna/Substantive → Alami/Authentic**. For other languages follow their native conventions and transferable principles. Do not reduce RASA to an invented score. Public indexable content uses `../visual-design/references/SEO.md` only where relevant; avoid keyword stuffing.

**Markdown docs:** keep readable content in Markdown, not text baked into images. Use one meaningful H1, ordered headings, blank lines, tagged code fences, appropriate lists, working relative links/anchors, alt text for meaningful illustrations, and readable mobile layout when relevant. Images must add independent meaning; keep claims/qualifications as text. Do not automatically write protected `docs/`.

**Deliver:** UI copy deck `surface/state → exact text → intent → evidence → accessibility/localization → status`; ordinary docs → revised document plus material verified/hypothetical/open claims. For minor edits scale review down, not accuracy.
