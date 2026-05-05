# Clipboard Scratchpad — Minimal Slice Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar popover app that captures copied text into editable blocks with local JSON persistence.

**Architecture:** AppKit shell (NSStatusItem + NSPopover) hosts a SwiftUI list of blocks backed by a single `ScratchpadStore`. A `ClipboardMonitor` polls NSPasteboard every 0.5s when capture is active. All data models are a single `ScratchBlock` enum with no protocol existentials.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, Combine, no external dependencies.

**Reference spec:** `docs/superpowers/specs/2026-05-05-clipboard-scratchpad-minimal-design.md`

---

## File Structure

| File | Responsibility |
|------|--------------|
| `Package.swift` | Swift Package manifest, macOS 14+ target |
| `Sources/ClipboardScratchpad/main.swift` | Entry point: create NSApplication and AppDelegate |
| `Sources/ClipboardScratchpad/AppDelegate.swift` | NSApplicationDelegate, owns Store + StatusBarController |
| `Sources/ClipboardScratchpad/Models.swift` | `ScratchBlock`, `ManualBlock`, `CapturedBlock` |
| `Sources/ClipboardScratchpad/ScratchpadStore.swift` | ObservableObject: blocks, persistence, validation, dedup, pasteboard writes |
| `Sources/ClipboardScratchpad/ClipboardMonitor.swift` | Polls NSPasteboard, invokes onCapture, suppresses self-capture |
| `Sources/ClipboardScratchpad/StatusBarController.swift` | NSStatusItem + NSPopover shell, click-to-toggle, outside-click dismissal |
| `Sources/ClipboardScratchpad/ContentView.swift` | SwiftUI: block list, input bar, action buttons, alerts |

---

## Chunk 1: Project Scaffold + Data Model

### Task 1: Create Swift Package

**Files:**
- Create: `Package.swift`

- [ ] **Step 1: Write Package.swift**

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClipboardScratchpad",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ClipboardScratchpad", targets: ["ClipboardScratchpad"])
    ],
    targets: [
        .executableTarget(name: "ClipboardScratchpad")
    ]
)
```

- [ ] **Step 2: Create source directories**

Run: `mkdir -p Sources/ClipboardScratchpad`

- [ ] **Step 3: Verify package parses**

Run: `swift package describe`
Expected: Prints package name, targets, products without errors.

- [ ] **Step 4: Commit**

```bash
git add Package.swift
git commit -m "chore: scaffold Swift package"
```

### Task 2: Write Data Model

**Files:**
- Create: `Sources/ClipboardScratchpad/Models.swift`

- [ ] **Step 1: Write Models.swift**

```swift
import Foundation

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

enum ScratchBlock: Identifiable, Codable, Equatable {
    case manual(ManualBlock)
    case captured(CapturedBlock)

    var id: UUID {
        switch self {
        case .manual(let block): return block.id
        case .captured(let block): return block.id
        }
    }

    var content: String {
        switch self {
        case .manual(let block): return block.content
        case .captured(let block): return block.content
        }
    }

