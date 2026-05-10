Status: needs-triage

# Verify pinned window behavior end to end

## Parent

.scratch/pinned-floating-window/PRD.md

## What to build

Verify the pinned floating window behavior across the full app. Add feasible isolated tests for placement and persistence compatibility if a test target is introduced or already available, and manually verify the macOS window behavior with `swift run`.

## Acceptance criteria

- [ ] `swift build` succeeds.
- [ ] The unpinned scratchpad opens below the menu bar item.
- [ ] Pinning creates a fixed-size movable floating panel.
- [ ] Header dragging moves the pinned panel and keeps header controls interactive.
- [ ] Menu bar clicks hide and show the pinned panel without unpinning.
- [ ] Closing the pinned panel hides it without unpinning.
- [ ] Outside clicks and Escape do not dismiss the pinned panel.
- [ ] Unpinning returns to anchored popover behavior.
- [ ] Relaunch starts unpinned while preserving the last floating position for the next pinned session.
- [ ] Invalid saved positions fall back below the menu bar item.
- [ ] Existing scratchpad, Clip Shelf, clipboard monitoring, and paste-to-previous-app behavior are checked for regressions.

## Blocked by

- .scratch/pinned-floating-window/issues/01-add-pinned-floating-panel-mode.md
- .scratch/pinned-floating-window/issues/02-make-pinned-window-visibility-controls-explicit.md
- .scratch/pinned-floating-window/issues/03-support-header-dragging-for-pinned-panel.md
- .scratch/pinned-floating-window/issues/04-persist-and-restore-pinned-window-position.md
