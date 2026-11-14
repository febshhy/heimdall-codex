# Render, inspect, correct: UI verification and motion

**Scope.** Conditional companion to canonical `$gui-design-thinking`. Use for implemented or reviewed UI on web, mobile and genuine native desktop, including Pascal/Lazarus/Delphi, SwiftUI and WinUI. `$gui-design-thinking` owns states/events, `$visual-design` presentation, `$testing` verification. No change to canonical GUI/domain models, Graph Protocol A/E/R or factory schemas.

**Principle.** Render a real UI state, inspect observed output and behavior, correct the defect, and recheck that state. Generate only evidence that materially affects a decision and tie it to current source and environment. Do not maintain a separate, stale screenshot inventory by default.

## 1. Browser UI building loop (when a browser is available)

1. **Select states.** Read the approved behavior and UI state graph. Prioritize affected happy, loading/empty, error/denied, focus, interaction-result, responsive and reduced-motion states by impact, significance and detectability; avoid exhaustive screenshots.
2. **Run the actual application.** Discover its real start and browser-test commands. Prefer installed browser/test tools; Playwright is an option, not a mandatory dependency. Do not invent a URL or successful run.
3. **Exercise a representative path.** Navigate, interact with controls and use real or deterministic fixture data. Wait for a specific UI readiness condition rather than arbitrary sleeps. Assert important state and semantics before capturing.
4. **Capture a rendered state.** Inspect viewport/component screenshots with known browser/version, OS, viewport, device scale, font environment, locale, color mode and reduced-motion setting where relevant. Compare to approved requirements or a reviewed reference. Do not assume a generated baseline is correct.
5. **Diagnose and iterate.** Inspect clipping/overflow, content length, focus, readability, responsive layout, voids, animation and unexpected layout changes. Fix, rerender and rerun affected assertions. Record unresolved conditions explicitly.
6. **Profile movement separately.** Static screenshots are not evidence for animation smoothness, frame pacing, input latency or accessibility. For material animation/scrolling, record a browser performance timeline with frame timing or dropped/late frames, and verify interaction/focus/accessibility independently.
7. **Report compact evidence.** Give surface, relevant states/viewport, environment, source revision, command, observed result and unresolved risks. Link screenshots/traces instead of putting everything in the model's context. If no browser actually ran, say **not visually verified**.

**Playwright Test example, only when the project uses it:**

```ts
import { test, expect } from '@playwright/test';

test('reports empty state', async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.goto('/reports'); // requires project baseURL and deterministic fixture
  await expect(page.getByRole('heading', { name: 'Reports' })).toBeVisible();
  await expect(page.getByText('No reports')).toBeVisible();
  await expect(page).toHaveScreenshot('reports-empty.png', {
    animations: 'disabled', // static snapshot, NOT animation test
  });
});
```

This is illustrative and must be adapted to approved content/fixtures. Screenshot output varies with browser, OS, fonts and environment; review snapshot baseline changes and keep the comparison environment consistent. Mask only truly irrelevant volatile content. Automated images neither verify state-transition contracts nor prove smoothness. Chrome DevTools frame records can link screenshot frames to individual frame timings; Playwright screenshots alone cannot.

## 2. Universal frame budget and measurement

- **Baseline target for smooth interactive/animated UI: 16.6 ms per frame at 60 Hz**, corresponding to the whole display-frame interval `1000/60 ≈ 16.67 ms`. Apply as a design/performance target across web, mobile and real native UI, but do not claim that all display frames are driven by application code, or that all displays run at 60 Hz.
- **Adapt to actual refresh:** 90 Hz ≈ 11.11 ms, 120 Hz ≈ 8.33 ms, 144 Hz ≈ 6.94 ms. Variable refresh, OS power/thermal policy, idle/background, and accessibility can alter cadence. Prefer platform frame scheduling; never assume fixed `dt = 16.6 ms`.
- **Leave headroom:** the frame pipeline includes application work, style/layout/drawing, compositing, GPU and platform overhead. For 60 Hz browser animation, ~10 ms for application work is a useful starting point, not a universal guarantee; the full frame must still meet 16.6 ms.
- **Measure actual outcomes:** frame intervals, missed/late frames, p95/p99 or hitches, UI-thread blocking and input responsiveness on representative devices. Record tested hardware, refresh rate, workload, revision, mode and tool. A screenshot, compile, or an isolated CPU timer is not a frame-time result.
- **Do not force idle rendering:** static/event-driven interfaces should not run a 60 Hz loop when no scene needs updates. A deliberate lower target for constrained devices must be explicit and justified; do not silently weaken a specified 60 Hz requirement.

