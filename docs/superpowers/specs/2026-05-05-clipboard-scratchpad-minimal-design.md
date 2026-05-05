# Clipboard Scratchpad — Minimal Slice Design

## Goal
Ship a working macOS menu bar app that collects copied text into an editable scratchpad.

## Architecture

- **AppKit shell:** `StatusBarController` owns an `NSStatusItem` and `NSPopover`. The popover hosts a SwiftUI `ContentView` via `NSHostingController`.
- **SwiftUI content:** `ContentView` shows a scrollable list of blocks. Manual text is plain. Captured blocks are styled cards with source app, timestamp, and inline action buttons (copy, convert, delete).
- **Shared state:** `ScratchpadStore` (ObservableObject) is injected from `AppDelegate`. It owns the block array and exposes all user actions.
- **Clipboard monitor:** `ClipboardMonitor` polls `NSPasteboard.changeCount` every 0.5s. When capture is active and the count changes, it reads the string, deduplicates against the last capture, and appends a `CapturedBlock`.
- **Persistence:** The block array serializes to JSON in `~/Library/Application Support/ClipboardScratchpad/store.json` via Codable. Loaded on launch, saved on every mutation.

## Data Model

```
Block (protocol)
  id: UUID
  timestamp: Date
  content: String

ManualBlock : Block

CapturedBlock : Block
  sourceApp: String?

StoredBlock (Codable enum)
  .manual(id, timestamp, content)
  .captured(id, timestamp, content, sourceApp)
```

`ScratchpadStore` exposes `[any Block]` to the view but serializes via `[StoredBlock]`.

## Data Flow

1. User clicks status bar icon → popover opens.
2. User types in a text field at the top → `ManualBlock` appended.
3. User toggles capture ON → `ClipboardMonitor` starts polling.
4. Clipboard changes → monitor calls `store.appendCapture(content, sourceApp)`.
5. Store deduplicates, appends, saves JSON.
6. View reacts via `@Published`.

## UI Behavior

- Popover width: 360pt. Height: ~480pt, resizable.
- Bottom bar: capture toggle button, "Copy All" button, "Clear" button.
- Captured block card: rounded rectangle background, monospace-ish text, small metadata row with source app + time, inline buttons (copy, convert to manual, delete).
- "Copy All" concatenates all block content with double newlines.
- "Clear" prompts for confirmation if blocks exist.

## Error Handling

- Clipboard permission failure (no changeCount changes after activation) → "Capture unavailable" badge in the UI with a button to open Security & Privacy settings.
- Persistence read/write errors → silently logged, degrade to in-memory scratchpad.

## Out of Scope (Future Slices)

- Global hotkey
- Export as Markdown
- App exclusions list
- Launch at login
- Settings/preferences window
- Undo support beyond text editing
