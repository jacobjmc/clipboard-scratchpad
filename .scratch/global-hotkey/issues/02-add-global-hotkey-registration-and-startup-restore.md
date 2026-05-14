# Add global hotkey registration and startup restore

Status: needs-triage

## Parent

.scratch/global-hotkey/PRD.md

## What to build

Add the OS registration boundary for Clipboard Scratchpad's global hotkey. A successfully saved shortcut should register while the app is running, unregister when cleared or replaced, and register again on app launch. Registration failure should be reported without replacing the previous working shortcut.

## Acceptance criteria

- [ ] The app can register a valid saved shortcut as a global hotkey while Clipboard Scratchpad is running.
- [ ] The app can unregister the currently active global hotkey.
- [ ] Replacing a shortcut unregisters the previous registered shortcut only after the replacement can be registered successfully.
- [ ] If a new shortcut cannot be registered, the previous working shortcut remains active.
- [ ] A failed registration is exposed as an unavailable status for Settings.
- [ ] Saved shortcuts are registered during app startup.
- [ ] If launch-time registration fails, the saved shortcut remains visible with an unavailable status.
- [ ] Hotkey registration does not depend on Accessibility permission.
- [ ] Tests cover registration success, registration failure, previous-shortcut retention, clear/unregister behavior, and startup restore using a test double for the OS registration boundary.

## Blocked by

- .scratch/global-hotkey/issues/01-add-shortcut-model-validation-and-persistence.md
