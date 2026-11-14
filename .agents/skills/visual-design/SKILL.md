---
name: visual-design
description: Use for visual styling, layout, visual hierarchy, responsive composition, typography, color, tokens, component presentation, brand identity, or visual design reviews of interfaces and public pages. Render the behavior defined by gui-design-thinking; do not invent interaction state or domain rules. A pure styling edit needs visual-design only. For building or reviewing a functional GUI also use gui-design-thinking; use content-writing for substantive words or documentation.
---

# Visual design — state-preserving presentation

**Authority:** layout, hierarchy, typography, color, imagery, tokens, responsive composition and visual variants. `$gui-design-thinking` owns UI states/events/focus; `$software-design-thinking` owns domain logic; `$content-writing` owns words. A visual wrapper must preserve upstream meaning, permissions and recovery. Pure cosmetic work needs only affected states; functional GUI changes also require GUI Design Thinking. If an interaction decision lacks an upstream contract, report the gap and route it to its owner before changing presentation.

```text
Known product content + upstream legal GUI states + platform constraints
  → Choose scale: small reuse | full visual-system design
    → Read context, real content, audience, device/input and tokens
      → Define reading priority and presentation choices
        → Map every applicable state → visual variant
          → Inspect accessibility and actual rendering
            → Verified | Failed | Not tested → report
```

| Work scope | Conditional guidance |
| --- | --- |
| Small styling edit | Reuse existing design system/tokens; inspect affected states; verify. |
| New surface/identity/multi-layout or high stakes | `references/METHOD.md`, `references/SLOP.md`, `references/ACCESSIBILITY.md`, `assets/DESIGN_CARD.md`. |
| Functional interaction | `$gui-design-thinking` and `references/COMPATIBILITY.md`; do not invent UI behavior. |
| Substantive words / public SEO | `$content-writing`; `references/SEO.md` only for genuinely indexable, in-scope public content. |
| Research-dependent decision | `references/RESEARCH.md`; mark unknowns rather than inventing personas/brands. |

**State coverage:** present each upstream legal default, loading, empty, partial, stale, error, denied, success, focus, pressed, selected, disabled state **when applicable**; do not invent new functional states. A variant must preserve its event, permission and recovery meaning. Plan information hierarchy before decoration; use real content and native platform conventions. Record actual material choices as `Decision | Default | Choice | Reason | Check` when useful; do not force comparison when one established design is sufficient.

**Motion and 3D (conditional):** use compact reusable vector/parametric geometry with logical coordinates, transform/property animation and few meaningful keyframes. No PNG frame sequence, SVG-per-frame exports, bloated traced paths, duplicated per-frame shapes or unneeded Lottie. Prefer native motion; a specific format/player is optional. Genuine 3D must declare **PBR** (plausible material/light), **NPR** (intentional stylization), or justified hybrid; use compact meshes/materials, avoid per-frame raster/mesh exports, keep meaningful 3D interaction in upstream GUI/domain state. Check depth, legibility, input, reduced motion and static/2D alternative. For actual budgets and target testing use `../gui-design-thinking/references/RENDERING-AND-MOTION.md`.

**Verification:** check focus, keyboard, assistive-technology meaning, noncolor status, WCAG 2.2 AA where applicable on web, native platform standards elsewhere, zoom/reflow, contrast, localization, long text, touch, reduced motion and representative real/edge data. Use swap/squint/real-content checks in `references/SLOP.md`. Inspect actual rendered output at relevant sizes/modalities; screenshots prove appearance only, not behavior, accessibility or animation quality. Measure motion where material; report untested environments honestly. For full visual work deliver state-to-presentation mapping, tokens, decisions, evidence and `assets/DESIGN_CARD.md` as appropriate. Create end-user `docs/` artifacts only on explicit authorized documentation task; otherwise report proposals in the response.

**Guards:** prefer existing stack and tokens; no unnecessary design system for one edit, no fabricated claims/metrics/guarantees, no automatic visual-design agent and no visual style bans based only on fashion. A delegated worker follows the existing A/E/R authority boundary.
