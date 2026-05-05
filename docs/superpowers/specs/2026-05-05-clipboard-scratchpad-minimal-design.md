# Clipboard Scratchpad — Minimal Slice Design

## Goal
Ship a working macOS menu bar app that collects copied text into an editable scratchpad.

## Architecture

- **AppKit shell:** `StatusBarController` owns an `NSStatusItem` and `NSPopover` with a fixed `contentSize` of 360×480pt. The popover hosts a SwiftUI `ContentView` via `NSHostingController`.
- **SwiftUI content:** `ContentView` shows a scrollable list of blocks. Manual text is plain. Captured blocks are styled cards with source app, timestamp, and inline action buttons (copy, convert, delete).
- **Shared state:** `ScratchpadStore` (ObservableObject) is injected from `AppDelegate`. It owns the block array and exposes all user actions. `ScratchpadStore` also owns `@Published var isCapturing: Bool` (does **not** persist across launches; starts as `false`). It explicitly calls `ClipboardMonitor.start(onCapture:)` / `ClipboardMonitor.stop()` when the value changes.
- **Clipboard monitor:** `ClipboardMonitor` is a standalone class. When started, it polls `NSPasteboard.changeCount` every 0.5s on the **main thread** (`NSPasteboard` requires main-thread access). When the count changes, it reads the string, deduplicates, and invokes the `onCapture` closure passed to `start(onCapture:)`. The monitor exposes `noteExternalPasteboardWrite()` which updates its internal `lastSeenChangeCount` to the current value, preventing the next poll from treating the app's own pasteboard writes as new captures.
- **Persistence:** The block array serializes to JSON in `~/Library/Application Support/ClipboardScratchpad/store.json` via Codable. Loaded on launch, saved on every mutation. Corrupted or missing JSON → start fresh with an empty scratchpad.

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
2. User types in the bottom text field and presses **Cmd+Return** → `ManualBlock` appended (ignored if content is empty after trimming; truncated to 10,000 chars if exceeded). **Return** inserts a newline.
3. User toggles capture ON → `ScratchpadStore.isCapturing = true` → `ClipboardMonitor.start(onCapture:)`.
4. Clipboard changes → monitor invokes the `onCapture` closure with `(content, sourceApp)`.
5. `ScratchpadStore` validates (ignores empty after trimming; truncates to 10,000 chars), deduplicates, appends at the bottom of the list, saves JSON.
6. View reacts via `@Published`; scroll view pins to the newest entry.

## Deduplication Rule

A new capture is ignored if its `content` (after trimming trailing newlines) exactly matches the `content` of the most recently appended `CapturedBlock` (after the same trimming). This prevents duplicate blocks when the user copies the same text twice in a row. Re-capturing the same text after other activity is allowed. A manual block with identical text does **not** prevent a capture.

## Content Validation

- Empty string content (after trimming whitespace and newlines) is ignored for both manual entry and clipboard capture.
- Content exceeding 10,000 characters is truncated to 10,000 with an appended "…".

## UI Behavior

- Popover: fixed 360×480pt `contentSize`.
- Bottom bar: multiline text input (**Return** for newline, **Cmd+Return** to submit), capture toggle button, "Copy All" button, "Clear" button.
- Captured block card: rounded rectangle background, source app + timestamp metadata row (omitted if `sourceApp` is nil), inline buttons (copy, convert to manual, delete).
- Manual block: plain text row with a delete button. Not editable inline in this slice (delete and re-add if needed).
- "Copy All" concatenates all block content with double newlines. Before writing, calls `ClipboardMonitor.noteExternalPasteboardWrite()` to suppress self-capture.
- "Clear" shows a native `NSAlert` with "Cancel" and "Clear" buttons if blocks exist.
- Empty state: centered placeholder text "Start typing or turn on capture to collect clips."

## Block Actions

- **Delete (manual or captured):** Removes the block from the store. Does not affect other blocks.
- **Copy (captured):** Copies the block's content to the system clipboard, then calls `ClipboardMonitor.noteExternalPasteboardWrite()`. Does not create a duplicate captured block.
- **Convert to manual (captured):** Appends a new `ManualBlock` with the same `content` and current `timestamp`, then deletes the original `CapturedBlock`.

## sourceApp Heuristic

`sourceApp` is determined by reading `NSWorkspace.shared.frontmostApplication?.localizedName` at poll time. This is a best-effort heuristic; the user may have switched apps between the copy and the poll. The UI does not claim perfect accuracy. When `nil`, the metadata row is hidden.

## Error Handling

- Persistence read/write errors or corrupted JSON → silently logged via `os_log`, degrade to in-memory scratchpad or start fresh.

## Out of Scope (Future Slices)

- Global hotkey
- Export as Markdown
- App exclusions list
- Launch at login
- Settings/preferences window
- Inline editing of manual blocks
- Undo support beyond text editing
- Capture-unavailable state and permission UI
- Max block count / memory ceiling
