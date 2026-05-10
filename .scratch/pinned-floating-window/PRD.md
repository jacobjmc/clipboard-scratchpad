Status: needs-triage

# PRD: Pinned Floating Window

## Problem Statement

Clipboard Scratchpad can currently be pinned so it stays open, but the current implementation is still built around a menu bar popover. That makes the pinned surface feel anchored and limited: the user cannot move it around the screen, and the app cannot restore the last useful pinned position.

When the user pins the scratchpad, they expect a Tot-like floating utility surface: visible above other work, movable, stable, and available wherever it is useful while collecting and drafting text.

## Solution

Pinning the scratchpad should promote it from the normal anchored menu bar popover into a real floating window or panel.

The unpinned scratchpad remains the default menu bar popover. The pinned scratchpad becomes a borderless utility panel that keeps the app's existing in-content header controls, can be moved by dragging the header area, stays above normal application windows, and remembers its last floating position across app launches.

Unpinning returns the scratchpad to normal popover behavior. The last floating position remains saved and is reused the next time the user pins. Pin state itself does not persist across launches.

## User Stories

1. As a Clipboard Scratchpad user, I want pinning to create a real floating scratchpad window, so that I can place it where I am working.
2. As a Clipboard Scratchpad user, I want the unpinned scratchpad to keep opening below the menu bar item, so that the app still behaves like a lightweight menu bar utility by default.
3. As a Clipboard Scratchpad user, I want the pinned scratchpad to stay open when I click outside it, so that it remains available while I work in another app.
4. As a Clipboard Scratchpad user, I want the pinned scratchpad to stay above normal windows, so that it does not disappear behind the app I am collecting from.
5. As a Clipboard Scratchpad user, I want to drag the pinned scratchpad by its header area, so that I can move it without needing visible instructions or extra controls.
6. As a Clipboard Scratchpad user, I want header buttons to remain clickable while the header is draggable, so that moving the window does not interfere with pin, settings, or other actions.
7. As a Clipboard Scratchpad user, I want the pinned scratchpad to keep the same compact visual design, so that it feels like the existing app rather than a different window.
8. As a Clipboard Scratchpad user, I want the pinned scratchpad to avoid a standard macOS title bar, so that controls are not duplicated.
9. As a Clipboard Scratchpad user, I want the pinned scratchpad to stay fixed size for now, so that the app remains predictable and focused.
10. As a Clipboard Scratchpad user, I want moving the pinned scratchpad to save its last position, so that I do not have to reposition it every time.
11. As a Clipboard Scratchpad user, I want the last pinned position to persist across launches, so that the app remembers where I like it.
12. As a Clipboard Scratchpad user, I want the app to start unpinned after launch, so that no floating window appears unexpectedly.
13. As a Clipboard Scratchpad user, I want pinning after launch to restore the last saved floating position, so that my previous layout is respected only when I ask for pinned mode.
14. As a Clipboard Scratchpad user, I want the app to avoid restoring an offscreen window position, so that monitor changes do not trap the scratchpad.
15. As a Clipboard Scratchpad user, I want invalid saved positions to fall back below the menu bar item, so that the window appears in the same default place as the normal popover.
16. As a Clipboard Scratchpad user, I want the menu bar item to hide or show the pinned floating window, so that the menu bar item remains the visibility toggle.
17. As a Clipboard Scratchpad user, I want clicking the menu bar item while pinned to keep pinned mode active, so that visibility and pin mode are separate concepts.
18. As a Clipboard Scratchpad user, I want closing the pinned floating window to hide it without unpinning, so that close behaves like another visibility action.
19. As a Clipboard Scratchpad user, I want only the pin control to change pinned or unpinned mode, so that the mode switch is explicit.
20. As a Clipboard Scratchpad user, I want unpinning to return to the anchored popover behavior, so that I can quickly go back to the lightweight menu bar mode.
21. As a Clipboard Scratchpad user, I want Escape to preserve normal text editing expectations, so that it does not unexpectedly hide the pinned scratchpad.
22. As a Clipboard Scratchpad user, I want all existing scratchpad and Clip Shelf actions to work in both popover and pinned window mode, so that pinning changes placement rather than content behavior.
23. As a Clipboard Scratchpad user, I want my scratchpad text and clips to remain local JSON data, so that this feature does not change the app's privacy model.
24. As a Clipboard Scratchpad user, I want no explanatory UI copy added for this feature, so that the app remains quiet and utility-focused.

## Implementation Decisions

- Keep two explicit presentation modes: unpinned anchored popover and pinned floating utility panel.
- Pin state remains runtime-only and does not persist across launches.
- Floating position persists across launches in the existing JSON store shape.
- The saved floating position should be optional to preserve compatibility with existing stored data.
- The saved floating position should be validated against available visible screen frames before use.
- If the saved floating position is not visible, the pinned window should fall back to the default position below the menu bar item.
- The pinned floating panel should use the same fixed content size as the existing popover.
- The pinned floating panel should be borderless or utility-styled and should keep the existing in-content header controls.
- The pinned floating panel should stay above normal application windows while visible.
- The menu bar item should toggle visibility for whichever presentation mode is active.
- Closing the pinned floating window should hide it without changing pinned mode.
- Unpinning should close or demote the floating panel and return the scratchpad to normal anchored popover behavior.
- Header dragging should move the pinned panel, excluding interactive controls.
- Existing scratchpad content, Clip Shelf behavior, clipboard monitoring, and paste-to-previous-app behavior should not change.
- A small deep module is appropriate for validating and resolving floating window placement because it packages screen/frame edge cases behind a stable interface.
- The main controller should continue owning presentation concerns. The store should own persisted state, not AppKit window lifecycle.

## Testing Decisions

- Good tests should cover externally observable behavior and pure placement rules, not AppKit implementation details.
- The best isolated test candidate is the floating window placement resolver: saved frame visibility, fallback behavior, and display-change edge cases can be tested without launching the app.
- Persistence compatibility should be verified by decoding existing store JSON without floating position data and by round-tripping store JSON with floating position data.
- Manual testing via `swift run` remains required because the repo has no unit test target yet and window behavior needs real macOS verification.
- Manual testing should confirm: unpinned popover opens below the menu bar item, pinning creates a movable floating panel, header dragging saves position, menu bar toggles visibility while pinned, close hides without unpinning, unpinning returns to popover mode, and relaunch starts unpinned while preserving the last floating position.

## Out of Scope

- Resizable pinned windows.
- Persisting pinned state across launches.
- Standard macOS title bar controls beyond what is required to support the chosen floating panel behavior.
- New explanatory UI copy or onboarding.
- Global hotkey support.
- Launch-at-login behavior.
- Changes to clipboard capture, Clip Shelf actions, paste-to-previous-app behavior, or note editing semantics.
- External dependencies.
- iOS or cross-platform support.

## Further Notes

The user explicitly wants behavior similar to Tot: a real floating utility surface, not a menu-bar popover forced to act like one.

This PRD follows the current domain model in `CONTEXT.md`: Clipboard Scratchpad stays local-first, fast, single-purpose, and quiet in the UI.
