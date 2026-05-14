# Verify Paper Finish End To End

Status: needs-triage

## Parent

.scratch/paper-finish/PRD.md

## What to build

Verify the complete Paper Finish experience across persistence, Settings, editor rendering, light and dark appearances, Clip Shelf layout, and normal editing behavior.

## Acceptance criteria

- [ ] `swift build` succeeds.
- [ ] Relevant automated tests pass.
- [ ] Manual `swift run` verification confirms the Paper Finish toggle appears under Appearance and defaults on.
- [ ] Manual verification confirms the toggle persists across relaunch.
- [ ] Manual verification confirms off state restores the native editor background.
- [ ] Manual verification confirms light paper and dark paper follow the app Appearance setting.
- [ ] Manual verification confirms the paper finish appears only in the editor pane when the Clip Shelf is open.
- [ ] Manual verification confirms typing, selection, undo, copy, paste, scrolling, and resizing remain normal.

## Blocked by

- .scratch/paper-finish/issues/02-add-paper-finish-toggle-to-settings.md
- .scratch/paper-finish/issues/04-generate-deterministic-light-and-dark-paper-textures.md
