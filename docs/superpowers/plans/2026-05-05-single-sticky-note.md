# Single Sticky Note Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the block-list clipboard scratchpad into a single editable plain-text sticky note with icon toolbar buttons.

**Architecture:** One `String` (`noteText`) backed by debounced autosave. Clipboard captures append with a `[HH:MM AM/PM · AppName]` prefix. Old block-based model is fully removed; legacy decode types exist only for one-time migration.

**Tech Stack:** Swift, SwiftUI (TextEditor), AppKit (menu bar popover), Swift Package Manager.

---

## File Structure

| File | Responsibility |
|------|----------------|
| `Sources/ClipboardScratchpad/StoreState.swift` | New `StoreState` struct and legacy decode types |
| `Sources/ClipboardScratchpad/ScratchpadStore.swift` | Rewritten: `noteText`, debounced save, migration, capture logic |
| `Sources/ClipboardScratchpad/ClipboardMonitor.swift` | Minor tweak: init `lastSeenChangeCount` on start |
| `Sources/ClipboardScratchpad/ContentView.swift` | Rewritten: single TextEditor + icon toolbar |
| `Sources/ClipboardScratchpad/Models.swift` | **Delete** — old ScratchBlock/ManualBlock/CapturedBlock |
| `Sources/ClipboardScratchpad/StatusBarController.swift` | No changes needed |
| `Sources/ClipboardScratchpad/AppDelegate.swift` | No changes needed |
| `Sources/ClipboardScratchpad/main.swift` | No changes needed |

---

## Chunk 1: Data Model + Legacy Migration Types

### Task 1: Create StoreState.swift

**Files:**
- Create: `Sources/ClipboardScratchpad/StoreState.swift`

- [ ] **Step 1: Write StoreState and legacy types**

```swift
import Foundation

struct StoreState: Codable {
    var noteText: String
}

// MARK: - Legacy migration types

enum LegacyScratchBlock: Codable {
    case manual(id: UUID, timestamp: Date, content: String)
    case captured(id: UUID, timestamp: Date, content: String, sourceApp: String?)
}
```

- [ ] **Step 2: Build to check for errors**

Run: `swift build`
Expected: Build succeeds (may warn about unused LegacyScratchBlock, that's fine).

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/StoreState.swift
git commit -m "feat: add StoreState and legacy migration types"
```

---

## Chunk 2: Rewrite ScratchpadStore

### Task 2: Rewrite ScratchpadStore.swift

**Files:**
- Modify: `Sources/ClipboardScratchpad/ScratchpadStore.swift` (full rewrite)

**Context:** The old store managed `[ScratchBlock]`, `appendManual`, `deleteBlock`, `convertToManual`, etc. The new store manages a single `noteText` string with debounced autosave.

**Key behaviors:**
- `isCapturing` is runtime-only, starts `false`
- `lastCapturedText` is runtime-only
- Manual edits debounce-save after 400ms
- Clipboard appends save immediately
- Max length: 100,000 chars
- Migration from old block store with backup

- [ ] **Step 1: Write the new ScratchpadStore**

```swift
import Foundation
import Combine

@MainActor
final class ScratchpadStore: ObservableObject {
    @Published var noteText: String = ""
    @Published var isCapturing: Bool = false
    @Published var persistenceWarning: String? = nil
    @Published var toolbarMessage: String? = nil

    private let maxLength = 100_000
    private let saveInterval: TimeInterval = 0.4
    private var saveCancellable: AnyCancellable?
    private var toolbarMessageCancellable: AnyCancellable?
    private var lastCapturedText: String? = nil
    private let clipboardMonitor = ClipboardMonitor()
    private let storeURL: URL
    private let backupURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClipboardScratchpad", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storeURL = dir.appendingPathComponent("store.json")
        self.backupURL = dir.appendingPathComponent("store.blocks.backup.json")
        load()
    }

    // MARK: - Capture

    func setCapturing(_ capturing: Bool) {
        isCapturing = capturing
        if capturing {
            clipboardMonitor.start { [weak self] content, name, bundleID in
                self?.handleCapture(content: content, appName: name)
            }
        } else {
            clipboardMonitor.stop()
        }
    }

    private func handleCapture(content: String, appName: String?) {
        let normalized = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        guard normalized != lastCapturedText else { return }

        if noteText.count >= maxLength {
            showToolbarMessage("Note is full.")
            return
        }

        let prefix: String
        if let appName = appName, !appName.isEmpty {
            prefix = "[\(formattedTime()) · \(appName)]"
        } else {
            prefix = "[\(formattedTime())]"
        }

        var newText = noteText
        // Remove only trailing newlines, not spaces/tabs
        while newText.hasSuffix("\n") {
            newText.removeLast()
        }
        if !newText.isEmpty {
            newText += "\n\n"
        }
        newText += prefix + "\n" + content

        noteText = newText
        lastCapturedText = normalized
        saveImmediately()
    }

    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    // MARK: - Pasteboard

    func copyAll() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(noteText, forType: .string)
        clipboardMonitor.noteExternalPasteboardWrite()
    }

    func clear() {
        noteText = ""
        lastCapturedText = nil
        saveImmediately()
    }

    // MARK: - Autosave

    func scheduleSave() {
        saveCancellable?.cancel()
        saveCancellable = Just(())
            .delay(for: .seconds(saveInterval), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveImmediately()
            }
    }

    private func saveImmediately() {
        saveCancellable?.cancel()
        let state = StoreState(noteText: noteText)
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: storeURL)
            persistenceWarning = nil
        } catch {
            persistenceWarning = "Couldn’t save changes. Content will remain until the app quits."
        }
    }

    // MARK: - Load / Migration

    private func load() {
        // Try new format first
        if let data = try? Data(contentsOf: storeURL) {
            if let state = try? JSONDecoder().decode(StoreState.self, from: data) {
                noteText = state.noteText
                return
            }
            // Try old format
            if let legacy = try? JSONDecoder().decode([LegacyScratchBlock].self, from: data) {
                migrate(legacyBlocks: legacy)
                return
            }
        }
        noteText = ""
    }

    private func migrate(legacyBlocks: [LegacyScratchBlock]) {
        var parts: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        for block in legacyBlocks {
            switch block {
            case .manual(_, _, let content):
                parts.append(content)
            case .captured(_, let timestamp, let content, let sourceApp):
                let time = formatter.string(from: timestamp)
                if let app = sourceApp, !app.isEmpty {
                    parts.append("[\(time) · \(app)]\n\(content)")
                } else {
                    parts.append("[\(time)]\n\(content)")
                }
            }
        }

        noteText = parts.joined(separator: "\n\n")

        // Backup old file
        if let data = try? Data(contentsOf: storeURL) {
            try? data.write(to: backupURL)
        }

        saveImmediately()
    }

    // MARK: - Toolbar message

    private func showToolbarMessage(_ message: String) {
        toolbarMessage = message
        toolbarMessageCancellable?.cancel()
        toolbarMessageCancellable = Just(())
            .delay(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.toolbarMessage = nil
            }
    }
}
```

- [ ] **Step 2: Build to check for errors**

Run: `swift build`
Expected: Build succeeds. May warn about `clipboardMonitor.noteExternalPasteboardWrite()` if ClipboardMonitor doesn't have it yet — that's OK, we'll fix in next chunk.

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/ScratchpadStore.swift
git commit -m "feat: rewrite ScratchpadStore for single sticky note"
```

