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
            logger.error("Failed to load store: \(error.localizedDescription)")
            persistenceWarning = "Couldn’t load previous scratchpad. Starting fresh."
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(blocks)
            try data.write(to: storeURL)
            persistenceWarning = nil
        } catch {
            logger.error("Failed to save store: \(error.localizedDescription)")
            persistenceWarning = "Couldn’t save changes. Content will remain until the app quits."
        }
    }
}