## 3. Animation mathematics and game-development lessons

- **UI state first:** animation presents an existing valid state transition; it must not invent hidden GUI or business state. In-flight animation is platform-owned `P` in canonical GUI Design Thinking. Disabling motion must not lose information, action reachability or focus.
- **Purpose and interruption:** motion communicates feedback, causality, continuity or spatial relationships. Prefer brief, interruptible transitions. Define cancellation, reversal, retargeting, and background/resume behavior when relevant. Decorative perpetual motion costs CPU, GPU and battery.
- **Time-based tween:** `u = clamp((now - start) / duration, 0, 1)`; `x = a + (b - a) * ease(u)`. For a smooth velocity endpoint, `ease(u) = 3u² − 2u³` (smoothstep) is a useful option, not a universal standard. Do not move a fixed number of pixels or percentage **per frame**.
- **Frame-independent exponential smoothing:** `alpha = 1 − exp(−lambda * dtSeconds)`; `x += (target − x) * alpha`, with `lambda > 0`. `alpha = speed * dt` is not an exact frame-rate-independent exponential filter and may overshoot at large `dt`.
- **Spring dynamics:** model `x'' + 2ζωx' + ω²(x − target) = 0`, with damping ratio `ζ` and natural angular frequency `ω`. Critically damped (`ζ = 1`) is a non-oscillating default when overshoot is undesirable. Preserve current velocity on retarget. Prefer a vetted analytical solution or bounded stable integrator; test pause, large `dt`, rapid reversals and completion thresholds.
- **Physics-style simulations:** where needed, use bounded fixed timestep updates and interpolated presentation. Cap catch-up steps to avoid the *spiral of death*. A general UI does not need a custom physics/render loop just for routine transitions.
- **Use platform strengths:** on web prefer browser CSS/Web Animations and compositor-friendly properties such as `transform` and `opacity` where appropriate, and profile layout/paint. SwiftUI: use built-in animation and keep view updates cheap; use `TimelineView`/display links only for genuinely time-dependent custom content. WinUI: prefer independent/compositor animations over per-frame UI thread handlers. Pascal VCL/LCL: use normal paint/invalidation, double buffering where supported; `TTimer.Interval = 16` is not vsync or a guaranteed budget. Do not sleep, perform I/O or heavy calculation on the UI thread.
- **Reduced motion:** honor platform preferences, including CSS `prefers-reduced-motion`. Remove/replace nonessential movement and parallax while keeping meaning and focus. Test the alternative; avoid flashing and motion that can trigger vestibular discomfort.

**Conditional deeper mathematics:** For custom high-volume motion or a measured bottleneck, consult [ANIMATION-MATH.md](ANIMATION-MATH.md) for closed-form kinematics, analytic damping/springs, polynomial easing, precomputation, geometry tests and error-bounded approximations. Do **not** load it for routine platform-managed transitions.

## 4. Resolution-independent vector motion (when animated artwork is in scope)

**Contract:** author and deliver motion artwork as a **compact, reusable** vector/parametric scene (shapes, paths, transforms and time-based properties) in logical coordinates. Do not author or ship pre-rendered pixel frames, sprite sheets, animated GIF/APNG, video substitutes, raster layers hidden inside SVG/Lottie/dotLottie, **SVG files per frame, or frame-by-frame copies of vector geometry**. A vector file is not automatically lightweight. If the user explicitly requires a conflicting medium, report it and obtain a scoped exception; never silently convert to raster frames or oversized per-frame vectors. This applies to animated UI artwork, not ordinary photographs, user video, requested pixel art, or diagnostic screenshots.

**Precision:** final hardware presentation necessarily rasterizes or samples vectors to pixels. "Never render to pixel" therefore means **do not bake UI animation into fixed-resolution raster source/delivery assets**. It does not prohibit standard compositor/GPU rendering or screenshots/traces captured solely for verification. Native text and controls may be rasterized by the platform without becoming raster animation assets.

