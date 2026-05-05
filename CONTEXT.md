# Clipboard Scratchpad Context

## Product

Clipboard Scratchpad is a lightweight macOS menu bar utility for temporary text collection and drafting.

The app gives the user one editable plain-text scratchpad plus a recent clip shelf. Copied text is captured into the shelf, and the user can insert useful clips into the scratchpad when needed.

The product should stay local-first, fast, and single-purpose. It should not become a full clipboard manager, notes database, research system, or AI writing tool.

## Current App Shape

- macOS 14+ menu bar app.
- AppKit app shell with a status bar item and popover.
- SwiftUI content inside the popover.
- Plain text editor backed by `NSTextView`.
- Clipboard polling via `NSPasteboard.changeCount`.
- Recent clip shelf with captured text, source app metadata, capture time, and a cap of 50 clips.
- Clicking a clip inserts it into the scratchpad at the current or last known cursor position.
- Copy-all writes the scratchpad text to the clipboard.
- Clear removes the scratchpad after confirmation.
- The popover can be pinned so it stays open.
- The footer shows line, word, character, and last-updated metadata.
- Scratchpad text and clips persist as JSON in Application Support.

## Current Non-Goals

- No iOS or cross-platform version.
- No cloud sync or accounts.
- No folders, tags, or long-term clipboard history.
- No image, file, or rich media capture.
- No AI features.
- No external dependencies unless explicitly approved.
- No Core Data.

## Important Product Decisions

- Current v1 is not a block-based document editor. Captured clips live in a shelf and become plain text when inserted.
- The scratchpad itself is plain text. Preserve normal text editing behavior and undo expectations.
- Captured clipboard data should remain local.
- Capture behavior should feel obvious and controllable before the app is treated as launch-ready.

## Known Gaps And Open Decisions

- Capture currently starts automatically on launch. Decide whether v1 should add explicit start/pause control before shipping.
- Settings button exists in the UI but does not yet open settings.
- Global hotkey is not implemented.
- Launch at login is not implemented.
- Excluded apps and clear-on-quit privacy controls are not implemented.
- Markdown export is not implemented.
- Per-clip actions such as delete one clip or copy one clip are not implemented.
- Decide whether `PRD.md` should be archived, trimmed, or rewritten now that the app has evolved.

## Architecture Notes

- Build system is Swift Package Manager only.
- Main source lives in `Sources/ClipboardScratchpad/`.
- `AppDelegate` owns app lifecycle and the shared `ScratchpadStore`.
- `StatusBarController` owns the menu bar item and popover.
- `ContentView` owns the main SwiftUI layout.
- `PlainTextView` bridges SwiftUI to `NSTextView`.
- `ScratchpadStore` owns scratchpad state, clip state, persistence, and clipboard monitor wiring.
- `ClipboardMonitor` polls `NSPasteboard` on the main thread.
- `StoreState` is the current persisted Codable shape.

## Persistence

Persist app data as JSON under:

```text
~/Library/Application Support/ClipboardScratchpad/store.json
```

The current stored state includes:

- `noteText`
- `updatedAt`
- `clips`

Legacy block-shaped state can be migrated into plain text and backed up to:

```text
~/Library/Application Support/ClipboardScratchpad/store.blocks.backup.json
```

## Working Rules

- Prefer small, direct changes over abstractions.
- Keep UI copy minimal and avoid meta commentary inside the app.
- Preserve local-first behavior.
- Avoid background-thread pasteboard access.
- Use `swift build` for build verification and `swift run` for manual testing.
