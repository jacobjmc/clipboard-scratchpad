Status: needs-triage

# Persist and restore pinned window position

## Parent

.scratch/pinned-floating-window/PRD.md

## What to build

Persist the last pinned floating window position in the existing local JSON store and restore it when the user pins again. Pin state itself should remain runtime-only. If the saved position is no longer visible on an available display, fall back to the default position below the menu bar item.

## Acceptance criteria

- [ ] Moving the pinned floating panel saves its last position.
- [ ] The saved floating position persists across app launches.
- [ ] The app starts in unpinned menu bar popover mode after launch.
- [ ] Pinning after launch restores the last saved floating position when it is still visible on an available display.
- [ ] If the saved position is offscreen or invalid, pinning falls back to the default position below the menu bar item.
- [ ] Existing store JSON without floating position data still loads successfully.
- [ ] Scratchpad text and clips continue to persist in the existing local JSON store.

## Blocked by

- .scratch/pinned-floating-window/issues/03-support-header-dragging-for-pinned-panel.md