    var timestamp: Date {
        switch self {
        case .manual(let block): return block.timestamp
        case .captured(let block): return block.timestamp
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/Models.swift
git commit -m "feat: add ScratchBlock data model"
```

---

## Chunk 2: Store + Monitor

### Task 3: Write ClipboardMonitor

**Files:**
- Create: `Sources/ClipboardScratchpad/ClipboardMonitor.swift`

- [ ] **Step 1: Write ClipboardMonitor.swift**

```swift
import AppKit

final class ClipboardMonitor {
    private var timer: Timer?
    private var lastChangeCount = 0
    private var onCapture: ((String, String?, String?) -> Void)?

    func start(onCapture: @escaping (String, String?, String?) -> Void) {
        self.onCapture = onCapture
        lastChangeCount = NSPasteboard.general.changeCount
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.check()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        onCapture = nil
    }

    func noteExternalPasteboardWrite() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func check() {
        let pasteboard = NSPasteboard.general
        let currentCount = pasteboard.changeCount
        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if let frontmost = NSWorkspace.shared.frontmostApplication,
           frontmost.bundleIdentifier == Bundle.main.bundleIdentifier {
            return
        }

        guard let string = pasteboard.string(forType: .string) else { return }

        let app = NSWorkspace.shared.frontmostApplication
        onCapture?(string, app?.localizedName, app?.bundleIdentifier)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/ClipboardMonitor.swift
git commit -m "feat: add clipboard monitor with polling and self-capture suppression"
```

### Task 4: Write ScratchpadStore

**Files:**
- Create: `Sources/ClipboardScratchpad/ScratchpadStore.swift`

- [ ] **Step 1: Write ScratchpadStore.swift**

```swift
import Foundation
import Combine
import AppKit
import os.log

final class ScratchpadStore: ObservableObject {
    @Published private(set) var blocks: [ScratchBlock] = []
    @Published var isCapturing: Bool = false {
        didSet { updateCaptureState() }
    }
    @Published var persistenceWarning: String? = nil

    private let storeURL: URL
    private let maxBlocks = 500
    private let maxContentLength = 10000
    private let logger = Logger(subsystem: "com.clipboardscratchpad", category: "Store")
    private lazy var clipboardMonitor = ClipboardMonitor()

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClipboardScratchpad", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storeURL = dir.appendingPathComponent("store.json")
        load()
    }

    func appendManual(content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let final = String(trimmed.prefix(maxContentLength)) + (trimmed.count > maxContentLength ? "…" : "")
        let block = ScratchBlock.manual(ManualBlock(id: UUID(), timestamp: Date(), content: final))
        blocks.append(block)
        save()
    }

    func appendCapture(content: String, sourceAppName: String?, sourceBundleID: String?) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let lastCaptured = blocks.last(where: {
            if case .captured = $0 { return true }
            return false
        }), lastCaptured.content.trimmingCharacters(in: .whitespacesAndNewlines) == trimmed {
            return
        }
        if blocks.count >= maxBlocks {
            persistenceWarning = "Maximum block count reached. Capture paused."
            isCapturing = false
            return
        }
        let final = String(trimmed.prefix(maxContentLength)) + (trimmed.count > maxContentLength ? "…" : "")
        let block = ScratchBlock.captured(CapturedBlock(
            id: UUID(),
            timestamp: Date(),
            content: final,
            sourceAppName: sourceAppName,
            sourceBundleID: sourceBundleID
        ))
        blocks.append(block)
        save()
    }

    func deleteBlock(id: UUID) {
        blocks.removeAll { $0.id == id }
        save()
    }

    func convertToManual(id: UUID) {
        guard let index = blocks.firstIndex(where: { $0.id == id }) else { return }
        switch blocks[index] {
        case .captured(let captured):
            let manual = ScratchBlock.manual(ManualBlock(
                id: captured.id,
                timestamp: captured.timestamp,
                content: captured.content
            ))
            blocks[index] = manual
            save()
        default:
            break
        }
    }

    func copyAll() -> String {
        blocks.map(\.content).joined(separator: "\n\n")
    }

    func clear() {
        blocks.removeAll()
        save()
    }

    func writeToPasteboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        clipboardMonitor.noteExternalPasteboardWrite()
    }

    private func updateCaptureState() {
        if isCapturing {
            clipboardMonitor.start { [weak self] content, name, bundleID in
                self?.appendCapture(content: content, sourceAppName: name, sourceBundleID: bundleID)
            }
        } else {
            clipboardMonitor.stop()
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        do {
            blocks = try JSONDecoder().decode([ScratchBlock].self, from: data)
        } catch {
            logger.error("Failed to load store: \\(error.localizedDescription)")
            persistenceWarning = "Couldn’t load previous scratchpad. Starting fresh."
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(blocks)
            try data.write(to: storeURL)
            persistenceWarning = nil
        } catch {
            logger.error("Failed to save store: \\(error.localizedDescription)")
            persistenceWarning = "Couldn’t save changes. Content will remain until the app quits."
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/ScratchpadStore.swift
git commit -m "feat: add scratchpad store with persistence, validation, dedup"
```

---

## Chunk 3: AppKit Shell + SwiftUI Views

### Task 5: Write StatusBarController

**Files:**
- Create: `Sources/ClipboardScratchpad/StatusBarController.swift`

- [ ] **Step 1: Write StatusBarController.swift**

```swift
import AppKit
import SwiftUI

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var eventMonitor: EventMonitor?

    init(store: ScratchpadStore) {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(store)
        )

        statusItem = NSStatusBar.shared.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Scratchpad")
            button.action = #selector(togglePopover)
            button.target = self
        }

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.popover.isShown else { return }
            self.closePopover(event)
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            eventMonitor?.start()
        }
    }

    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
}

final class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/StatusBarController.swift
git commit -m "feat: add status bar controller with popover and outside-click dismissal"
```

### Task 6: Write ContentView

**Files:**
- Create: `Sources/ClipboardScratchpad/ContentView.swift`

- [ ] **Step 1: Write ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ScratchpadStore
    @State private var inputText = ""
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

            if store.blocks.isEmpty {
                Spacer()
                Text("Start typing or turn on capture to collect clips.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(store.blocks) { block in
                                BlockRow(block: block)
                                    .id(block.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: store.blocks.count) { _ in
                        if let last = store.blocks.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Divider()

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextEditor(text: $inputText)
                        .font(.body)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                    Button("Add Note") {
                        submitManual()
                    }
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                HStack(spacing: 12) {
                    Button(store.isCapturing ? "Pause Capture" : "Start Capture") {
                        store.isCapturing.toggle()
                    }

                    Button("Copy All") {
                        let text = store.copyAll()
                        store.writeToPasteboard(text)
                    }
                    .disabled(store.blocks.isEmpty)

                    Button("Clear") {
                        if !store.blocks.isEmpty {
                            showingClearAlert = true
                        }
                    }
                    .disabled(store.blocks.isEmpty)
                }
            }
            .padding()

            Text("Captured text stays on this Mac.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        
        .alert("Clear Scratchpad?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                store.clear()
            }
        } message: {
            Text("This will remove all blocks. This cannot be undone.")
        }
        .onKeyPress(.return, modifiers: .command) {
            submitManual()
            return .handled
        }
    }

    private func submitManual() {
        store.appendManual(content: inputText)
        inputText = ""
    }
}

struct BlockRow: View {
    let block: ScratchBlock

    var body: some View {
        switch block {
        case .manual(let manual):
            ManualBlockRow(block: manual)
        case .captured(let captured):
            CapturedBlockRow(block: captured)
        }
    }
}

struct ManualBlockRow: View {
    let block: ManualBlock
    @EnvironmentObject var store: ScratchpadStore

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(block.content)
                .font(.body)
                .textSelection(.enabled)
            Spacer()
            Button {
                store.deleteBlock(id: block.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
    }
}

struct CapturedBlockRow: View {
    let block: CapturedBlock
    @EnvironmentObject var store: ScratchpadStore

    private var metadataText: String {
        let time = block.timestamp.formatted(date: .omitted, time: .shortened)
        if let app = block.sourceAppName {
            return "\(app) · \(time)"
        }
        return time
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.content)
                .font(.body)
                .textSelection(.enabled)

            Text(metadataText)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("Copy") {
                    store.writeToPasteboard(block.content)
                }
                Button("Convert") {
                    store.convertToManual(id: block.id)
                }
                Button("Delete") {
                    store.deleteBlock(id: block.id)
                }
            }
            .font(.caption)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}
```

- [ ] **Step 2: Build to verify**

Run: `swift build`
Expected: Compiles without errors.

- [ ] **Step 3: Commit**

```bash
git add Sources/ClipboardScratchpad/ContentView.swift
git commit -m "feat: add SwiftUI content view with block list, input, and actions"
```

---

## Chunk 4: Entry Point + Integration

### Task 7: Write AppDelegate + main

**Files:**
- Create: `Sources/ClipboardScratchpad/AppDelegate.swift`
- Create: `Sources/ClipboardScratchpad/main.swift`

- [ ] **Step 1: Write AppDelegate.swift**

```swift
import AppKit

@main
final class ClipboardScratchpadApp: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    let store = ScratchpadStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(store: store)
    }
}
```

Wait — `@main` with `NSApplicationDelegate` needs a different pattern. On macOS, the `@main` entry point for AppKit apps should use `NSApplicationMain` or a custom main. Let me fix this.

Actually, for a Swift Package executable on macOS, the cleanest pattern is:

`main.swift`:
```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

`AppDelegate.swift`:
```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    let store = ScratchpadStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(store: store)
    }
}
```

- [ ] **Step 1: Write main.swift**

```swift
import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
```

- [ ] **Step 2: Write AppDelegate.swift**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    let store = ScratchpadStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(store: store)
    }
}
```

