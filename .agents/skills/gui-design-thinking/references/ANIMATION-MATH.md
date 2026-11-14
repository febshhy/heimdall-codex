# Animation mathematics: cheaper work with bounded error

**Load only for custom motion, high-volume geometry, curve sampling, or a measured animation bottleneck.** Companion to [RENDERING-AND-MOTION.md](RENDERING-AND-MOTION.md), not a new UI state model, physics engine, or requirement for ordinary transitions. Prefer the project's native animation scheduler, compositor and built-in physics/geometry facilities. The existing 16.6 ms **total frame** target at 60 Hz still applies (and is tighter at higher refresh rates).

**Decision rule:** prefer a direct solution over simulating intermediate steps when its assumptions hold; reuse invariant calculations; approximate only with an explicit accuracy tolerance. Profile before and after on representative hardware. A smaller operation count is not necessarily a faster rendered frame.

## Select the least expensive sufficient technique

| Situation | First candidate | Boundary / check |
| --- | --- | --- |
| Ordinary transition, opacity, transform | Native/CSS/Web Animations | Profile layout, paint, compositor and reduced motion before custom code. |
| Fixed start/end/duration | Direct `u = clamp(elapsed/duration,0,1)` and easing | Rebase when retargeting; no fixed percentage *per frame*. |
| Constant-acceleration motion | Evaluate closed-form position | Invalid across collisions, changing acceleration or constraints. |
| Following a changing target | Exact exponential damping per update | Target is treated as constant during the update; check interruption/retargeting. |
| Elastic tracking | Native spring, then a vetted analytic spring | Track velocity; verify stability, target jumps and stopping criteria. |
| Many 2D/3D geometric checks | Squared distance, dot tests, coarse filtering | Validate thresholds, precision and coordinate spaces. |
| Repeated Bézier evaluation | Cache polynomial coefficients; Horner evaluation | Constant `t` increments do **not** imply constant speed. |
| Many rotating objects | Cache transforms; use nlerp only where acceptable | Shortest-arc quaternion handling; speed need not be uniform. |
| Constrained physics/collision | Existing engine or bounded fixed-step solver | Prefer correctness, contacts and numerical stability over shortcuts. |

## Direct mathematics: skip unnecessary intermediate work

- **Constant acceleration, fixed initial conditions:** `x(t) = x0 + v0*t + 0.5*a*t*t`, `v(t) = v0 + a*t` in consistent units. Evaluate at display time instead of integrating every previous frame. If forces change or an event happens, establish a new starting state at that time.
- **Fixed-duration easing:** `x = a + (b-a)*ease(u)` where `u` is clamped normalized elapsed time. `smoothstep(u) = u*u*(3-2*u)` gives zero endpoint velocity; `smootherstep(u) = u*u*u*(u*(u*6-15)+10)` also gives zero endpoint acceleration. These are time curves, **not** physical spring simulations.
- **Exponential follow:** for a constant target over `dtSeconds`, `alpha = 1 - exp(-lambda*dtSeconds)` with `lambda > 0`. A more intuitive half-life `h > 0` uses `lambda = ln(2)/h`. For tiny `dt`, `alpha = -expm1(-lambda*dtSeconds)` reduces cancellation error where available. Update `x += (target-x)*alpha`. Share `alpha` among objects with the same rate and `dt`.
- **Critically damped spring** (constant target over each step; `omega > 0`): with `y=x-target`, `j=(v+omega*y)*dt` and `e=exp(-omega*dt)`, compute `xNext=target+(y+j)*e`, `vNext=(v-omega*j)*e`. This is a closed-form step for `y''+2*omega*y'+omega^2*y=0`, not a universal solution for nonlinear constraints. Retain velocity on target changes; re-evaluate after pauses using appropriate elapsed time and policy.

### Minimal reference implementation (custom motion only)

