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
          → Render affected states → inspect → adjust → rerender
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

**Verification:** inspect actual rendering for affected states, sizes, and
content. For visual improvements and reviews, use the
[visual improvement loop](references/VISUAL-IMPROVEMENT-LOOP.md) with the
target's available runtime. A spacing edit needs a focused layout check.
Check keyboard and focus,
assistive-technology meaning, contrast, noncolor status, zoom/reflow, touch,
and reduced motion where the change can affect them. Apply applicable web or
native accessibility standards for the changed scope. Use swap/squint/real-content
checks in `references/SLOP.md` when helpful. Screenshots verify appearance.
Use interaction checks and measurements for material behavior and motion.
Report untested environments. For full visual work deliver state mappings,
tokens, decisions, and evidence as appropriate. Write end-user `docs/` only
for an explicitly authorized documentation task.

**Guards:** prefer existing stack and tokens; no unnecessary design system for one edit, no fabricated claims/metrics/guarantees, no automatic visual-design agent and no visual style bans based only on fashion. A delegated worker follows the existing A/E/R authority boundary.
