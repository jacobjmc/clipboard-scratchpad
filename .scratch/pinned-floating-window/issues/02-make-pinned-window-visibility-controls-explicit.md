Status: needs-triage

# Make pinned window visibility controls explicit

## Parent

.scratch/pinned-floating-window/PRD.md

## What to build

Make visibility separate from pinned mode. While pinned, the menu bar item and close action should hide or show the floating window without unpinning. Outside clicks and Escape should not dismiss the pinned floating window.

## Acceptance criteria

- [ ] While pinned and visible, clicking the menu bar item hides the floating window without changing pinned mode.
- [ ] While pinned and hidden, clicking the menu bar item shows the same floating window without replacing it with the popover.
- [ ] Closing the pinned floating window hides it without changing pinned mode.
- [ ] Only the pin control changes pinned/unpinned mode.
- [ ] Clicking outside the pinned floating window does not dismiss it.
- [ ] Pressing Escape does not unexpectedly hide the pinned floating window or break normal text editing behavior.

## Blocked by

- .scratch/pinned-floating-window/issues/01-add-pinned-floating-panel-mode.md
