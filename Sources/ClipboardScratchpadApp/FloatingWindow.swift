import AppKit
import SwiftUI
import ClipboardScratchpadLib

final class FloatingWindow: NSPanel {
    var onMove: ((CGRect) -> Void)?
    var onResize: ((CGRect) -> Void)?
    var onClose: (() -> Void)?

    private let cornerRadius: CGFloat = 14
    private var dragStart: NSPoint = .zero

    init<Content: View>(contentRect: NSRect, contentView: Content) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .resizable],
            backing: .buffered,
            defer: false
        )
        self.minSize = NSSize(width: 360, height: 320)
        self.isFloatingPanel = true
        self.level = .floating
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isOpaque = false
        self.acceptsMouseMovedEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]

        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.frame = NSRect(origin: .zero, size: contentRect.size)
        hostingController.view.autoresizingMask = [.width, .height]

        let shell = FloatingWindowShellView(frame: NSRect(origin: .zero, size: contentRect.size))
        shell.autoresizingMask = [.width, .height]
        shell.material = .popover
        shell.blendingMode = .behindWindow
        shell.state = .active
        shell.minimumSize = self.minSize
        shell.onResize = { [weak self] frame in
            self?.onResize?(frame)
        }
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

    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        super.setFrame(frameRect, display: flag)
        onResize?(self.frame)
    }

    override func close() {
        onClose?()
        orderOut(nil)
    }
}

private final class FloatingWindowShellView: NSVisualEffectView {
    var minimumSize: NSSize = NSSize(width: 360, height: 320)
    var onResize: ((CGRect) -> Void)?

    private var resizeStart: NSPoint = .zero
    private var resizeStartFrame: NSRect = .zero
    private var resizeRegion: WindowResizeRegion?

    override func hitTest(_ point: NSPoint) -> NSView? {
        if WindowResizeRegion.region(for: point, contentSize: bounds.size) != nil {
            return self
        }
        return super.hitTest(point)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        let thickness: CGFloat = 8
        addCursorRect(NSRect(x: 0, y: 0, width: thickness, height: bounds.height), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: bounds.width - thickness, y: 0, width: thickness, height: bounds.height), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: 0, y: 0, width: bounds.width, height: thickness), cursor: .resizeUpDown)
        addCursorRect(NSRect(x: 0, y: bounds.height - thickness, width: bounds.width, height: thickness), cursor: .resizeUpDown)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let region = WindowResizeRegion.region(for: point, contentSize: bounds.size), let window else {
            super.mouseDown(with: event)
            return
        }
        resizeRegion = region
        resizeStart = event.locationInWindow
        resizeStartFrame = window.frame
    }

    override func mouseDragged(with event: NSEvent) {
        guard let resizeRegion, let window else {
            super.mouseDragged(with: event)
            return
        }
        let current = event.locationInWindow
        let nextFrame = WindowResizeRegion.resizedFrame(
            resizeStartFrame,
            region: resizeRegion,
            delta: CGSize(width: current.x - resizeStart.x, height: current.y - resizeStart.y),
            minimumSize: minimumSize
        )
        window.setFrame(nextFrame, display: true)
    }

    override func mouseUp(with event: NSEvent) {
        if resizeRegion != nil {
            resizeRegion = nil
            resizeStart = .zero
            resizeStartFrame = .zero
            if let window {
                onResize?(window.frame)
            }
        }
        super.mouseUp(with: event)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        window?.invalidateCursorRects(for: self)
    }
}
