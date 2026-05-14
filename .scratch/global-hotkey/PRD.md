# Global Hotkey PRD

Status: needs-triage

## Problem Statement

Clipboard Scratchpad currently requires the user to click the menu bar item to show the scratchpad surface. This is awkward when the user is typing in another app and wants to quickly reveal the scratchpad, bring an existing detached window forward, or hide the current scratchpad surface without reaching for the mouse.

The user needs a configurable global keyboard shortcut in Settings that can show or toggle Clipboard Scratchpad while the app is already running.

## Solution

Add a Settings feature that lets the user record a global keyboard shortcut. The shortcut starts unassigned. Once recorded and successfully registered, it persists locally and is registered again on app launch.

When triggered, the shortcut should use the same product language as the menu bar presentation model:

- If no scratchpad surface is visible, show the anchored popover.
- If the anchored popover is visible, hide it.
- If pinned mode is active, show or bring forward the pinned floating window, and hide it when it is already visible.
- If a detached window exists, bring that detached window forward rather than hiding it.
- If Clipboard Scratchpad is not already running, the shortcut does nothing because the app cannot receive it.

Settings should include a compact `Global Shortcut` row with the description `Show Clipboard Scratchpad while the app is open.` The value control should show `None`, the current shortcut, or `Press shortcut` while recording. Escape cancels recording. Delete or Backspace clears the shortcut. Error or status copy should appear only when needed, such as `Shortcut unavailable`.

## User Stories

1. As a Clipboard Scratchpad user, I want to assign a global shortcut, so that I can show the scratchpad without clicking the menu bar icon.
2. As a Clipboard Scratchpad user, I want the shortcut to work while another app is focused, so that I can summon the scratchpad from my current workflow.
3. As a Clipboard Scratchpad user, I want the shortcut description to say it works while the app is open, so that I understand it is not a system launcher.
4. As a Clipboard Scratchpad user, I want the shortcut to start as `None`, so that the app does not unexpectedly claim a global key combination.
5. As a Clipboard Scratchpad user, I want to record a shortcut in Settings, so that I can choose a combination that fits my habits.
6. As a Clipboard Scratchpad user, I want the recorder to show `Press shortcut`, so that I know it is waiting for input.
7. As a Clipboard Scratchpad user, I want Escape to cancel recording, so that I can back out without changing my shortcut.
8. As a Clipboard Scratchpad user, I want Delete or Backspace to clear the shortcut, so that I can return to the unassigned state.
9. As a Clipboard Scratchpad user, I want the current shortcut displayed in Settings, so that I can remember what is active.
10. As a Clipboard Scratchpad user, I want invalid shortcuts rejected, so that I do not accidentally create a disruptive global key.
11. As a Clipboard Scratchpad user, I want single-key shortcuts rejected, so that normal typing is not intercepted.
12. As a Clipboard Scratchpad user, I want Shift-only shortcuts rejected, so that normal capital letters are not intercepted.
13. As a Clipboard Scratchpad user, I want modifier-only shortcuts rejected, so that incomplete key presses are not treated as shortcuts.
14. As a Clipboard Scratchpad user, I want Escape, Return, and arrow-key shortcuts rejected, so that common navigation and cancellation keys keep working normally.
15. As a Clipboard Scratchpad user, I want common Command shortcuts rejected, so that the app does not capture copy, paste, save, quit, close, or similar basics.
16. As a Clipboard Scratchpad user, I want a shortcut with at least one non-Shift modifier and a normal key accepted, so that useful combinations like Command-Shift-Space or Control-Option-C can work.
17. As a Clipboard Scratchpad user, I want the app to detect registration failure, so that I know when another app already owns my chosen shortcut.
18. As a Clipboard Scratchpad user, I want the previous working shortcut to remain active if a new shortcut cannot register, so that failed changes do not break my setup.
19. As a Clipboard Scratchpad user, I want the app to save a shortcut only after successful registration, so that persisted state matches actual behavior.
20. As a Clipboard Scratchpad user, I want my chosen shortcut to persist across launches, so that I do not need to configure it repeatedly.
21. As a Clipboard Scratchpad user, I want launch-time registration failures to be visible in Settings, so that I can replace or clear an unavailable saved shortcut.
22. As a Clipboard Scratchpad user, I want the shortcut to show the anchored popover when no surface is visible, so that the default scratchpad is quick to access.
23. As a Clipboard Scratchpad user, I want the shortcut to hide the anchored popover when it is already visible, so that the shortcut behaves like a fast toggle.
24. As a Clipboard Scratchpad user, I want the shortcut to show the pinned floating window when pinned mode is active, so that it respects my pinned workflow.
25. As a Clipboard Scratchpad user, I want the shortcut to hide the pinned floating window when it is visible, so that pinned mode keeps matching menu bar visibility behavior.
26. As a Clipboard Scratchpad user, I want the shortcut to bring an existing detached window forward, so that I can find it if it is behind another app.
27. As a Clipboard Scratchpad user, I do not want the shortcut to hide a detached window, so that pressing it when searching for the window does not make the window disappear.
28. As a Clipboard Scratchpad user, I want the shortcut to avoid depending on Accessibility permission, so that it is separate from paste-to-previous-app permission.
29. As a Clipboard Scratchpad user, I want Accessibility status to remain focused on paste actions, so that Settings does not confuse shortcut setup with paste automation.
30. As a Clipboard Scratchpad user, I want the feature to stay local-first, so that shortcut settings remain on my Mac.

