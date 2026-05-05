# Clipboard Scratchpad — Minimal Slice Design

## Goal
Ship a working macOS menu bar app that collects copied text into an editable scratchpad.

## Product Shape

For this slice, the scratchpad is a **temporary menu bar popover**, not a persistent floating sticky note. It opens on status bar click and closes when the user clicks elsewhere. Later slices may add a detach/keep-open mode using `NSPanel`.

## Architecture

- **AppKit shell:** `StatusBarController` owns an `NSStatusItem` and `NSPopover` with a fixed `contentSize` of 400×520pt. The popover hosts a SwiftUI `ContentView` via `NSHostingController`.
- **SwiftUI content:** `ContentView` shows a scrollable list of blocks. Manual text is plain. Captured blocks are styled cards with source app, timestamp, and inline action buttons (copy, convert, delete).
- **Shared state:** `ScratchpadStore` (ObservableObject) is injected from `AppDelegate`. It owns the block array and exposes all user actions. `ScratchpadStore` also owns `@Published var isCapturing: Bool` (does **not** persist across launches; starts as `false`). It explicitly calls `ClipboardMonitor.start(onCapture:)` / `ClipboardMonitor.stop()` when the value changes.
- **Clipboard monitor:** `ClipboardMonitor` is a standalone class. When started, it polls `NSPasteboard.changeCount` every 0.5s on the **main thread** (`NSPasteboard` requires main-thread access). When the count changes, it reads the string, deduplicates, and invokes the `onCapture` closure passed to `start(onCapture:)`. The monitor exposes `noteExternalPasteboardWrite()` which updates its internal `lastSeenChangeCount` to the current value, preventing the next poll from treating the app's own pasteboard writes as new captures.
- **Persistence:** The block array serializes to JSON in `~/Library/Application Support/ClipboardScratchpad/store.json` via Codable. Loaded on launch, saved on block-level mutations (append, delete, convert, clear). Corrupted or missing JSON → start fresh with an empty scratchpad.

## Data Model

Use a single enum as the model. No protocol existentials, no separate stored enum.

```swift
enum ScratchBlock: Identifiable, Codable, Equatable {
    case manual(ManualBlock)
    case captured(CapturedBlock)

    var id: UUID { … }
    var content: String { … }
    var timestamp: Date { … }
}

struct ManualBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: Date
    var content: String
}

struct CapturedBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: Date
    var content: String
    var sourceAppName: String?
    var sourceBundleID: String?
}
```

`ScratchpadStore` exposes:

```swift
@Published private(set) var blocks: [ScratchBlock] = []
@Published var isCapturing: Bool = false
@Published var persistenceWarning: String? = nil
```

## Data Flow

1. User clicks status bar icon → popover opens.
2. User types in the bottom text field and presses **Cmd+Return** (or clicks **Add Note**) → `ManualBlock` appended at the bottom (ignored if content is empty after trimming; truncated to 10,000 chars if exceeded). **Return** inserts a newline.
3. User toggles capture ON → `ScratchpadStore.isCapturing = true` → `ClipboardMonitor.start(onCapture:)`.
4. Clipboard changes → monitor invokes the `onCapture` closure with `(content, sourceAppName, sourceBundleID)`.
5. `ScratchpadStore` validates (ignores empty after trimming; truncates to 10,000 chars), deduplicates, appends at the bottom, saves JSON.
6. View reacts via `@Published`; scroll view pins to the newest entry.

## Content Validation

Empty string content (after trimming whitespace and newlines via `.whitespacesAndNewlines`) is ignored for both manual entry and clipboard capture. Content exceeding 10,000 characters is truncated to 10,000 with an appended "…".

## Deduplication Rule

A new capture is ignored if its normalized content matches the normalized content of the most recently appended `.captured` block. Normalization: `trimmingCharacters(in: .whitespacesAndNewlines)`. This prevents duplicate blocks when the user copies the same text twice in a row. Re-capturing the same text after other activity is allowed. A `.manual` block with identical text does **not** prevent a capture.

## Self-Capture Suppression

Whenever the app writes to the pasteboard (Copy All, Copy Block), it writes the string first, then immediately calls `ClipboardMonitor.noteExternalPasteboardWrite()`. This updates the monitor's internal `lastSeenChangeCount` so the next poll does not treat the app's own write as a new capture.

```swift
func writeToPasteboard(_ string: String) {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(string, forType: .string)
    clipboardMonitor.noteExternalPasteboardWrite()
}
```

## UI Behavior

- Popover: fixed 400×520pt `contentSize`.
- Bottom bar: multiline text input (**Return** for newline, **Cmd+Return** to submit), visible **Add Note** button, capture toggle button, "Copy All" button, "Clear" button.
- Capture toggle uses explicit copy: "Start Capture" / "Pause Capture" instead of an ambiguous switch.
- Captured block card: rounded rectangle background, source app name + timestamp metadata row (omitted if `sourceAppName` is nil), inline buttons (copy, convert to manual, delete).
- Manual block: plain text row with a delete button. Not editable inline in this slice (delete and re-add if needed).
- "Copy All" concatenates all block content with double newlines.
- "Clear" shows a native `NSAlert` with "Cancel" and "Clear" buttons if blocks exist.
- Empty state: centered placeholder text "Start typing or turn on capture to collect clips."
- Privacy notice: small footer text "Captured text stays on this Mac."

## Block Actions

- **Delete (manual or captured):** Removes the block from the store in place. Does not affect other blocks.
- **Copy (captured):** Writes the block's content to the system clipboard via `writeToPasteboard`, then updates the monitor. Does not create a duplicate captured block.
- **Convert to manual (captured):** Replaces the `.captured` block in-place with a `.manual` block using the same `id`, `content`, and `timestamp` (or a new timestamp if desired). Preserves position in the list.

## sourceApp Heuristic

`sourceAppName` and `sourceBundleID` are determined by reading `NSWorkspace.shared.frontmostApplication` at poll time. This is a best-effort heuristic; the user may have switched apps between the copy and the poll. The UI does not claim perfect accuracy. When values are nil, the metadata row is hidden.

## Privacy Guards

- Do not capture while the app itself is frontmost.
- Do not capture empty or whitespace-only strings.

## Error Handling

- Persistence read/write errors or corrupted JSON → silently logged via `os_log`, start fresh with empty scratchpad, and set `persistenceWarning` to a non-invasive message ("Couldn’t save changes. Content will remain until the app quits.") shown as a small banner in the popover.

## Guardrails

- Max total blocks: 500. When exceeded, stop capturing and show a warning in the UI.
- Max block content: 10,000 characters (truncated with "…").

## Out of Scope (Future Slices)

- Global hotkey
- Export as Markdown
- App exclusions list
- Launch at login
- Settings/preferences window
- Inline editing of manual blocks
- Undo support beyond text editing
- Capture-unavailable state and permission UI
- Floating/detachable window mode
