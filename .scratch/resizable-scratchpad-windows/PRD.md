Status: needs-triage

# PRD: Resizable Scratchpad Windows

## Problem Statement

Clipboard Scratchpad now supports three presentation shapes: a fixed anchored popover, a native detached window created by dragging the popover away from the menu bar, and a pinned floating window created by clicking the pin control.

Detached and pinned windows currently behave like movable surfaces, but they do not let the user resize the scratchpad to match their working context. This is frustrating when the user wants a small note-like window for quick reference or a larger drafting surface for longer text.

The app also still uses frame terminology that is too narrow. The persisted frame is no longer only for pinned floating mode; it represents the shared size and position of the scratchpad window across detached and pinned modes.

## Solution

Detached and pinned scratchpad windows should be resizable using native macOS edge and corner resizing. The anchored menu bar popover should remain fixed-size and predictable.

Detached and pinned windows should share one persisted `windowFrame`, including both size and position. Moving or resizing either window mode should immediately update that shared frame. The saved frame should persist across launches and should restore only for detached or pinned windows, never for the anchored popover.

The reset action in the status item context menu should become `Reset Window Size and Location`, resetting the shared saved window frame to the default size and position below the menu bar item.

## User Stories

1. As a Clipboard Scratchpad user, I want to resize a detached window, so that I can make the scratchpad fit my current task.
2. As a Clipboard Scratchpad user, I want to resize a pinned floating window, so that I can keep a larger or smaller scratchpad visible while working.
3. As a Clipboard Scratchpad user, I want the anchored popover to stay fixed-size, so that clicking the menu bar item remains predictable.
4. As a Clipboard Scratchpad user, I want detached and pinned windows to use native macOS resizing, so that the interaction feels familiar.
5. As a Clipboard Scratchpad user, I do not want custom resize handles or resize instructions in the UI, so that the app stays quiet and utility-focused.
6. As a Clipboard Scratchpad user, I want a minimum window size, so that resizing cannot break the editor, footer, or controls.
7. As a Clipboard Scratchpad user, I want no app-defined maximum window size, so that I can make the scratchpad as large as my screen allows.
8. As a Clipboard Scratchpad user, I want resized detached windows to save their size immediately, so that the app remembers the window I shaped.
9. As a Clipboard Scratchpad user, I want resized pinned windows to save their size immediately, so that pinned mode remembers my working layout.
10. As a Clipboard Scratchpad user, I want detached and pinned windows to share one saved frame, so that moving or resizing in one mode carries naturally into the other.
11. As a Clipboard Scratchpad user, I want the saved window frame to persist across launches, so that I do not need to reshape the scratchpad repeatedly.
12. As a Clipboard Scratchpad user, I want the app to start as the fixed anchored popover after launch, so that no detached or pinned window appears unexpectedly.
13. As a Clipboard Scratchpad user, I want pinning after resizing a detached window to preserve that detached window size and location, so that pinning does not jump or reshape the window.
14. As a Clipboard Scratchpad user, I want unpinning to return to the fixed anchored popover, so that pinned-window size does not affect the menu bar popover.
15. As a Clipboard Scratchpad user, I want invalid saved frames to fall back below the menu bar item, so that monitor changes do not lose the scratchpad.
16. As a Clipboard Scratchpad user, I want the reset action to restore both size and location, so that I have a reliable recovery path after awkward resizing or dragging.
17. As a Clipboard Scratchpad user, I want the reset action to be available for detached and pinned windows, so that recovery is not tied only to pinned mode.
18. As a Clipboard Scratchpad user, I want the reset action label to avoid saying pinned, so that it matches both detached and pinned windows.
19. As a Clipboard Scratchpad user, I want extra resized height to go primarily to the editor, so that the main scratchpad remains the focus.
20. As a Clipboard Scratchpad user, I want the Clip Shelf to keep its capped height and scroll behavior, so that it does not crowd out the editor.
21. As a Clipboard Scratchpad user, I want scratchpad text editing behavior to remain normal while resizing, so that undo, selection, and typing still feel native.
22. As a Clipboard Scratchpad user, I want existing clip actions to keep working in resized windows, so that resizing only changes the available space.
23. As a Clipboard Scratchpad user, I want the persisted frame field to be named `windowFrame`, so that the stored data matches the product behavior.
24. As a Clipboard Scratchpad user, I accept that old `floatingFrame` data is not migrated, so that the code and persisted model stay simple.
25. As a Clipboard Scratchpad user, I want all frame data to stay local, so that resizing does not change the app's privacy model.

## Implementation Decisions

- The anchored popover remains fixed-size.
- Detached and pinned windows are resizable.
- Detached and pinned windows share one saved frame that includes size and position.
- The persisted frame field is renamed to `windowFrame`.
- The old `floatingFrame` key is not preserved, decoded, or migrated.
- The saved `windowFrame` persists across app launches.
- App launch still starts in anchored popover mode; saved window size is not applied to the anchored popover.
- Moving or resizing a detached window immediately updates `windowFrame`.
- Moving or resizing a pinned floating window immediately updates `windowFrame`.
- Pinning from a detached window should preserve the current detached window frame.
- Unpinning returns to fixed-size anchored popover mode.
- The reset menu item is renamed to `Reset Window Size and Location`.
- Reset restores the saved window frame to the default size and position below the menu bar item.
- Reset is available whenever a saved window frame exists or a detached or pinned window is open.
- Minimum detached or pinned window size is 360 by 320 points.
- No app-defined maximum size is set.
- Native macOS edge and corner resizing should be used. No custom resize handle or explanatory UI should be added.
- Extra vertical space should primarily expand the scratchpad editor.
- Clip Shelf height remains capped and scrollable.
- The presentation/window controller remains responsible for mode transitions, status item actions, native popover detach handling, and window delegate events.
- The store remains responsible for persisted scratchpad state, clips, and saved window frame.
- The frame placement resolver remains the deep module for default frame calculation and saved-frame visibility validation.

## Testing Decisions

- Tests should verify external behavior through stable public interfaces and pure frame rules, not private AppKit implementation details.
- Store-state tests should verify `windowFrame` encode/decode behavior and confirm `floatingFrame` is not preserved as a supported key.
- Frame resolver tests should cover default below-menu-bar frame, minimum-size-aware saved frame behavior, and offscreen fallback behavior.
- Presentation-state tests should continue to cover pinned versus unpinned mode semantics, including that detached mode does not turn on pinned mode.
- Window/frame update behavior should be manually verified with `swift run`, because native resizing and popover detachment require real AppKit behavior.
- Manual verification should include resizing a detached window, resizing a pinned window, pinning after detached resize, unpinning after pinned resize, relaunch restore behavior, reset menu behavior, and anchored popover fixed-size behavior.
- Manual verification should also check that editor layout receives extra height first and that Clip Shelf remains capped and scrollable.

## Out of Scope

- Resizing the anchored popover.
- Persisting pin state across launches.
- Migrating or preserving old `floatingFrame` data.
- Custom resize handles.
- In-app instructional copy about resizing.
- Changing detached-window close behavior.
- Changing clipboard capture behavior.
- Changing Clip Shelf actions or paste-to-previous-app behavior.
- Cloud sync, accounts, external dependencies, or non-local persistence.

## Further Notes

The canonical product terms are:

- Anchored popover: the fixed menu bar popover.
- Detached window: the native window created by dragging the popover away from the menu bar. This does not turn on pinned mode.
- Pinned floating window: the floating utility window created by the pin control.

The key product rule is that detached and pinned windows are both scratchpad windows and should therefore share one saved `windowFrame`.
