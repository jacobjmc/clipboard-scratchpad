Status: needs-triage

# Support header dragging for the pinned panel

## Parent

.scratch/pinned-floating-window/PRD.md

## What to build

Allow the user to move the pinned floating panel by dragging the top header area. Interactive header controls must remain clickable and should not accidentally start window dragging.

## Acceptance criteria

- [ ] Dragging the non-interactive header area moves the pinned floating panel around the screen.
- [ ] Pin, settings, and other header controls remain clickable while pinned.
- [ ] Dragging behavior is only active for the pinned floating panel and does not change normal popover behavior.
- [ ] Moving the panel does not resize it.
- [ ] No visible drag handle or explanatory UI copy is added.

## Blocked by

- .scratch/pinned-floating-window/issues/01-add-pinned-floating-panel-mode.md
