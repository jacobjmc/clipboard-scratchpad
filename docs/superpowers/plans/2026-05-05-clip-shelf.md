# Clip Shelf Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an always-on Clip Shelf so copied text is captured into a persisted drawer instead of being auto-inserted into the sticky note.

**Architecture:** Keep the current SwiftPM macOS app shape. Extend `StoreState` and `ScratchpadStore` to persist clips beside note text, keep `ClipboardMonitor` as the single pasteboard polling boundary, use `PlainTextView` for cursor-sensitive insertion, and add a small SwiftUI inline drawer above the bottom toolbar.

**Tech Stack:** Swift 5.9, Swift Package Manager, macOS 14+, AppKit `NSPasteboard`/`NSTextView`, SwiftUI, JSON `Codable` persistence. No new dependencies.

---

## Scope And File Structure

Spec: `docs/superpowers/specs/2026-05-05-clip-shelf-design.md`

Project constraints:

- Swift Package Manager only.
- No external dependencies.
- Clipboard access stays on the main thread.
- Persistence stays JSON in `~/Library/Application Support/ClipboardScratchpad/`.
- There is no unit test target yet; verification is `swift build` plus manual testing via `swift run`.

Files to modify:

- `Sources/ClipboardScratchpad/StoreState.swift`
  - Add `ClipShelfItem`.
  - Add persisted `clips`.
  - Add custom decode/defaulting so old JSON without `clips` loads as an empty shelf.

- `Sources/ClipboardScratchpad/ScratchpadStore.swift`
  - Replace note auto-append capture behavior with clip capture.
  - Start clipboard monitoring automatically.
  - Add `clips` state and explicit methods: `captureClipboardText`, `insertClip`, `clearClips`.
  - Preserve app-owned pasteboard write ignoring through `noteExternalPasteboardWrite`.

- `Sources/ClipboardScratchpad/PlainTextView.swift`
  - Replace `scratchpadAppendText` capture insertion with `scratchpadInsertText`.
  - Insert notification content at selected range or cursor.
  - Append to the end if no active insertion point exists.
  - Keep undo behavior intact.

- `Sources/ClipboardScratchpad/ContentView.swift`
  - Remove capture toggle.
  - Add Clips button with badge.
  - Add inline Clip Shelf drawer above the toolbar.
  - Keep note metadata blended into the toolbar.

- `Sources/ClipboardScratchpad/AppDelegate.swift`
  - Stop monitor on app termination if the store exposes a stop method.

Do not modify:

- `Package.swift`
- `.gitignore`
- Existing docs except this implementation plan, unless a later user explicitly asks.

## Chunk 1: Persisted Clip Model

### Task 1: Add ClipShelfItem And Backward-Compatible StoreState

**Files:**

- Modify: `Sources/ClipboardScratchpad/StoreState.swift:3-11`

- [ ] **Step 1: Add `ClipShelfItem` above `StoreState`**

Add:

```swift
struct ClipShelfItem: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let capturedAt: Date
    let sourceAppName: String?
    let sourceBundleID: String?
}
```

- [ ] **Step 2: Extend `StoreState` with clips**

Change `StoreState` to include:

```swift
struct StoreState: Codable {
    var noteText: String
    var updatedAt: Date?
    var clips: [ClipShelfItem]

    init(noteText: String, updatedAt: Date? = nil, clips: [ClipShelfItem] = []) {
        self.noteText = noteText
        self.updatedAt = updatedAt
        self.clips = clips
    }
}
```

- [ ] **Step 3: Add custom decoding for old saved JSON**

Implement `init(from decoder:)` so missing `clips` defaults to `[]` and missing `updatedAt` defaults to `nil`.

Use this shape:

```swift
private enum CodingKeys: String, CodingKey {
    case noteText
    case updatedAt
    case clips
}

init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    noteText = try container.decode(String.self, forKey: .noteText)
    updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    clips = try container.decodeIfPresent([ClipShelfItem].self, forKey: .clips) ?? []
}
```

- [ ] **Step 4: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Sources/ClipboardScratchpad/StoreState.swift
git commit -m "feat: add persisted clip shelf model"
```

## Chunk 2: Store And Capture Behavior

### Task 2: Convert Capture From Note Append To Clip Shelf

**Files:**

- Modify: `Sources/ClipboardScratchpad/ScratchpadStore.swift:6-83`
- Modify: `Sources/ClipboardScratchpad/ScratchpadStore.swift:125-183`

- [ ] **Step 1: Add store properties**

Add:

```swift
@Published var clips: [ClipShelfItem] = []

