Status: needs-triage

# Make detached window frame persistence match pinned windows

## Parent

.scratch/resizable-scratchpad-windows/PRD.md

## What to build

Make native detached windows follow the same shared frame rules as pinned windows. Detached windows should be resizable, moving or resizing them should update `windowFrame`, and pinning from a detached window should preserve the current detached frame.

## Acceptance criteria

- [ ] The anchored popover remains fixed-size.
- [ ] Native detached windows can be resized using native macOS resizing.
- [ ] Detached windows have a minimum size of 360 by 320 points.
- [ ] Detached windows have no app-defined maximum size.
- [ ] Moving or resizing a detached window immediately saves the shared `windowFrame`.
- [ ] Pinning from a detached window preserves that detached window's current size and location.
- [ ] Unpinning returns to the fixed-size anchored popover.
- [ ] Saved detached/pinned frames restore only when visible on an available display.
- [ ] Invalid saved frames fall back below the menu bar item.

## Blocked by

- .scratch/resizable-scratchpad-windows/issues/01-rename-saved-frame-to-window-frame.md
