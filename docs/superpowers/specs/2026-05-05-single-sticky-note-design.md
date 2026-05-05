# Single Sticky Note Design

## Context

The Clipboard Scratchpad is a macOS menu-bar app that currently stores clipboard captures as a structured list of `ScratchBlock` items (manual notes vs. captured clips). The user wants to convert it into a single editable sticky note where captured clips are automatically appended as plain text with a lightweight prefix.

## Goal

Replace the block-list UI with a single editable plain-text document that feels like a sticky note catching copied text.

## Architecture

### Data Model

The app now uses a single editable plain-text document.

Persisted:
- `noteText: String`

Runtime-only:
- `isCapturing: Bool` — always `false` on launch, never persisted
- `lastCapturedText: String?` — used only for immediate deduplication, never persisted

No hidden structured clip metadata is stored. Once captured text is appended to the note, it becomes normal editable text.

Persistence: JSON via `Codable` to `~/Library/Application Support/ClipboardScratchpad/store.json` with a single `StoreState` struct containing `noteText`.

The `ScratchBlock` enum and its associated types (`ManualBlock`, `CapturedBlock`) are deleted from the live app model and UI. Legacy block types may remain in a migration-only file/namespace until migration is no longer needed. They must not be used by the live app model or UI.

### Clipboard Capture

The monitor polls `NSPasteboard.changeCount` on the main thread.

When capture is turned on, set the monitor's `lastSeenChangeCount` to `NSPasteboard.general.changeCount` before polling begins. This prevents the app from immediately capturing whatever was already on the clipboard before the user turned capture on.

When a new clipboard string is detected:
1. Ignore it if Clipboard Scratchpad is the frontmost app.
2. Use trimmed text only to check whether the capture is empty.
3. Use the same normalized text for immediate deduplication against `lastCapturedText`.
4. Append the original copied text, preserving whitespace.
5. Format the capture as:

```
[HH:MM AM/PM · AppName]
copied text
```

If `AppName` is unavailable, use `[HH:MM AM/PM]` as the prefix.

Captured clips always append to the end of `noteText`. When appending to a non-empty note, remove only trailing newline characters, then append exactly two newline characters before the new clip. Do not remove spaces, tabs, or other user-entered characters.

After appending, update `lastCapturedText` with the normalized text and save immediately.

The `Copy All` button inside the app triggers a pasteboard write. Call `clipboardMonitor.noteExternalPasteboardWrite()` after writing to the pasteboard because the write changes `NSPasteboard.changeCount`.

### UI

Use SwiftUI `TextEditor` for the first implementation. If focus, scrolling, undo, cursor preservation, or plain-text control becomes unreliable, replace it with `NSTextView` wrapped in SwiftUI.

The single editable note area fills the popover. User types directly into the note.

Toolbar row at bottom with icon buttons. Each icon button must have an accessibility label and tooltip:
- **Clipboard toggle** — `play.fill` / `pause.fill`. Label: "Start Capturing" / "Pause Capturing".
- **Copy All** — `doc.on.doc` icon. Label: "Copy All".
- **Clear** — `trash` icon. Label: "Clear".

Remove the separate text input + "Add Note" button. Remove "Convert" button and all conversion logic. Popover size stays 400×520. No explanatory copy or meta commentary inside the app UI.

### Block Row Cleanup

Delete `BlockRow`, `ManualBlockRow`, `CapturedBlockRow` views. Delete `ScratchBlock`, `ManualBlock`, `CapturedBlock` from the live model and UI. Keep legacy decode types in a migration-only file if needed.

### Migration

1. Try decoding `store.json` as the new `StoreState`.
2. If that fails, try decoding as the old block-based `[ScratchBlock]` store.
3. If old decode succeeds, convert blocks into `noteText`:
   - `ManualBlock` → append the `content` directly (no prefix).
   - `CapturedBlock` → append `[HH:MM AM/PM · AppName]\ncapturedContent`.
   - Separate each migrated block with two newlines.
4. Before overwriting, copy the old file to `store.blocks.backup.json`.
5. Write the new `StoreState` to `store.json`.
6. If migration fails, start with an empty note and log the error. Do not delete the old file before a successful new save.

## Autosave

Manual edits from the `TextEditor` are autosaved using a short debounce of 300–500ms after the last edit. Clipboard appends, Clear, and migration save immediately.

## Edge Cases

- **Empty note on first launch** — show empty sticky note. No placeholder text inside the editor.
- **Maximum length** — cap `noteText` at 100,000 characters. If a capture would exceed it, skip the append and show a small non-modal toolbar message: "Note is full." If manual editing pushes `noteText` beyond 100,000 characters, allow the edit but show "Note is full" and prevent further clipboard captures until the note is reduced below the limit. Do not forcibly truncate what the user typed.
- **User deletes timestamp prefix** — perfectly fine, it's just text now.
- **User pastes the same text twice** — `lastCapturedText` dedup catches identical consecutive captures.
- **noteText ends with whitespace/newlines** — when appending, remove only trailing newline characters, then insert exactly two newlines before the new clip. Do not strip spaces, tabs, or other user-entered characters.