- **Space and time:** define path/scene coordinates relative to a logical viewport or normalized geometry. Scale to different containers, pixel densities, zoom levels and orientations without resizing baked frames; preserve intentional aspect ratio and clipping. Use elapsed time and platform scheduling, not a fixed number of output pixels or frames per tick. Check stroke behavior, safe bounds and text layout where applicable.
- **Compact scene:** represent repeated shapes once and reuse instances/groups where supported. Animate position, rotation, scale, opacity, color, strokes or other parameters over time. Prefer a small set of meaningful keyframes or analytic transitions, interpolated at runtime. Avoid duplicate per-frame SVGs, auto-traced outlines, excessive vertices/layers, per-frame path data, and path morphs unless a simpler transform cannot express the required motion. A scene with thousands of unique paths is not acceptable merely because it is vector.
- **Minimal implementation:** animate existing native/vector UI primitives with the project's current toolset when a simple transition suffices. Do not add a Lottie player or a general animation engine for opacity, position or small affordance changes. Keep motion presentation separate from the GUI's canonical `S` and event/effect contracts; player progress and cancellation live in platform `P`.
- **Web option:** for simple motion, animate existing DOM/CSS or a compact, reusable SVG scene (`viewBox`, shared definitions/groups and CSS/Web Animations). For richer authored motion, consider **shape-only, compact** Lottie if the player and its payload are justified. Lottie permits PNG/JPEG assets, dense shape geometry and excessive keyframes; shape-only is necessary but not sufficient. Inspect packaged dotLottie archives too. SVG/Canvas/HTML renderer choice is web-specific and does not define the cross-platform contract.
- **Other platforms:** use the supported native path/scene/vector animation API, or a validated vector-capable Lottie runtime where it fits the product. Same intent, scaling, timing, accessibility, interruption and static/reduced-motion outcomes matter; identical serialized assets and byte-for-byte rendering across targets are **not** required. A missing player is a reason to choose a native implementation or static vector fallback, not to ship a raster animation by default.
- **Reduced motion and fallback:** honor each platform's preference, including the web's `prefers-reduced-motion`. Remove nonessential movement; present the same meaning and reachable actions with a stable vector frame or native static UI. No inaccessible information may depend only on animation. Define startup, completion, interruption, retarget, disable, resize and background/resume behavior for material motion; avoid persistent decorative loops by default.
- **Complexity and budget:** before accepting authored motion, inspect the delivered compressed/uncompressed asset size, unique paths/vertices, groups/layers, and animated properties/keyframes; flag duplicated geometry and per-frame path samples. Choose limits from the product's actual download, memory, startup and device-performance budgets rather than inventing universal numeric caps. Compare against a simpler native transition or static vector when useful. Compression alone does not fix parsing or rendering costs.
- **Validation:** inspect shipped assets for raster layers, bitmap data URIs, external pixel resources, SVG-per-frame sequences, duplicated paths and excessive path/keyframe/layer counts; a `.svg`, `.json` or `.lottie` suffix is not evidence of efficiency. Verify shape/player feature support on actual target runtimes and check geometry at different viewport sizes and densities, including resize, non-square scaling and clipping. Test reduced motion and interruption. For material motion measure startup, memory, frame pacing and input responsiveness on representative devices. Screenshots can verify appearance but cannot prove compactness, vector provenance, scaling, or cross-platform playback.

