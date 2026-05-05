# Single Sticky Note Design

## Context

The Clipboard Scratchpad is a macOS menu-bar app that currently stores clipboard captures as a structured list of `ScratchBlock` items (manual notes vs. captured clips). The user wants to convert it into a single editable sticky note where captured clips are automatically appended as plain text with a lightweight prefix.

## Goal

Replace the block-list UI with a single editable plain-text document that feels like a sticky note catching copied text.

## Architecture

### Data Model

- One `String` property `noteText` replaces `[ScratchBlock]`.
- Simple settings (`isCapturing: Bool`) still persisted alongside the note.
- No hidden structured metadata. The saved file is just the document string plus settings.
- In-memory `lastCapturedText: String?` for deduplication only — not persisted.
- Persistence: JSON via `Codable` to `~/Library/Application Support/ClipboardScratchpad/store.json`. Two keys: `noteText` and `isCapturing`.
- The `ScratchBlock` enum and its associated types (`ManualBlock`, `CapturedBlock`) are deleted. The project convention requiring `ScratchBlock` is retired because a single plain-text document is the correct model for a sticky note.

### Clipboard Capture

- Poll `NSPasteboard.changeCount` on main thread (existing behavior).
- When a new string is captured:
  1. Trim whitespace from the captured string.
  2. Check `lastCapturedText` — if identical, skip.
  3. Format prefix: `[HH:MM AM/PM · AppName]`.
  4. Normalize `noteText` trailing whitespace: strip all trailing whitespace and newlines, then append exactly two newlines, the prefix, a newline, and the captured text.
  5. Update `lastCapturedText`.
  6. Save.
- If the frontmost app is the scratchpad itself, skip (existing behavior).

### UI

- Single `TextEditor` (SwiftUI) fills the popover body.
- Toolbar row at bottom with icon buttons:
  - **Clipboard toggle** — `play.fill` / `pause.fill` to start/pause capture.
  - **Copy All** — `doc.on.doc` icon. Copies the entire `noteText` to pasteboard.
  - **Clear** — `trash` icon. Shows destructive confirmation alert.
- Remove the separate text input + "Add Note" button — everything is typed directly into the sticky note.
- Remove "Convert" button and all conversion logic.
- Popover size stays 400×520; the sticky note fills the space.
- No explanatory copy or meta commentary inside the app UI.

### Block Row Cleanup

- Delete `BlockRow`, `ManualBlockRow`, `CapturedBlockRow` views.
- Delete `ScratchBlock`, `ManualBlock`, `CapturedBlock` model types.
- Delete `appendManual`, `deleteBlock`, `convertToManual` methods from `ScratchpadStore`.

### Migration

- On first load with the new model, if the old `[ScratchBlock]` store exists:
  - `ManualBlock` → append the `content` directly (no prefix).
  - `CapturedBlock` → append `[HH:MM AM/PM · AppName]\ncapturedContent`.
  - Separate each migrated block with two newlines.
  - Set the resulting string as `noteText`, then delete the old file.
- If migration fails or no old store exists, start with an empty note.

## Edge Cases

- **Empty note on first launch** — show empty sticky note. No placeholder text inside the editor.
- **Maximum length** — cap `noteText` at 100,000 chars. If a capture would exceed it, silently skip the append. Do not show a warning.
- **User deletes timestamp prefix** — perfectly fine, it's just text now.
- **User pastes the same text twice** — `lastCapturedText` dedup catches identical consecutive captures.
- **noteText ends with whitespace/newlines** — normalized on every append (see Clipboard Capture spacing rules).