- [ ] **Step 3: Build to verify**

Run: `swift build`
Expected: Compiles without errors.

- [ ] **Step 4: Commit**

```bash
git add Sources/ClipboardScratchpad/main.swift Sources/ClipboardScratchpad/AppDelegate.swift
git commit -m "feat: add app delegate and entry point"
```

### Task 8: Integration Test

- [ ] **Step 1: Run the app**

Run: `swift run`
Expected: App starts, a clipboard icon appears in the menu bar. Clicking it opens the popover.

- [ ] **Step 2: Manual test checklist**

1. Click menu bar icon → popover opens
2. Type text in input, click "Add Note" → block appears
3. Toggle "Start Capture" → icon changes to "Pause Capture"
4. Copy text from another app → captured block appears in list
5. Click "Copy All" → pasteboard contains concatenated text
6. Click "Clear" → alert appears, confirm → list empties
7. Quit app, relaunch → previous blocks restored from JSON
8. Click outside popover → popover closes

- [ ] **Step 3: Commit if all tests pass**

```bash
git add -A
git commit -m "feat: minimal slice complete — menu bar scratchpad with capture, persistence, and block actions"
```

---

## Plan Review

After completing the plan, dispatch the plan-document-reviewer subagent with:
- Plan file path
- Spec file path
- Focus areas: completeness of code snippets, build commands, file paths, testability