References: [SVG viewBox](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Attribute/viewBox), [SVG reusable elements](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/use), [Lottie authoring guidance](https://github.com/airbnb/lottie/blob/master/after-effects.md), [Lottie image assets](https://lottie.github.io/lottie-spec/dev/specs/assets/), [Lottie web renderers](https://github.com/airbnb/lottie-web/wiki/loadAnimation-options), [dotLottie format](https://www.dotlottie.io/spec/), [W3C animation from interactions](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions).

## 5. 3D UI: PBR or NPR (only when genuine 3D is needed)

**Rendering intent:** For a 3D interface or interactive 3D illustration, explicitly choose **PBR** (physically based rendering: materials respond plausibly to lights and viewing angles), **NPR** (non-photorealistic rendering: deliberately illustrative/toon/diagrammatic shading), or a justified hybrid. The choice serves the task: PBR for product/material fidelity; NPR for clarity, expressive style or simplified depth cues. Unlit/flat shading is a valid minimal NPR-style option when lighting is unnecessary. Do not add 3D for visual novelty, assume PBR means expensive texture stacks, or assume NPR means inherently cheaper rendering. A stylized scene may use PBR materials selectively; the categories are not mutually exclusive.

- **Separate concerns:** Scene geometry, transforms and material/shading parameters are resolution-independent representations; the GPU/display still rasterizes frames. The 2D vector-motion contract forbids baked animation frames; it does **not** require 3D meshes to be SVG or Lottie. Do not export 3D motion as PNG/video/sprite sequences or one full geometry snapshot per frame as a shortcut. Animate mesh transforms, bones or bounded parameters over elapsed time using native runtime facilities.
- **PBR:** Prefer the supported, simplest material model appropriate to the product. When exchanging assets, glTF 2.0 metallic-roughness is one portable option with base color, metalness and roughness; advanced effects are conditional. Test representative lighting, viewing angles and color management. PBR material data does not guarantee identical output across renderers, tone mapping, environments or devices.
- **NPR:** Use a clear, intentionally stylized model such as flat/unlit, toon/cel bands, contours or limited palette. Preserve shape, hierarchy, selection, text and affordances under the chosen lighting/background. An unlit material is a portable option where supported; custom outline and toon shader behavior often needs target-specific implementation and verification.
- **Small sufficient scene:** Reuse meshes/materials and instances; cap geometry detail, draw calls, shader passes, texture count/size, memory and asset download according to measured target budgets. Prefer material constants, lighting and procedural effects when they meet requirements. Raster texture maps may be justified for real 3D surface detail but are **not** animation frames; optimize and document them instead of banning useful PBR textures. No mandatory 3D engine, file format, shader language or texture dependency.
- **Usability and graceful fallback:** 3D must not encode critical actions or information solely in color, material, motion, lighting or depth. Keep keyboard/touch/pointer selection, focus, screen-reader equivalents, reduced-motion settings, static/2D fallback, device-loss/context-loss recovery and resource cleanup consistent with GUI `S` and platform `P`. Defer rendering when offscreen or idle; handle resize, scale and input-to-scene mapping.
- **Verification:** On actual target runtimes inspect material/shading results across relevant lighting, zoom, density, contrast and input modes. Test depth/occlusion of important UI, hit targets, state transitions, reduced-motion/fallback and degraded/no-GPU behavior as applicable. Profile frame timing, shader compilation/startup, GPU/CPU cost, memory and draw calls on representative hardware when 3D is consequential. Static screenshots cannot establish material portability, runtime performance, accessibility or interaction correctness.

Sources: [Khronos glTF PBR](https://www.khronos.org/gltf/pbr), [glTF 2.0 material specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html#materials), [Khronos KHR_materials_unlit](https://github.com/KhronosGroup/glTF/blob/main/extensions/2.0/Khronos/KHR_materials_unlit/README.md), [NPR definition](https://doi.org/10.1007/978-3-642-27851-8_169-3), [Three.js toon shading example](https://threejs.org/manual/pages/materials.html). These illustrate rendering principles, not mandated runtimes.

## 6. Verification proportional to risk

- **Static presentation edit:** inspect the affected rendered state and applicable viewport; no motion benchmark or snapshot inventory needed.
- **Functional UI change:** exercise affected states and transitions; use visual captures for appearance and actual assertions for behavior. Review focus, keyboard, accessibility and reduced motion when relevant.
- **Material movement/high-frequency scrolling/canvas:** measure jank and frame pacing against **16.6 ms at 60 Hz** and the tighter actual refresh interval; test interruption and slower hardware.
- **High-impact change:** retain only necessary reproducible checks and independent outcome evidence. A screenshot or attractive design is never sufficient proof of correctness.
- **Native UI:** use platform-native screenshot and profiling tools, and record what ran. Browser screenshots are not mandatory for a native app. If tooling is unavailable, report that portion **not verified**.

## Primary sources (checked 2026-11-09; revalidate when material)

- Playwright visual comparisons and environments: https://playwright.dev/docs/test-snapshots
- Playwright screenshot assertions: https://playwright.dev/docs/api/class-pageassertions
- Chrome DevTools frame screenshots and timing: https://developer.chrome.com/docs/devtools/performance/reference
- web.dev browser frame budget/headroom: https://web.dev/articles/rendering-performance
- MDN browser frame scheduler: https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame
- Android frame deadlines: https://developer.android.com/topic/performance/vitals/render
- Apple variable refresh rates: https://developer.apple.com/documentation/quartzcore/optimizing-iphone-and-ipad-apps-to-support-promotion-displays
- SwiftUI performance: https://developer.apple.com/documentation/Xcode/understanding-and-improving-swiftui-performance
- WinUI compositor animation: https://learn.microsoft.com/en-us/windows/apps/develop/performance/optimize-animations-and-media
- Lazarus paint invalidation: https://lazarus-ccr.sourceforge.io/docs/lcl/controls/tcontrol.invalidate.html
- Godot time-based exponential interpolation: https://docs.godotengine.org/en/stable/tutorials/math/interpolation.html
- Gaffer on Games timestep tradeoffs: https://gafferongames.com/post/fix_your_timestep/
- W3C WCAG animation from interaction: https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions
