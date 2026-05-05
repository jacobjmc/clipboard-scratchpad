import Foundation
import Combine
import AppKit

final class ScratchpadStore: ObservableObject {
    @Published var noteText: String = ""
    @Published var isCapturing: Bool = false
    @Published var persistenceWarning: String? = nil
    @Published var toolbarMessage: String? = nil

    private let maxLength = 100_000
    private let saveInterval: TimeInterval = 0.4
    private var saveWorkItem: DispatchWorkItem?
    private var toolbarMessageWorkItem: DispatchWorkItem?
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
                DispatchQueue.main.async {
                    self?.handleCapture(content: content, appName: name)
                }
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
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.saveImmediately()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + saveInterval, execute: workItem)
    }

    private func saveImmediately() {
        saveWorkItem?.cancel()
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

        // Backup old file
        if let data = try? Data(contentsOf: storeURL) {
            try? data.write(to: backupURL)
        }

        saveImmediately()
    }

    // MARK: - Toolbar message

    private func showToolbarMessage(_ message: String) {
        toolbarMessage = message
        toolbarMessageWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.toolbarMessage = nil
        }
        toolbarMessageWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }
}
