# Add shortcut model, validation, and persistence

Status: needs-triage

## Parent

.scratch/global-hotkey/PRD.md

## What to build

Add the local shortcut representation needed for Clipboard Scratchpad's global hotkey. The app should be able to represent an unassigned shortcut, format an assigned shortcut for Settings, validate recorded input, reject obvious invalid or reserved shortcuts, and persist the chosen shortcut in local JSON state.

## Acceptance criteria

- [ ] The shortcut starts unassigned when no saved shortcut exists.
- [ ] A shortcut can represent a key code plus modifier flags.
- [ ] The shortcut has a stable display label for Settings.
- [ ] Valid shortcuts require at least one non-Shift modifier plus a normal key.
- [ ] Single-key shortcuts, Shift-only shortcuts, modifier-only shortcuts, Escape, Return, and arrow keys are rejected.
- [ ] Common reserved Command shortcuts for copy, paste, cut, select all, undo, save, quit, close, new, open, and print are rejected before registration.
- [ ] The shortcut encodes and decodes through the local JSON app state.
- [ ] Existing stored state without a shortcut still decodes successfully.
- [ ] Unit tests cover valid shortcuts, invalid shortcuts, reserved shortcuts, display formatting, and persistence.

## Blocked by

None - can start immediately
