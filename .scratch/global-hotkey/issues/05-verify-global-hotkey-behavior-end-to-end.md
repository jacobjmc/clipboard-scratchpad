# Verify global hotkey behavior end to end

Status: needs-triage

## Parent

.scratch/global-hotkey/PRD.md

## What to build

Verify the global hotkey feature across Settings, persistence, OS registration, and the anchored, detached, and pinned scratchpad presentation states. This issue is focused on real app behavior that cannot be fully proven by unit tests.

## Acceptance criteria

- [ ] `swift build` passes.
- [ ] `swift test` passes.
- [ ] Running the app manually starts with the shortcut unassigned when no shortcut has been saved.
- [ ] Recording a valid shortcut in Settings registers it and displays the chosen shortcut.
- [ ] The shortcut works while another app is focused.
- [ ] The shortcut shows the anchored popover when no surface is visible.
- [ ] The shortcut hides the anchored popover when it is visible.
- [ ] The shortcut brings a detached window forward without hiding it.
- [ ] The shortcut shows and hides the pinned floating window while keeping pinned mode active.
- [ ] Clearing the shortcut unregisters it and returns Settings to `None`.
- [ ] A conflicting or unavailable shortcut shows the unavailable status and does not replace the previous working shortcut.
- [ ] Relaunching the app restores and registers the saved shortcut.
- [ ] If launch-time registration fails, Settings shows the saved shortcut with an unavailable status.
- [ ] Accessibility permission behavior for paste-to-previous-app is unchanged.

## Blocked by

- .scratch/global-hotkey/issues/01-add-shortcut-model-validation-and-persistence.md
- .scratch/global-hotkey/issues/02-add-global-hotkey-registration-and-startup-restore.md
- .scratch/global-hotkey/issues/03-add-settings-shortcut-recorder.md
- .scratch/global-hotkey/issues/04-wire-hotkey-activation-into-scratchpad-presentation.md
