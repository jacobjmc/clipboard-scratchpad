# Wire hotkey activation into scratchpad presentation

Status: needs-triage

## Parent

.scratch/global-hotkey/PRD.md

## What to build

Wire the registered global hotkey action into the existing scratchpad presentation controller. The hotkey should use the same product semantics as the menu bar surface: show the anchored popover when nothing is visible, toggle the anchored popover when visible, toggle the pinned floating window in pinned mode, and bring detached windows forward instead of hiding them.

## Acceptance criteria

- [ ] Triggering the hotkey while no scratchpad surface is visible shows the anchored popover.
- [ ] Triggering the hotkey while the anchored popover is visible hides it.
- [ ] Triggering the hotkey while pinned mode is active shows or brings forward the pinned floating window.
- [ ] Triggering the hotkey while the pinned floating window is visible hides it while keeping pinned mode active.
- [ ] Triggering the hotkey while a detached window exists brings that detached window forward.
- [ ] Triggering the hotkey while a detached window exists does not hide the detached window.
- [ ] The hotkey path does not duplicate presentation logic unnecessarily.
- [ ] Presentation-state tests cover the hotkey behavior where pure state can represent it.

## Blocked by

- .scratch/global-hotkey/issues/02-add-global-hotkey-registration-and-startup-restore.md
