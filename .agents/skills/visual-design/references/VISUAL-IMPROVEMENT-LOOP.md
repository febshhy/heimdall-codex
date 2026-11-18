# Visual improvement loop

Use this loop when changing or reviewing rendered UI. Visual Design owns
presentation. Use the app's existing states and interactions to reach the
rendered view. Route changes to behavior, navigation, or focus order through
GUI Design Thinking.

## Observe, improve, and verify

1. **Choose what to observe.** Identify the surface, a representative state,
   and any state or configuration likely to expose the issue. A spacing fix may
   need one state at two widths. A status layout change may need long content,
   empty and error states, or larger text. Use affected states and the actual
   requirements to decide coverage.
2. **Run the relevant build.** Discover the repository's launch and test
   commands. Prefer existing fixtures, test profiles and UI tools. Reach the
   state through normal interaction or a supported fixture, then wait for an
   observable ready state. Use test data and avoid unintended external writes.
3. **Inspect the render.** Use the live surface or examine a captured image.
   For an improvement, inspect the starting point when available. Describe the
   concrete problem and expected outcome, such as keeping a clipped label
   readable at the supported text size.
4. **Adjust and repeat.** Make the smallest useful change. Rebuild, reload or
   relaunch as needed, and revisit the same state under comparable conditions.
   Inspect the new render and nearby affected states. For review-only work,
   report findings and reproduction steps without editing.
5. **Stop on evidence.** Finish when the affected renders meet the task's
   criteria and relevant checks pass, or when a concrete environment or scope
   blocker prevents further verification. Record the affected states, runtime,
   revision, observed outcome and any remaining gap. Keep captures only when
   they help reproduce or explain a result.

## Choose the runtime for the interface

| Interface | Practical verification |
| --- | --- |
| Web, including mobile web | Open the real app in a supported browser. Use browser automation or inspect it directly. Exercise relevant widths and input modes. Use a real target browser/device when browser chrome, touch, or OS behavior matters. |
| Native or cross-platform mobile | Build and launch the actual app in an available iOS simulator, Android emulator, or test device. Use the project's UI test runner or device controls to reach the state. Check relevant orientation, text scaling, safe areas, and on-screen keyboard. Check hardware-dependent behavior on a real device when relevant. |
| Native desktop | Launch the actual application on a compatible OS and graphical session, such as Windows for WinUI or Delphi VCL, macOS for AppKit, or the supported Linux target for GTK or Lazarus. Use the framework's UI runner, OS automation, or direct interaction and window capture. Check relevant window sizes, display scaling, themes, native dialogs, and keyboard behavior. A suitable VM or remote test host can serve as the target when authorized. |
| Desktop or embedded webview | Launch the actual host app when window chrome, menus, dialogs, input, or host integration matters. Use a browser separately for web content when the same content can run there. |
| Other target surfaces | Use the project's supported runtime, simulator, or capture mechanism. Identify which target properties the available environment reproduces. |

If the target is unavailable, use the closest existing check, such as a
framework preview, component harness, build, or source inspection. Label its
coverage. A browser's phone viewport checks mobile web layout. It cannot verify
a native mobile or desktop build. A simulator result covers that simulator.
Report missing OS, SDK, display, device, or access as an explicit verification
gap. Keep the implementation in its native framework.

A screenshot verifies appearance in the captured state. Use interaction
checks for behavior, accessibility checks for semantics, and profiling for
material motion. For deeper runtime and motion guidance, see
[Rendering and Motion](../../gui-design-thinking/references/RENDERING-AND-MOTION.md).
