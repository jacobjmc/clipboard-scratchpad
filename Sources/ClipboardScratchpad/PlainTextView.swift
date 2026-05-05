import SwiftUI
import AppKit

extension Notification.Name {
    static let scratchpadPopoverDidShow = Notification.Name("scratchpadPopoverDidShow")
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
        guard let textView = scrollView.documentView as? PlainTextNSTextView else { return }

        if textView.string != text {
            let wasFirstResponder = textView.window?.firstResponder == textView
            textView.string = text
            if wasFirstResponder {
                textView.window?.makeFirstResponder(textView)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextView
        weak var textView: NSTextView?
        private var focusObserver: NSObjectProtocol?

        init(_ parent: PlainTextView) {
            self.parent = parent
            super.init()

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
        }

        deinit {
            if let observer = focusObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }
            parent.text = textView.string
            parent.onTextChange()
        }
    }
}

// MARK: - Custom NSTextView with explicit command-key handling

final class PlainTextNSTextView: NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command),
           let chars = event.charactersIgnoringModifiers {
            let lower = chars.lowercased()
            switch lower {
            case "a":
                selectAll(nil)
                return true
            case "c":
                copy(nil)
                return true
            case "v":
                paste(nil)
                return true
            case "x":
                cut(nil)
                return true
            case "z":
                if event.modifierFlags.contains(.shift) {
                    undoManager?.redo()
                } else {
                    undoManager?.undo()
                }
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