---

## Chunk 3: ClipboardMonitor Tweaks

### Task 3: Update ClipboardMonitor

**Files:**
- Modify: `Sources/ClipboardScratchpad/ClipboardMonitor.swift`

**Changes needed:**
- Add `initializeChangeCount()` method that sets `lastChangeCount = NSPasteboard.general.changeCount` before polling starts
- Call it inside `start()` before creating the timer

- [ ] **Step 1: Modify ClipboardMonitor.start**

```swift
func start(onCapture: @escaping (String, String?, String?) -> Void) {
    self.onCapture = onCapture
    lastChangeCount = NSPasteboard.general.changeCount
    timer?.invalidate()
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
        self?.check()
    }
}
```

The existing `noteExternalPasteboardWrite()` method already exists and is correct.

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/ClipboardMonitor.swift
git commit -m "fix: initialize changeCount when capture starts"
```

---

## Chunk 4: Rewrite ContentView

### Task 4: Rewrite ContentView.swift

**Files:**
- Modify: `Sources/ClipboardScratchpad/ContentView.swift` (full rewrite)

**Context:** Replace list-of-blocks UI with single TextEditor + icon toolbar.

- [ ] **Step 1: Write new ContentView**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ScratchpadStore
    @State private var showingClearAlert = false

    var body: some View {
        VStack(spacing: 0) {
            if let warning = store.persistenceWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
            }

            TextEditor(text: $store.noteText)
                .font(.body)
                .padding(4)
                .onChange(of: store.noteText) { _, _ in
                    store.scheduleSave()
                }

            Divider()

            HStack(spacing: 16) {
                Button {
                    store.setCapturing(!store.isCapturing)
                } label: {
                    Image(systemName: store.isCapturing ? "pause.fill" : "play.fill")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help(store.isCapturing ? "Pause Capturing" : "Start Capturing")
                .accessibilityLabel(store.isCapturing ? "Pause Capturing" : "Start Capturing")

                Button {
                    store.copyAll()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Copy All")
                .accessibilityLabel("Copy All")
                .disabled(store.noteText.isEmpty)

                Button {
                    if !store.noteText.isEmpty {
                        showingClearAlert = true
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Clear")
                .accessibilityLabel("Clear")
                .disabled(store.noteText.isEmpty)
            }
            .padding(.vertical, 8)

            if let message = store.toolbarMessage {
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }
        }
        .alert("Clear Scratchpad?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                store.clear()
            }
        } message: {
            Text("This will remove all content. This cannot be undone.")
        }
    }
}
```

- [ ] **Step 2: Build to check for errors**

Run: `swift build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/ContentView.swift
git commit -m "feat: rewrite ContentView as single sticky note with icon toolbar"
```

---

## Chunk 5: Delete Old Model and Views

### Task 5: Delete Models.swift

**Files:**
- Delete: `Sources/ClipboardScratchpad/Models.swift`

- [ ] **Step 1: Delete the file**

```bash
rm Sources/ClipboardScratchpad/Models.swift
```

- [ ] **Step 2: Build to verify nothing references old types**

Run: `swift build`
Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore: remove old ScratchBlock model and Manual/Captured block types"
```

---

## Chunk 6: Manual Testing

### Task 6: Build and Run

- [ ] **Step 1: Build**

Run: `swift build`
Expected: Clean build, no errors.

- [ ] **Step 2: Run the app**

Run: `swift run`
Expected: App launches in menu bar. Click icon → popover opens with empty TextEditor.

- [ ] **Step 3: Test scenarios**

1. Type into editor → close popover → reopen → text persists.
2. Click play icon → copy text from Safari → it appears in note with timestamp prefix.
3. Click pause icon → copy text → nothing appends.
4. Click Copy All icon → paste somewhere → entire note text is pasted.
5. Click Clear icon → confirm → note is empty.
6. Type until note exceeds 100,000 chars → try to capture → "Note is full" appears.

- [ ] **Step 4: Commit**

```bash
git commit --allow-empty -m "test: manual testing passed"
```