```ts
function dampHalfLife(x: number, target: number, halfLifeS: number, dtS: number): number {
  if (halfLifeS <= 0) return target; // explicit immediate-snap policy
  if (!Number.isFinite(dtS) || dtS < 0) throw new Error('invalid elapsed time');
  const alpha = -Math.expm1(-Math.LN2 * dtS / halfLifeS);
  return x + (target - x) * alpha;
}

function criticalSpringStep(x: number, v: number, target: number, omega: number, dtS: number) {
  if (!(omega > 0) || !Number.isFinite(dtS) || dtS < 0) throw new Error('invalid spring parameters');
  const y = x - target;
  const j = (v + omega * y) * dtS;
  const decay = Math.exp(-omega * dtS);
  return { x: target + (y + j) * decay, v: (v - omega * j) * decay };
}
```

Platform equivalents may offer stronger scheduling, accessibility integration and numerical behavior. Avoid creating an application-wide custom animation runtime for two small transitions.

## Geometry and linear-algebra shortcuts

- **Squared distance:** compare `dx*dx + dy*dy <= radius*radius`; no square root for membership queries. Use finite coordinates and a consistent unit/space; compare to a precise baseline near the boundary.
- **Cone/angle test:** with **unit** vectors, compare `dot(a,b) >= cos(maxAngle)` rather than evaluating `acos(dot(a,b))`. Precompute the threshold if the angle is fixed. Do not omit normalization unless lengths are otherwise accounted for.
- **Rotation:** compute an object's `sin(theta)`/`cos(theta)` or transform matrix once per changed transform and reuse it across vertices/children. Use the framework's transform stack before hand-coding matrix operations.
- **Cubic Bézier:** precompute vector coefficients `a,b,c,d` from control points, then evaluate `P(t) = ((a*t+b)*t+c)*t+d` (Horner). For approximately constant-speed motion, use a **validated** arc-length lookup table or suitable parameterization; uniform `t` is not uniform distance.
- **Quaternion:** platform `nlerp` can be cheaper than `slerp` for small orientation differences when nonuniform angular velocity is acceptable. Handle equivalent signs/shortest path and normalize the result; use `slerp` when accurate spherical motion matters.

## Avoid doing work at all

Prefer framework culling/virtualization and event-driven invalidation; do not animate static screens continuously. Cache fixed coefficients, shared elapsed-time factors and unchanged transforms. Keep per-frame allocations low in high-volume loops; measure whether contiguous arrays improve locality. Use spatial indices only after showing broad-phase checks dominate the frame and validating results against a simple reference. Approximation tables or hand-written trigonometric polynomials require proven benefit, a specified domain and bounded error: they are **not** default optimizations.

## Acceptance: correctness, performance and reversibility

1. Record the intended behavior, valid input domain, units, accepted position/angle/timing error, and source revision. For physics, also test constraint and collision behavior; a subpixel display tolerance is not an acceptable collision tolerance by default.
2. Compare optimized output with a simple trusted reference at boundaries, representative times, random seeded cases, variable `dt`, long pauses, retargeting and numeric extremes where relevant. Validate error accumulation and determinism if required.
3. Capture **actual** frame pacing (including p95/p99 hitches) and interaction quality under representative workloads and devices. Measure total render cost; do not mistake math microbenchmarks for frame-time wins. Revert the optimization when its gain is not material.
4. Keep source-derived audit evidence short: input/workload, tool, revision, error bound, before/after measurements, known limitations. Do not persist a second authoritative model or duplicate raw traces in the default agent context.

## Source references (checked 2026-11-09; recheck versions when material)

- Godot interpolation, including exact exponential smoothing: https://docs.godotengine.org/en/stable/tutorials/math/interpolation.html
- Rory Driscoll, frame-rate-independent damping: https://www.rorydriscoll.com/2016/03/07/frame-rate-independent-damping-using-lerp/
- Ryan Juckett, analytic damped springs: https://www.ryanjuckett.com/damped-springs/
- Gaffer on Games, fixed timestep and interpolation: https://gafferongames.com/post/fix_your_timestep/
- Unity Mathematics `nlerp` and tradeoff: https://docs.unity.com/en-us/engine/6000.5/script-reference/unity/mathematics/math/nlerp
- MDN frame scheduling: https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame
