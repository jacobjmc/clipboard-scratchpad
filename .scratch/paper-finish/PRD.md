# Paper Finish PRD

Status: needs-triage

## Problem Statement

Clipboard Scratchpad currently uses a plain native editor surface. The user wants the editable note body to feel more like matte paper, similar to the attached reference, while still preserving the app's light mode, dark mode, plain-text editing behavior, and lightweight utility shape.

The user also wants control over the treatment, so the paper finish should be a Settings preference rather than an always-on visual change.

## Solution

Add a persisted `Paper Finish` setting that defaults on and applies a subtle matte paper texture only to the editable scratchpad editor surface. The treatment should follow the existing Appearance setting and system appearance:

- In light mode, the editor surface should use a warm off-white paper base with subtle fractal grain.
- In dark mode, the editor surface should use restrained warm charcoal paper with very low-contrast grain.
- When Paper Finish is off, the editor should return to the native text view background.

The texture should be generated procedurally in-process with deterministic fractal noise, cached as a fixed-size tiled bitmap per light/dark appearance, and drawn behind the existing `NSTextView`. It should not affect header/footer chrome, Settings, Clip Shelf, split dividers, text styling, selection behavior, cursor behavior, undo behavior, or paste/editing semantics.

## User Stories

1. As a Clipboard Scratchpad user, I want the note body to have a subtle paper-like matte finish, so that the scratchpad feels warmer and more tactile.
2. As a Clipboard Scratchpad user, I want the paper finish to apply only to the editable note body, so that the app controls remain native and uncluttered.
3. As a Clipboard Scratchpad user, I want the header to stay visually native, so that window controls and toolbar actions remain easy to scan.
4. As a Clipboard Scratchpad user, I want the footer to stay visually native, so that metadata remains clear and utility-like.
5. As a Clipboard Scratchpad user, I want the Clip Shelf to stay visually separate from the paper finish, so that captured clips still feel like a list rather than part of the note.
6. As a Clipboard Scratchpad user, I want the paper finish to apply when the Clip Shelf is open, so that the editor pane keeps its note identity in split view.
7. As a Clipboard Scratchpad user, I want the split divider to remain native, so that the drawer relationship stays clear.
8. As a Clipboard Scratchpad user, I want the paper finish to work in light mode, so that the note can resemble warm matte paper.
9. As a Clipboard Scratchpad user, I want the paper finish to work in dark mode, so that dark appearance does not become a beige or glaring surface.
10. As a Clipboard Scratchpad user, I want dark paper finish to be restrained, so that the texture does not read as visual noise.
11. As a Clipboard Scratchpad user, I want the paper finish to follow the existing System, Light, and Dark appearance setting, so that one appearance control governs the app's visual mode.
12. As a Clipboard Scratchpad user, I want a Settings toggle for Paper Finish, so that I can turn the texture off if I prefer a plain native editor.
13. As a Clipboard Scratchpad user, I want the Paper Finish setting to persist across launches, so that my visual preference sticks.
14. As a Clipboard Scratchpad user, I want Paper Finish to default on, so that the app gains the intended paper character immediately.
15. As a Clipboard Scratchpad user, I want turning Paper Finish off to restore the native editor background, so that off means normal rather than another custom theme.
16. As a Clipboard Scratchpad user, I want the setting to live near Appearance, so that visual preferences are grouped together.
17. As a Clipboard Scratchpad user, I want the setting labeled `Paper Finish`, so that it is clear and concise.
18. As a Clipboard Scratchpad user, I want the setting description to say `Add a subtle matte texture to the note.`, so that I understand the effect without extra explanation.
19. As a Clipboard Scratchpad user, I want the paper finish to avoid intensity controls, so that Settings stays compact.
20. As a Clipboard Scratchpad user, I want the paper finish to avoid texture style choices, so that the app does not become a theming system.
21. As a Clipboard Scratchpad user, I want my text font to stay the same, so that Paper Finish does not change writing behavior.
22. As a Clipboard Scratchpad user, I want selection behavior to stay native, so that editing remains predictable.
23. As a Clipboard Scratchpad user, I want the insertion point to stay native, so that text input still feels like a normal macOS editor.
24. As a Clipboard Scratchpad user, I want undo and redo behavior to stay unchanged, so that the visual treatment cannot break editing expectations.
25. As a Clipboard Scratchpad user, I want copy, paste, cut, and select-all behavior to stay unchanged, so that the scratchpad remains a reliable text utility.
26. As a Clipboard Scratchpad user, I want the texture to be stable across launches, so that the surface does not subtly change every time I open the app.
27. As a Clipboard Scratchpad user, I want the texture to avoid shimmer while resizing or scrolling, so that it feels like a surface rather than an animation.
28. As a Clipboard Scratchpad user, I want the texture to remain subtle on Retina displays, so that the grain does not become distracting.
29. As a Clipboard Scratchpad user, I want the feature to add no external dependencies, so that the app stays lightweight.
30. As a Clipboard Scratchpad user, I want the feature to remain local-first, so that no visual preference or generated asset leaves my Mac.

## Implementation Decisions

- Add a persisted Paper Finish boolean preference to the local store state.
- Default Paper Finish to on when older stored state does not include the field.
- Expose Paper Finish through the shared store so SwiftUI settings and the editor bridge can react to changes.
- Add a Settings row directly under Appearance and before Global Shortcut.
- Use the title `Paper Finish` and the description `Add a subtle matte texture to the note.`
- Use a native toggle control, not a custom control.
- Apply paper finish only to the editable scratchpad editor surface.
- Keep header, footer, Settings, Clip Shelf, and split divider outside the paper finish treatment.
- When the Clip Shelf is open, apply paper finish only to the editor pane above the shelf.
- When Paper Finish is off, use the native text view background.
- Do not change font, selection color, insertion point, line spacing, undo behavior, text input behavior, or paste behavior.
- Generate the paper texture in-process using deterministic fractal noise.
- Use a fixed seed so texture output is stable across launches.
- Cache one fixed pixel-size tiled bitmap for light paper and one for dark paper.
- Do not regenerate texture for window size, resize events, scroll events, or display scale.
- Use light paper colors for light appearance and warm charcoal paper colors for dark appearance.
- Keep dark paper grain lower contrast than light paper grain.
- Do not add bundled image assets for the paper texture.
- Do not add external packages or asset-pipeline changes.
- Prefer a small deep module for texture generation, with a simple interface that returns deterministic image or pixel data for a requested appearance.
- Keep AppKit drawing code thin: it should choose the cached texture and fill the editor background, not own the noise algorithm.
- Keep the setting and persistence shape explicit rather than introducing a general preferences framework.
- No ADR is needed because the decision is documented in context, easy to reverse, and does not introduce a hard architectural dependency.

## Testing Decisions

- Tests should focus on external behavior and stable contracts, not the exact visual implementation details.
- Add store-state tests for decoding older JSON without the Paper Finish field and defaulting to enabled.
- Add store-state tests for round-tripping Paper Finish when disabled and enabled.
- Add store-state tests to confirm Paper Finish persistence does not affect existing note text, clips, window frame, global shortcut, or appearance preference fields.
- Add focused tests for deterministic texture generation if the generator can expose testable pixel or sample data without requiring a live AppKit view.
- Good texture tests should assert determinism, light/dark distinction, and bounded contrast rather than exact full-image snapshots.
- Avoid brittle screenshot tests for the noise pattern unless a later visual testing workflow exists.
- Manually verify with `swift run` that the toggle appears under Appearance, defaults on, persists across relaunch, and restores the native editor background when off.
- Manually verify both Appearance Light and Appearance Dark modes.
- Manually verify System appearance if the host macOS appearance can be switched during testing.
- Manually verify the editor keeps normal typing, selection, undo, copy, paste, and scrolling behavior.
- Manually verify the paper finish appears only in the editor pane when the Clip Shelf is open.
- Existing prior art includes store-state persistence tests for appearance preference, global shortcut, and window frame.

## Out of Scope

- Intensity sliders.
- Multiple texture styles.
- User-supplied texture images.
- Randomizing the texture each launch.
- Animating or live-updating the noise.
- Applying paper texture to header, footer, Settings, Clip Shelf, split divider, menus, or popovers outside the editor.
- Changing editor font, typography, selection color, insertion point, line spacing, undo behavior, or input handling.
- Adding third-party dependencies.
- Adding bundled image assets.
- Adding a full preferences architecture.
- Adding screenshot-based visual regression infrastructure.

## Further Notes

The domain glossary defines `Paper finish`, `Paper Finish setting`, `Dark paper finish`, and `Paper finish scope`. Implementation should use that language consistently.

The feature should preserve Clipboard Scratchpad's lightweight, local-first, single-purpose product shape. The paper finish is an ambient editor-surface treatment, not a broader theme system.
