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
