Status: needs-triage

# Make pinned floating window resizable

## Parent

.scratch/resizable-scratchpad-windows/PRD.md

## What to build

Make the pinned floating window natively resizable while preserving the existing borderless utility-panel feel. Resizing or moving the pinned window should update the shared `windowFrame`, and resized space should primarily benefit the editor.

## Acceptance criteria

- [ ] The pinned floating window can be resized using native macOS edge and corner resizing.
- [ ] The pinned floating window has a minimum size of 360 by 320 points.
- [ ] The pinned floating window has no app-defined maximum size.
- [ ] The app does not add a custom resize handle or explanatory resize UI.
- [ ] Resizing or moving the pinned floating window saves the shared `windowFrame`.
- [ ] Extra height primarily expands the scratchpad editor.
- [ ] Clip Shelf height remains capped and scrollable.
- [ ] Existing scratchpad editing and clip actions still work after resizing.

## Blocked by

- .scratch/resizable-scratchpad-windows/issues/01-rename-saved-frame-to-window-frame.md
