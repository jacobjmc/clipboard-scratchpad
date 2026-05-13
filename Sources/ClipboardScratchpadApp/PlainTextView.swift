import SwiftUI
import AppKit

extension Notification.Name {
    static let scratchpadPopoverDidShow = Notification.Name("scratchpadPopoverDidShow")
    static let scratchpadInsertText = Notification.Name("scratchpadInsertText")
    static let scratchpadClearText = Notification.Name("scratchpadClearText")
    static let scratchpadPinChanged = Notification.Name("scratchpadPinChanged")
    static let scratchpadCloseRequested = Notification.Name("scratchpadCloseRequested")
}

struct PlainTextView: NSViewRepresentable {
    @Binding var text: String
    var onTextChange: () -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.autoresizingMask = [.width, .height]
        scrollView.borderType = .noBorder

        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(
            containerSize: NSSize(width: contentSize.width, height: .greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let textView = PlainTextNSTextView(
            frame: NSRect(origin: .zero, size: contentSize),
            textContainer: textContainer
        )
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.autoresizingMask = [.width, .height]
        textView.delegate = context.coordinator

        scrollView.documentView = textView
        context.coordinator.textView = textView

        textView.string = text
        context.coordinator.lastSyncedText = text

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self

        guard let textView = scrollView.documentView as? PlainTextNSTextView else { return }

        // The text view is the source of truth when it already has the text.
        // Skip sync to avoid loops and preserve undo history.
        if textView.string == text {
            context.coordinator.lastSyncedText = text
            return
        }

        // External change: sync from binding to text view.
        context.coordinator.lastSyncedText = text
        let undoManager = textView.undoManager
        undoManager?.disableUndoRegistration()
        textView.string = text
        undoManager?.enableUndoRegistration()
        undoManager?.removeAllActions()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextView
        weak var textView: NSTextView?
        private var focusObserver: NSObjectProtocol?
        private var insertObserver: NSObjectProtocol?
        private var clearObserver: NSObjectProtocol?
        private var undoBreakWorkItem: DispatchWorkItem?
        private var lastSelectedRange: NSRange = NSRange(location: 0, length: 0)
        var lastSyncedText: String = ""

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

            insertObserver = NotificationCenter.default.addObserver(
                forName: .scratchpadInsertText,
                object: nil,
                queue: .main
            ) { [weak self] note in
                guard let self = self, let textView = self.textView else { return }
                guard let content = note.userInfo?["content"] as? String else { return }
                self.insertText(content, into: textView)
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
            if let observer = insertObserver {
                NotificationCenter.default.removeObserver(observer)
            }
            if let observer = clearObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = textView else { return }

            lastSelectedRange = textView.selectedRange()

            let previousText = lastSyncedText
            let currentText = textView.string
            lastSyncedText = textView.string
            parent.text = currentText
            parent.onTextChange()

            undoBreakWorkItem?.cancel()
            if shouldBreakUndoGroup(previousText: previousText, currentText: currentText) {
                textView.breakUndoCoalescing()
                return
            }

            let workItem = DispatchWorkItem { [weak textView] in
                textView?.breakUndoCoalescing()
            }
            undoBreakWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: workItem)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            lastSelectedRange = textView.selectedRange()
        }

        private func shouldBreakUndoGroup(previousText: String, currentText: String) -> Bool {
            guard currentText.count > previousText.count else { return false }
            guard currentText.hasPrefix(previousText) else { return false }

            let insertedText = String(currentText.dropFirst(previousText.count))
            return insertedText.contains { character in
                character.isWhitespace || ".!?;:".contains(character)
            }
        }

        private func insertText(_ content: String, into textView: NSTextView) {
            let selectedRange = textView.window?.firstResponder == textView
                ? textView.selectedRange()
                : lastSelectedRange

            let range: NSRange
            if selectedRange.location == NSNotFound || NSMaxRange(selectedRange) > textView.string.utf16.count {
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

        private func clearText(in textView: NSTextView) {
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
    private let localUndoManager = UndoManager()

    convenience init() {
        self.init(frame: .zero, textContainer: nil)
    }

    override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
        super.init(frame: frameRect, textContainer: container)
        localUndoManager.levelsOfUndo = 100
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        localUndoManager.levelsOfUndo = 100
    }

    override var undoManager: UndoManager? {
        localUndoManager
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        guard flags.contains(.command),
              let chars = event.charactersIgnoringModifiers?.lowercased()
        else {
            return super.performKeyEquivalent(with: event)
        }

        switch chars {
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
        case "z":
            if flags.contains(.shift) {
                undoManager?.redo()
            } else {
                undoManager?.undo()
            }
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
}
