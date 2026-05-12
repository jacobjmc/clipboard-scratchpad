Status: needs-triage

# Verify resizable scratchpad windows end to end

## Parent

.scratch/resizable-scratchpad-windows/PRD.md

## What to build

Verify the complete resizable-window behavior across anchored popover, detached window, and pinned floating window modes. Use automated tests for pure frame/store behavior and manual `swift run` verification for native AppKit resizing.

## Acceptance criteria

- [ ] `swift build` succeeds.
- [ ] `swift test` succeeds.
- [ ] Anchored popover remains fixed-size.
- [ ] Detached windows resize natively and persist size/location to `windowFrame`.
- [ ] Pinned floating windows resize natively and persist size/location to `windowFrame`.
- [ ] Pinning after detached resize preserves the detached frame.
- [ ] Unpinning after pinned resize returns to the fixed anchored popover.
- [ ] Relaunch starts in anchored popover mode while retaining `windowFrame` for detached/pinned windows.
- [ ] Reset Window Size and Location restores default size and default below-menu-bar position.
- [ ] Editor receives extra height before the Clip Shelf grows.
- [ ] Clip Shelf remains capped and scrollable.
- [ ] Existing text editing, clip actions, clipboard monitoring, and paste-to-previous-app behavior are checked for regressions.

## Blocked by

- .scratch/resizable-scratchpad-windows/issues/01-rename-saved-frame-to-window-frame.md
- .scratch/resizable-scratchpad-windows/issues/02-make-pinned-floating-window-resizable.md
- .scratch/resizable-scratchpad-windows/issues/03-make-detached-window-frame-persistence-match-pinned-windows.md
- .scratch/resizable-scratchpad-windows/issues/04-update-reset-window-recovery-action.md
