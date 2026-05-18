import Foundation
import Combine
import AppKit
import ApplicationServices
import UniformTypeIdentifiers
import ClipboardScratchpadLib

final class ScratchpadStore: ObservableObject {
    @Published var noteText: String = ""
    @Published var clips: [ClipShelfItem] = []
    @Published var persistenceWarning: String? = nil
    @Published var clipFeedback: (clipID: UUID, message: String)? = nil
    @Published var updatedAt: Date? = nil
    @Published var windowFrame: CGRect? = nil {
        didSet {
            if windowFrame != oldValue {
                scheduleSave()
            }
        }
    }
    @Published var globalShortcut: GlobalKeyboardShortcut? = nil
    @Published var globalShortcutUnavailable: Bool = false
    @Published var appearancePreference: AppearancePreference = .system {
        didSet {
            guard appearancePreference != oldValue else { return }
            applyAppearancePreference()
            saveImmediately()
        }
    }
    @Published var paperFinishEnabled: Bool = true {
        didSet {
            guard paperFinishEnabled != oldValue else { return }
            saveImmediately()
        }
    }
    @Published var customNoteBackgroundImagePath: String? = nil {
        didSet {
            guard customNoteBackgroundImagePath != oldValue else { return }
            saveImmediately()
        }
    }
    @Published var isAccessibilityTrusted: Bool = AXIsProcessTrusted()
    @Published var isPinned: Bool = false {
        didSet {
            if isPinned != oldValue {
                NotificationCenter.default.post(name: .scratchpadPinChanged, object: isPinned)
            }
        }
    }

    private let maxLength = 100_000
    private let maxClips = 50
    private let saveInterval: TimeInterval = 0.4
    private var saveWorkItem: DispatchWorkItem?
    private var clipFeedbackWorkItem: DispatchWorkItem?
    private var lastCapturedClipText: String? = nil
    private var lastExternalApplication: NSRunningApplication?
    private let clipboardMonitor = ClipboardMonitor()
    private let storeURL: URL
    private let backupURL: URL
    private let backgroundsDirectoryURL: URL

    var previousExternalAppName: String? {
        guard let application = lastExternalApplication, !application.isTerminated else { return nil }
        return application.localizedName
    }

    var previousExternalAppIcon: NSImage? {
        guard let application = lastExternalApplication, !application.isTerminated else { return nil }
        return application.icon
    }

    var hasPreviousExternalApplication: Bool {
        guard let application = lastExternalApplication else { return false }
        return !application.isTerminated
    }

    var customNoteBackgroundImageURL: URL? {
        guard let customNoteBackgroundImagePath else { return nil }
        return URL(fileURLWithPath: customNoteBackgroundImagePath)
    }

