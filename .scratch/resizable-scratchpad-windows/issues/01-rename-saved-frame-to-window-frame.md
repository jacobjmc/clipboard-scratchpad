Status: needs-triage

# Rename saved frame to windowFrame

## Parent

.scratch/resizable-scratchpad-windows/PRD.md

## What to build

Rename the persisted scratchpad window frame from the pinned-only concept to `windowFrame`, representing the shared size and position for detached and pinned windows. Do not preserve, decode, or migrate the old `floatingFrame` key.

## Acceptance criteria

- [ ] The persisted frame field is named `windowFrame`.
- [ ] New store JSON writes `windowFrame`, not `floatingFrame`.
- [ ] Old `floatingFrame` data is not decoded or migrated.
- [ ] Existing scratchpad text and clips still decode and persist normally.
- [ ] Frame data remains local in the existing JSON store.
- [ ] Tests cover `windowFrame` encode/decode behavior and unsupported old `floatingFrame` data.

## Blocked by

None - can start immediately