## Implementation Decisions

- Add a small shortcut model that represents a key code, modifier flags, display label, and persisted value.
- Add shortcut validation that requires at least one non-Shift modifier plus a normal key.
- Reject single-key shortcuts, Shift-only shortcuts, modifier-only shortcuts, Escape, Return, arrow keys, and common reserved Command shortcuts before attempting registration.
- Add a hotkey registration service as the AppKit or Carbon boundary. It should register, unregister, and report registration success or failure through a small interface.
- Keep Accessibility permission separate from hotkey registration. Hotkey registration should not require Accessibility permission.
- Add the chosen shortcut to the local JSON store state.
- Save a newly recorded shortcut only after registration succeeds.
- Keep the previous working shortcut active if registration of a new shortcut fails.
- Register the saved shortcut during app startup.
- If startup registration fails, keep the saved shortcut visible in Settings with an unavailable status so the user can clear or replace it.
- Extend Settings with a compact `Global Shortcut` row, current value control, recording mode, clear behavior, cancel behavior, and conditional status text.
- Route hotkey activation into the existing presentation controller rather than creating a separate show/hide path.
- Detached windows should be brought forward by hotkey activation and should not be hidden by hotkey activation.
- Pinned floating windows and anchored popovers should retain toggle-like hotkey behavior.
- The feature does not need an ADR because it is expected for a menu bar app, reversible, and captured sufficiently in domain context.

## Testing Decisions

- Tests should focus on external behavior and stable contracts rather than implementation details.
- Add unit tests for shortcut validation, including accepted modifier-plus-key shortcuts and rejected invalid/reserved shortcuts.
- Add unit tests for display formatting, so Settings shows predictable shortcut labels.
- Add store-state tests for shortcut encode/decode behavior and missing-shortcut defaults.
- Add presentation-state tests if the hotkey behavior is represented as a pure state transition.
- Registration against the real OS global hotkey system should be manually verified with `swift run`, because successful registration depends on the current desktop environment and conflicts with other running apps.
- Manual verification should cover recording a shortcut, triggering it from another app, conflict failure, clearing the shortcut, relaunch persistence, and the anchored, detached, and pinned presentation states.

## Out of Scope

- Launching Clipboard Scratchpad when the app is not running.
- Syncing shortcuts across devices.
- Multiple shortcuts.
- Per-mode shortcuts.
- User-editable shortcut profiles.
- Full keyboard-shortcut conflict discovery across all apps.
- Replacing Accessibility permission behavior for paste-to-previous-app.
- Adding third-party dependencies.

## Further Notes

This feature should preserve the app's current local-first, single-purpose shape. It should make the scratchpad faster to access without turning Settings into a large preferences system.