    var customNoteBackgroundDisplayName: String? {
        customNoteBackgroundImageURL?.lastPathComponent
    }

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ClipboardScratchpad", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storeURL = dir.appendingPathComponent("store.json")
        self.backupURL = dir.appendingPathComponent("store.blocks.backup.json")
        self.backgroundsDirectoryURL = dir.appendingPathComponent("Backgrounds", isDirectory: true)
        load()
        applyAppearancePreference()
        startClipboardMonitoring()
    }

    // MARK: - Clipboard capture

    private func startClipboardMonitoring() {
        clipboardMonitor.start { [weak self] content, name, bundleID in
            DispatchQueue.main.async {
                self?.captureClipboardText(content, sourceAppName: name, sourceBundleID: bundleID)
            }
        }
    }

    func stopClipboardMonitoring() {
        clipboardMonitor.stop()
    }

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

    func insertClip(_ clip: ClipShelfItem) {
        NotificationCenter.default.post(
            name: .scratchpadInsertText,
            object: nil,
            userInfo: ["content": clip.content]
        )
    }

    func copyClip(_ clip: ClipShelfItem) {
        writeToPasteboard(clip.content)
        showClipFeedback("Copied", for: clip)
    }

    func pasteClipToPreviousApp(_ clip: ClipShelfItem) {
        writeToPasteboard(clip.content)
        showClipFeedback("Copied", for: clip)

        guard AXIsProcessTrusted(),
              let application = lastExternalApplication,
              !application.isTerminated,
              application.activate() else {
            return
        }

        let processIdentifier = application.processIdentifier
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.sendPasteShortcut(to: processIdentifier)
        }
    }

    func recordExternalApplication(_ application: NSRunningApplication) {
        guard application.bundleIdentifier != Bundle.main.bundleIdentifier else { return }
        lastExternalApplication = application
    }

    func deleteClip(_ clip: ClipShelfItem) {
        clips.removeAll { $0.id == clip.id }
        lastCapturedClipText = clips.first?.content.trimmingCharacters(in: .whitespacesAndNewlines)
        saveImmediately()
    }

    func refreshAccessibilityStatus() {
        isAccessibilityTrusted = AXIsProcessTrusted()
    }

    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        isAccessibilityTrusted = AXIsProcessTrustedWithOptions(options)
    }

    func clearClips() {
        clips = []
        lastCapturedClipText = nil
        saveImmediately()
    }

    // MARK: - Pasteboard

    func copyAll() {
        writeToPasteboard(noteText)
    }

    func clear() {
        noteText = ""
        updatedAt = Date()
        saveImmediately()

        NotificationCenter.default.post(name: .scratchpadClearText, object: nil)
    }

    func noteDidChange() {
        updatedAt = Date()
        scheduleSave()
    }

    func chooseCustomNoteBackground() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.resolvesAliases = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        setCustomNoteBackground(from: url)
    }

    func setCustomNoteBackground(from sourceURL: URL) {
        guard let image = NSImage(contentsOf: sourceURL),
              let jpegData = normalizedBackgroundJPEGData(from: image) else {
            persistenceWarning = "Couldn’t use that image as a background."
            return
        }

        do {
            try FileManager.default.createDirectory(at: backgroundsDirectoryURL, withIntermediateDirectories: true)
            let previousBackgroundURL = customNoteBackgroundImageURL
            let backgroundURL = backgroundsDirectoryURL.appendingPathComponent("note-background-\(UUID().uuidString).jpg")
            try jpegData.write(to: backgroundURL, options: .atomic)
            paperFinishEnabled = false
            customNoteBackgroundImagePath = backgroundURL.path
            if let previousBackgroundURL, previousBackgroundURL != backgroundURL {
                try? FileManager.default.removeItem(at: previousBackgroundURL)
            }
            persistenceWarning = nil
        } catch {
            persistenceWarning = "Couldn’t save the background image."
        }
    }

    func removeCustomNoteBackground() {
        if let url = customNoteBackgroundImageURL {
            try? FileManager.default.removeItem(at: url)
        }
        customNoteBackgroundImagePath = nil
    }

    // MARK: - Autosave

    func scheduleSave() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveImmediately()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + saveInterval, execute: workItem)
    }

    private func saveImmediately() {
        saveWorkItem?.cancel()
        let state = StoreState(
            noteText: noteText,
            updatedAt: updatedAt,
            clips: clips,
            windowFrame: windowFrame,
            globalShortcut: globalShortcut,
            appearancePreference: appearancePreference,
            paperFinishEnabled: paperFinishEnabled,
            customNoteBackgroundImagePath: customNoteBackgroundImagePath
        )
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
                updatedAt = state.updatedAt
                clips = state.clips
                windowFrame = state.windowFrame
                globalShortcut = state.globalShortcut
                appearancePreference = state.appearancePreference
                paperFinishEnabled = state.paperFinishEnabled
                customNoteBackgroundImagePath = state.customNoteBackgroundImagePath
                lastCapturedClipText = state.clips.first?.content.trimmingCharacters(in: .whitespacesAndNewlines)
                return
            }
            // Try old format
            if let legacy = try? JSONDecoder().decode([LegacyScratchBlock].self, from: data) {
                migrate(legacyBlocks: legacy)
                return
            }
        }
        noteText = ""
        clips = []
    }

    private func applyAppearancePreference() {
        NSApp.appearance = appearancePreference.nsAppearance
    }

    func globalShortcutDidRegister(_ shortcut: GlobalKeyboardShortcut) {
        globalShortcut = shortcut
        globalShortcutUnavailable = false
        saveImmediately()
    }

    func globalShortcutDidFail() {
        globalShortcutUnavailable = true
    }

    func globalShortcutDidClear() {
        globalShortcut = nil
        globalShortcutUnavailable = false
        saveImmediately()
    }

    private func migrate(legacyBlocks: [LegacyScratchBlock]) {
        var parts: [String] = []
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        for block in legacyBlocks {
            switch block {
            case .manual(let manual):
                parts.append(manual.content)
            case .captured(let captured):
                let time = formatter.string(from: captured.timestamp)
                if let app = captured.sourceAppName, !app.isEmpty {
                    parts.append("[\(time) · \(app)]\n\(captured.content)")
                } else {
                    parts.append("[\(time)]\n\(captured.content)")
                }
            }
        }

        noteText = parts.joined(separator: "\n\n")
        updatedAt = Date()
        clips = []

        // Backup old file
        if let data = try? Data(contentsOf: storeURL) {
            try? data.write(to: backupURL)
        }

        saveImmediately()
    }

    // MARK: - Clip feedback

    private func showClipFeedback(_ message: String, for clip: ClipShelfItem) {
        clipFeedback = (clip.id, message)
        clipFeedbackWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard self?.clipFeedback?.clipID == clip.id else { return }
            self?.clipFeedback = nil
        }
        clipFeedbackWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4, execute: workItem)
    }

    private func writeToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        clipboardMonitor.noteExternalPasteboardWrite()
    }

    private func sendPasteShortcut(to processIdentifier: pid_t) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.postToPid(processIdentifier)
        keyUp?.postToPid(processIdentifier)
    }

    private func normalizedBackgroundJPEGData(from image: NSImage) -> Data? {
        let maxLongEdge: CGFloat = 2400
        let originalSize = image.size
        guard originalSize.width > 0, originalSize.height > 0 else { return nil }

        let scale = min(1, maxLongEdge / max(originalSize.width, originalSize.height))
        let targetSize = NSSize(
            width: max(1, floor(originalSize.width * scale)),
            height: max(1, floor(originalSize.height * scale))
        )

        let outputImage = NSImage(size: targetSize)
        outputImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: originalSize),
            operation: .copy,
            fraction: 1
        )
        outputImage.unlockFocus()

        guard let tiffData = outputImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.86])
    }
}
