Status: needs-triage

# Add pinned floating panel mode

## Parent

.scratch/pinned-floating-window/PRD.md

## What to build

When the user pins Clipboard Scratchpad, promote the scratchpad from the anchored menu bar popover into a real fixed-size floating utility panel. When unpinned, keep the normal menu bar popover behavior. The pinned surface should use the existing scratchpad content and controls without adding explanatory UI copy.

## Acceptance criteria

- [ ] Clicking the pin control switches from anchored popover mode to a real floating window or panel.
- [ ] The pinned floating surface uses the same fixed content size as the existing popover.
- [ ] The pinned floating surface keeps the existing in-content header controls and does not add a standard duplicate title bar.
- [ ] The pinned floating surface stays above normal application windows while visible.
- [ ] Clicking the pin control again returns the app to normal anchored popover behavior.
- [ ] Existing scratchpad editing, Clip Shelf, clipboard monitoring, and paste-to-previous-app behavior still work in both modes.
- [ ] No explanatory UI copy is added for the feature.

## Blocked by

None - can start immediately
