import AppKit
import SwiftUI
import ClipboardScratchpadLib

final class FloatingWindow: NSPanel {
    var onMove: ((CGRect) -> Void)?
    var onClose: (() -> Void)?

    private let cornerRadius: CGFloat = 14
    private var dragStart: NSPoint = .zero

    init<Content: View>(contentRect: NSRect, contentView: Content) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        self.isFloatingPanel = true
        self.level = .floating
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isOpaque = false
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]

        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = NSRect(origin: .zero, size: contentRect.size)
        hostingController.view.autoresizingMask = [.width, .height]

        let shell = NSVisualEffectView(frame: NSRect(origin: .zero, size: contentRect.size))
        shell.autoresizingMask = [.width, .height]
        shell.material = .popover
        shell.blendingMode = .behindWindow
        shell.state = .active
        shell.wantsLayer = true
        shell.layer?.cornerRadius = cornerRadius
        shell.layer?.cornerCurve = .continuous
        shell.layer?.masksToBounds = true
        shell.layer?.borderWidth = 1
        shell.layer?.borderColor = NSColor.black.withAlphaComponent(0.35).cgColor
        shell.addSubview(hostingController.view)

        self.contentView = shell
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        false
    }

    override func cancelOperation(_ sender: Any?) {}

    override func mouseDown(with event: NSEvent) {
        let location = event.locationInWindow
        let pointInContent = self.contentView?.convert(location, from: nil) ?? location
        let contentSize = self.contentView?.bounds.size ?? self.frame.size

        if WindowDragRegion.isDraggable(point: pointInContent, contentSize: contentSize) {
            dragStart = event.locationInWindow
        } else {
            super.mouseDown(with: event)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard dragStart != .zero else {
            super.mouseDragged(with: event)
            return
        }
        let current = event.locationInWindow
        self.setFrame(WindowDragRegion.movedFrame(self.frame, from: dragStart, to: current), display: true)
    }

    override func mouseUp(with event: NSEvent) {
        if dragStart != .zero {
            dragStart = .zero
            onMove?(self.frame)
        }
        super.mouseUp(with: event)
    }

    override func close() {
        onClose?()
        orderOut(nil)
    }
}