private let maxClips = 50
private var lastCapturedClipText: String? = nil
```

Remove or stop using:

```swift
@Published var isCapturing: Bool = false
private var lastCapturedText: String? = nil
```

- [ ] **Step 2: Start monitoring automatically in `init`**

After `load()` in `init`, call a new private method:

```swift
startClipboardMonitoring()
```

Implement:

```swift
private func startClipboardMonitoring() {
    clipboardMonitor.start { [weak self] content, name, bundleID in
        DispatchQueue.main.async {
            self?.captureClipboardText(content, sourceAppName: name, sourceBundleID: bundleID)
        }
    }
}
```

- [ ] **Step 3: Add stop method for app termination**

Add:

```swift
func stopClipboardMonitoring() {
    clipboardMonitor.stop()
}
```

- [ ] **Step 4: Remove `setCapturing(_:)` behavior**

Delete `setCapturing(_:)` or leave it only if all call sites are removed and there is a temporary compile need. Preferred: delete it.

- [ ] **Step 5: Replace `handleCapture` with `captureClipboardText`**

Implement:

```swift
func captureClipboardText(_ content: String, sourceAppName: String?, sourceBundleID: String?) {
    let normalized = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !normalized.isEmpty else { return }
    guard normalized != lastCapturedClipText else { return }

    let clip = ClipShelfItem(
        id: UUID(),
        content: content,
        capturedAt: Date(),
        sourceAppName: sourceAppName,
        sourceBundleID: sourceBundleID
    )

    clips.insert(clip, at: 0)
    if clips.count > maxClips {
        clips.removeLast(clips.count - maxClips)
    }

    lastCapturedClipText = normalized
    saveImmediately()
}
```

Do not modify `noteText` here.

- [ ] **Step 6: Add clip actions**

Add:

```swift
func insertClip(_ clip: ClipShelfItem) {
    NotificationCenter.default.post(
        name: .scratchpadInsertText,
        object: nil,
        userInfo: ["content": clip.content]
    )
}

