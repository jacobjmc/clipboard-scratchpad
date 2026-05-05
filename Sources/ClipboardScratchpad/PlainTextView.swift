import SwiftUI
import AppKit

extension Notification.Name {
    static let scratchpadPopoverDidShow = Notification.Name("scratchpadPopoverDidShow")
    static let scratchpadAppendText = Notification.Name("scratchpadAppendText")
    static let scratchpadClearText = Notification.Name("scratchpadClearText")
}

struct PlainTextView: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.autoresizingMask = [.width, .height]

        let textView = PlainTextNSTextView()
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.autoresizingMask = [.width, .height]
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        context.coordinator.textView = textView

        textView.string = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? PlainTextNSTextView else { return }

        if context.coordinator.isProgrammaticChange {
            context.coordinator.isProgrammaticChange = false
            return
        }

        if textView.string != text {
            textView.undoManager?.disableUndoRegistration()
            textView.string = text
            textView.undoManager?.enableUndoRegistration()
            textView.undoManager?.removeAllActions()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextView
        weak var textView: NSTextView?
        private let textUndoManager = UndoManager()
        private var focusObserver: NSObjectProtocol?
        private var appendObserver: NSObjectProtocol?
        private var clearObserver: NSObjectProtocol?
        var isProgrammaticChange = false

        init(_ parent: PlainTextView) {
            self.parent = parent
            super.init()
            textUndoManager.levelsOfUndo = 100

            focusObserver = NotificationCenter.default.addObserver(
                forName: .scratchpadPopoverDidShow,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let textView = self?.textView else { return }
                DispatchQueue.main.async {
                    textView.window?.makeFirstResponder(textView)
                }
            }

            appendObserver = NotificationCenter.default.addObserver(
                forName: .scratchpadAppendText,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let self = self, let textView = self.textView else { return }
                guard let prefix = note.userInfo?["prefix"] as? String,
                      let content = note.userInfo?["content"] as? String else { return }
                self.insertCapture(prefix: prefix, content: content, into: textView)
            }

            clearObserver = NotificationCenter.default.addObserver(
                forName: .scratchpadClearText,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self = self, let textView = self.textView else { return }
                self.clearText(in: textView)
            }
        }

        deinit {
            if let observer = focusObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = appendObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = clearObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func undoManager(for view: NSTextView) -> UndoManager? {
            textUndoManager
        }

        func textDidChange(_ notification: Notification) {
            isProgrammaticChange = false
            guard let textView = textView else { return }
            parent.text = textView.string
            parent.onTextChange()
        }

        private func insertCapture(prefix: String, content: String, into textView: NSTextView) {
            isProgrammaticChange = true

            let current = textView.string
            var trimmed = current
            while trimmed.hasSuffix("\n") {
                trimmed.removeLast()
            }

            let insertText: String
            if trimmed.isEmpty {
                insertText = prefix + "\n" + content
            } else {
                insertText = "\n\n" + prefix + "\n" + content
            }

            let end = trimmed.utf16.count
            let range = NSRange(location: end, length: 0)

            if textView.shouldChangeText(in: range, replacementString: insertText) {
                textView.textStorage?.replaceCharacters(in: range, with: insertText)
                textView.didChangeText()
                textView.breakUndoCoalescing()
            }
        }

        private func clearText(in textView: NSTextView) {
            isProgrammaticChange = true

            let fullRange = NSRange(location: 0, length: textView.string.utf16.count)

            if textView.shouldChangeText(in: fullRange, replacementString: "") {
                textView.textStorage?.replaceCharacters(in: fullRange, with: "")
                textView.didChangeText()
                textView.breakUndoCoalescing()
            }
        }
    }
}

final class PlainTextNSTextView: NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command),
           let chars = event.charactersIgnoringModifiers {
            switch chars.lowercased() {
            case "a":
                selectAll(nil)
                return true
            case "c":
                copy(nil)
                return true
            case "v":
                paste(nil)
                breakUndoCoalescing()
                return true
            case "x":
                cut(nil)
                breakUndoCoalescing()
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
