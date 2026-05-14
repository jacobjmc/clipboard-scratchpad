# Persist Paper Finish Setting

Status: needs-triage

## Parent

.scratch/paper-finish/PRD.md

## What to build

Add a default-on persisted `Paper Finish` setting to local app state so the user's preference survives relaunches and older stored state enables the paper finish by default.

## Acceptance criteria

- [ ] Older stored JSON without a Paper Finish field decodes with Paper Finish enabled.
- [ ] Paper Finish can be saved and loaded as both enabled and disabled.
- [ ] Existing stored fields such as note text, clips, window frame, global shortcut, and appearance preference keep their current behavior.
- [ ] The shared store exposes Paper Finish as app state that UI surfaces can observe and update.
- [ ] The implementation keeps persistence explicit and does not introduce a general preferences framework.

## Blocked by

None - can start immediately