func clearClips() {
    clips = []
    lastCapturedClipText = nil
    saveImmediately()
}
```

- [ ] **Step 7: Persist clips**

Change `saveImmediately()` to:

```swift
let state = StoreState(noteText: noteText, updatedAt: updatedAt, clips: clips)
```

Change `load()` to assign:

```swift
clips = state.clips
lastCapturedClipText = state.clips.first?.content.trimmingCharacters(in: .whitespacesAndNewlines)
```

In the no-data fallback, set:

```swift
clips = []
```

In `migrate(legacyBlocks:)`, keep the existing migration into note text and set:

```swift
clips = []
```

- [ ] **Step 8: Preserve Copy All ignore behavior**

Keep `copyAll()` calling:

```swift
clipboardMonitor.noteExternalPasteboardWrite()
```

Do not route `copyAll()` through clip capture.

- [ ] **Step 9: Build**

Run:

```bash
swift build
```

Expected: build may fail because UI still references `isCapturing` and `setCapturing`. That is acceptable at this step only if the errors are limited to `ContentView`.

- [ ] **Step 10: Commit after the UI task compiles**

Do not commit this task until Chunk 3 removes the old UI references and `swift build` passes.

## Chunk 3: Text Insertion Contract

### Task 3: Add Clip Insert Notification To PlainTextView

**Files:**

- Modify: `Sources/ClipboardScratchpad/PlainTextView.swift:4-8`
- Modify: `Sources/ClipboardScratchpad/PlainTextView.swift:86-207`

- [ ] **Step 1: Replace append notification name**

Remove:

```swift
static let scratchpadAppendText = Notification.Name("scratchpadAppendText")
```

Add:

```swift
static let scratchpadInsertText = Notification.Name("scratchpadInsertText")
```

Keep:

```swift
static let scratchpadPopoverDidShow = Notification.Name("scratchpadPopoverDidShow")
static let scratchpadClearText = Notification.Name("scratchpadClearText")
```

- [ ] **Step 2: Rename observer storage**

Change:

```swift
private var appendObserver: NSObjectProtocol?
```

to:

```swift
private var insertObserver: NSObjectProtocol?
```

- [ ] **Step 3: Replace observer setup**

Replace the `.scratchpadAppendText` observer with `.scratchpadInsertText`.

Expected payload:

```swift
guard let content = note.userInfo?["content"] as? String else { return }
self.insertText(content, into: textView)
```

- [ ] **Step 4: Update cleanup**

Remove `appendObserver` cleanup and clean up `insertObserver`.

- [ ] **Step 5: Replace `insertCapture` helper**

Delete `insertCapture(prefix:content:into:)`.

Add:

```swift
private func insertText(_ content: String, into textView: NSTextView) {
    let selectedRange = textView.window?.firstResponder == textView
        ? textView.selectedRange()
        : NSRange(location: textView.string.utf16.count, length: 0)

    let range: NSRange
    if selectedRange.location == NSNotFound {
        range = NSRange(location: textView.string.utf16.count, length: 0)
    } else {
        range = selectedRange
    }

    if textView.shouldChangeText(in: range, replacementString: content) {
        textView.textStorage?.replaceCharacters(in: range, with: content)
        textView.setSelectedRange(NSRange(location: range.location + content.utf16.count, length: 0))
        textView.didChangeText()
        textView.breakUndoCoalescing()
    }
}
```

- [ ] **Step 6: Build**

Run:

```bash
swift build
```

Expected: build may still fail until Chunk 4 removes old UI references. If it fails, confirm failures are not in `PlainTextView.swift`.

## Chunk 4: Clip Shelf UI

### Task 4: Add Inline Drawer And Toolbar Clips Button

**Files:**

- Modify: `Sources/ClipboardScratchpad/ContentView.swift:3-150`

- [ ] **Step 1: Add drawer state**

In `ContentView`, add:

```swift
@State private var isShowingClips = false
```

- [ ] **Step 2: Add drawer above bottom toolbar**

After `Divider()` and before the bottom toolbar `HStack`, conditionally render:

```swift
if isShowingClips {
    ClipShelfDrawer(
        clips: store.clips,
        onInsert: { store.insertClip($0) },
        onClear: { store.clearClips() }
    )
    Divider()
}
```

- [ ] **Step 3: Remove capture toggle button**

Delete the button that references:

```swift
store.setCapturing(!store.isCapturing)
store.isCapturing
```

- [ ] **Step 4: Add Clips button**

Add a toolbar button before metadata:

```swift
Button {
    isShowingClips.toggle()
} label: {
    HStack(spacing: 5) {
        Image(systemName: "tray.full")
            .font(.body)
        if !store.clips.isEmpty {
            Text("\(min(store.clips.count, 50))")
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(Color.secondary.opacity(0.18)))
        }
    }
}
.buttonStyle(.plain)
.foregroundColor(isShowingClips ? .primary : .secondary)
.help("Clips")
.accessibilityLabel("Clips")
```

- [ ] **Step 5: Keep metadata blended**

Keep `ScratchpadMetaBar` in the bottom toolbar and keep it small/muted.

- [ ] **Step 6: Add `ClipShelfDrawer` view**

Add below `ScratchpadMetaBar`:

```swift
private struct ClipShelfDrawer: View {
    let clips: [ClipShelfItem]
    let onInsert: (ClipShelfItem) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clips")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Clear") {
                    onClear()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .disabled(clips.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            if clips.isEmpty {
                Text("No clips")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(clips) { clip in
                            ClipShelfRow(clip: clip) {
                                onInsert(clip)
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
    }
}
```

- [ ] **Step 7: Add `ClipShelfRow` view**

Add:

```swift
private struct ClipShelfRow: View {
    let clip: ClipShelfItem
    let onInsert: () -> Void

    var body: some View {
        Button(action: onInsert) {
            VStack(alignment: .leading, spacing: 4) {
                Text(clip.content)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(metadata)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var metadata: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let time = formatter.localizedString(for: clip.capturedAt, relativeTo: Date())
        if let sourceAppName = clip.sourceAppName, !sourceAppName.isEmpty {
            return "\(sourceAppName) · \(time)"
        }
        return time
    }
}
```

- [ ] **Step 8: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 9: Commit Chunks 2-4 together**

```bash
git add Sources/ClipboardScratchpad/ScratchpadStore.swift Sources/ClipboardScratchpad/PlainTextView.swift Sources/ClipboardScratchpad/ContentView.swift
git commit -m "feat: capture copied text into clip shelf"
```

## Chunk 5: Lifecycle And Verification

### Task 5: Stop Monitoring On Quit And Run Manual Checks

**Files:**

- Modify: `Sources/ClipboardScratchpad/AppDelegate.swift:3-10`

- [ ] **Step 1: Stop monitor on app termination**

Add:

```swift
func applicationWillTerminate(_ notification: Notification) {
    store.stopClipboardMonitoring()
}
```

- [ ] **Step 2: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 3: Run app**

Run:

```bash
swift run
```

Expected: app launches as a menu bar app. Stop any existing running instance first with `pkill -x ClipboardScratchpad || true` if needed.

- [ ] **Step 4: Manual verification**

Verify:

- Copying text from another app adds a row to Clips and does not change the note.
- Clips badge count increments.
- Clips button toggles the inline drawer.
- Clips button appears highlighted while open.
- Clicking a clip inserts at the current cursor.
- Selecting note text then clicking a clip replaces the selection.
- Clicking Copy All does not create a new clip.
- Clear note leaves clips intact.
- Clear Clips leaves note text intact.
- Quit and relaunch restores clips.
- Old saved state without `clips` loads with an empty shelf.

- [ ] **Step 5: Stop the run session**

Stop the app process:

```bash
pkill -x ClipboardScratchpad || true
```

Confirm no attached long-running `swift run` session remains.

- [ ] **Step 6: Commit lifecycle polish**

```bash
git add Sources/ClipboardScratchpad/AppDelegate.swift
git commit -m "chore: stop clipboard monitoring on quit"
```

## Final Checks

- [ ] **Step 1: Full build**

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 2: Diff hygiene**

```bash
git diff --check
git status --short
```

Expected: no whitespace errors. Status should only show expected uncommitted files, or be clean after commits.

- [ ] **Step 3: Review behavior against spec**

Compare implementation to:

```bash
sed -n '1,260p' docs/superpowers/specs/2026-05-05-clip-shelf-design.md
```

Expected: every manual verification item is covered.

## Notes For Implementer

- Do not add a unit test target for this feature.
- Do not add external packages.
- Do not reintroduce the capture toggle.
- Do not auto-append copied text to the note.
- Do not consume/remove clips when inserted.
- Keep drawer copy minimal; no instructional text in the app UI.
- Keep toolbar controls compact and native.
