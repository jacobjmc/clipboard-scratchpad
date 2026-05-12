Status: needs-triage

# Update reset window recovery action

## Parent

.scratch/resizable-scratchpad-windows/PRD.md

## What to build

Update the status-item context menu recovery action so it applies to the shared detached/pinned window frame instead of pinned location only. The action should reset both size and location.

## Acceptance criteria

- [ ] The menu item is labeled `Reset Window Size and Location`.
- [ ] The reset action is available whenever a saved `windowFrame` exists or a detached or pinned window is currently open.
- [ ] Reset clears the saved `windowFrame`.
- [ ] Reset moves any open detached or pinned window to the default position below the menu bar item.
- [ ] Reset restores the default window size.
- [ ] Left-clicking the menu bar item still toggles visibility normally.

## Blocked by

- .scratch/resizable-scratchpad-windows/issues/01-rename-saved-frame-to-window-frame.md
- .scratch/resizable-scratchpad-windows/issues/02-make-pinned-floating-window-resizable.md
- .scratch/resizable-scratchpad-windows/issues/03-make-detached-window-frame-persistence-match-pinned-windows.md
