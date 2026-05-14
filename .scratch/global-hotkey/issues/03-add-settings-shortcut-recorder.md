# Add Settings shortcut recorder

Status: needs-triage

## Parent

.scratch/global-hotkey/PRD.md

## What to build

Add a compact global shortcut recorder to Settings. The row should explain what the shortcut does, show the current shortcut or `None`, enter recording mode when clicked, and handle cancel, clear, invalid input, and unavailable registration states without adding broad preferences UI.

## Acceptance criteria

- [ ] Settings includes a row labeled `Global Shortcut`.
- [ ] The row description is `Show Clipboard Scratchpad while the app is open.`
- [ ] The value control shows `None` when no shortcut is assigned.
- [ ] The value control shows the current shortcut label when one is assigned.
- [ ] Clicking the value control enters recording mode and shows `Press shortcut`.
- [ ] Pressing Escape cancels recording without changing the active shortcut.
- [ ] Pressing Delete or Backspace clears the shortcut and unregisters it.
- [ ] Invalid or reserved shortcuts are rejected without saving.
- [ ] Registration failure shows conditional status copy such as `Shortcut unavailable`.
- [ ] Accessibility permission remains visually separate from shortcut setup.
- [ ] Tests cover recorder state transitions where practical, and manual verification covers actual key capture in Settings.

## Blocked by

- .scratch/global-hotkey/issues/01-add-shortcut-model-validation-and-persistence.md
- .scratch/global-hotkey/issues/02-add-global-hotkey-registration-and-startup-restore.md
