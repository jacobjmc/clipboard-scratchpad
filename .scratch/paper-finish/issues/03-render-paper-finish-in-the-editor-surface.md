# Render Paper Finish In The Editor Surface

Status: needs-triage

## Parent

.scratch/paper-finish/PRD.md

## What to build

Render the paper finish only behind the editable scratchpad editor surface, while preserving native chrome, Clip Shelf presentation, and plain text editing behavior. When Paper Finish is off, restore the native editor background.

## Acceptance criteria

- [ ] Paper Finish applies only to the editable note body.
- [ ] Header, footer, Settings, Clip Shelf, and split divider do not receive the paper finish.
- [ ] When the Clip Shelf is open, Paper Finish appears only in the editor pane above the shelf.
- [ ] Turning Paper Finish off restores the native text view background.
- [ ] Font, selection color, insertion point, line spacing, undo, copy, paste, cut, select-all, and normal text input behavior are unchanged.
- [ ] The editor drawing path is thin and does not own the fractal noise algorithm.

## Blocked by

- .scratch/paper-finish/issues/01-persist-paper-finish-setting.md
