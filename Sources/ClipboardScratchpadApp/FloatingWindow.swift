import AppKit
import SwiftUI
import ClipboardScratchpadLib

final class FloatingWindow: NSPanel {
    var onMove: ((CGRect) -> Void)?
    var onResize: ((CGRect) -> Void)?
    var onClose: (() -> Void)?

    private let cornerRadius: CGFloat = 18
    private var dragStart: NSPoint = .zero

    init<Content: View>(
        contentRect: NSRect,
        level: NSWindow.Level = .floating,
        contentView: Content
    ) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .resizable],
            backing: .buffered,
            defer: false
        )
        self.minSize = NSSize(width: 360, height: 320)
        self.isFloatingPanel = true
        self.level = level
        self.isMovableByWindowBackground = false
        self.backgroundColor = .clear
        self.hasShadow = false
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
        shell.cornerRadius = cornerRadius
        shell.applyRoundedCorners()
        shell.layer?.borderWidth = 1
        shell.layer?.borderColor = NSColor.black.withAlphaComponent(0.35).cgColor
        shell.addSubview(hostingController.view)

        let resizeOverlay = ScratchpadWindowResizeOverlayView(frame: shell.bounds)
        resizeOverlay.autoresizingMask = [.width, .height]
        resizeOverlay.minimumSize = self.minSize
        resizeOverlay.onResize = { [weak self] frame in
            self?.onResize?(frame)
        }
        shell.addSubview(resizeOverlay)

        let container = FloatingWindowContainerView(frame: NSRect(origin: .zero, size: contentRect.size))
        container.autoresizingMask = [.width, .height]
        container.cornerRadius = cornerRadius
        container.addSubview(shell)

        self.contentView = container
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

private final class FloatingWindowContainerView: NSView {
    var cornerRadius: CGFloat = 18

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func layout() {
        super.layout()
        subviews.first?.frame = bounds
    }
}

private final class FloatingWindowShellView: NSVisualEffectView {
    var cornerRadius: CGFloat = 18

    override func layout() {
        super.layout()
        applyRoundedCorners()
    }

    func applyRoundedCorners() {
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
    }
}

final class ScratchpadWindowResizeOverlayView: NSView {
    var minimumSize: NSSize = NSSize(width: 360, height: 320)
    var onResize: ((CGRect) -> Void)?

    private let resizeEdgeThickness: CGFloat = 16
    private let headerControlsHeight: CGFloat = 32
    private let leadingControlsWidth: CGFloat = 60
    private let trailingControlsWidth: CGFloat = 104
    private var resizeStart: NSPoint = .zero
    private var resizeStartFrame: NSRect = .zero
    private var resizeRegion: WindowResizeRegion?
    private var cursorTrackingAreas: [NSTrackingArea] = []

    override func hitTest(_ point: NSPoint) -> NSView? {
        if resizeRegion(for: point) != nil {
            return self
        }
        return nil
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        let thickness = resizeEdgeThickness
        let verticalEdgeHeight = max(0, bounds.height - headerControlsHeight)
        addCursorRect(NSRect(x: 0, y: 0, width: thickness, height: verticalEdgeHeight), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: bounds.width - thickness, y: 0, width: thickness, height: verticalEdgeHeight), cursor: .resizeLeftRight)
        addCursorRect(NSRect(x: 0, y: 0, width: bounds.width, height: thickness), cursor: .resizeUpDown)
        addCursorRect(
            NSRect(
                x: leadingControlsWidth,
                y: bounds.height - thickness,
                width: max(0, bounds.width - leadingControlsWidth - trailingControlsWidth),
                height: thickness
            ),
            cursor: .resizeUpDown
        )
    }

    override func cursorUpdate(with event: NSEvent) {
        updateCursor(for: convert(event.locationInWindow, from: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        updateCursor(for: convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let region = resizeRegion(for: point), let window else {
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
        for trackingArea in cursorTrackingAreas {
            removeTrackingArea(trackingArea)
        }
        let cursorTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInActiveApp, .cursorUpdate, .mouseEnteredAndExited, .inVisibleRect],
            owner: self
        )
        let mouseTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect],
            owner: self
        )
        addTrackingArea(cursorTrackingArea)
        addTrackingArea(mouseTrackingArea)
        cursorTrackingAreas = [cursorTrackingArea, mouseTrackingArea]
        window?.invalidateCursorRects(for: self)
    }

    private func updateCursor(for point: NSPoint) {
        guard let region = resizeRegion(for: point) else {
            NSCursor.arrow.set()
            return
        }
        cursor(for: region).set()
    }

    private func resizeRegion(for point: NSPoint) -> WindowResizeRegion? {
        guard !isHeaderControlPoint(point) else { return nil }
        return WindowResizeRegion.region(for: point, contentSize: bounds.size, edgeThickness: resizeEdgeThickness)
    }

    private func isHeaderControlPoint(_ point: NSPoint) -> Bool {
        guard point.y >= bounds.height - headerControlsHeight else { return false }
        return point.x <= leadingControlsWidth || point.x >= bounds.width - trailingControlsWidth
    }

    private func cursor(for region: WindowResizeRegion) -> NSCursor {
        if #available(macOS 15.0, *) {
            return NSCursor.frameResize(
                position: cursorPosition(for: region),
                directions: .all
            )
        }
        if region.contains(.left) || region.contains(.right) {
            return .resizeLeftRight
        }
        return .resizeUpDown
    }

    @available(macOS 15.0, *)
    private func cursorPosition(for region: WindowResizeRegion) -> NSCursor.FrameResizePosition {
        switch (region.contains(.left), region.contains(.right), region.contains(.top), region.contains(.bottom)) {
        case (true, false, true, false):
            return .topLeft
        case (false, true, true, false):
            return .topRight
        case (true, false, false, true):
            return .bottomLeft
        case (false, true, false, true):
            return .bottomRight
        case (true, false, false, false):
            return .left
        case (false, true, false, false):
            return .right
        case (false, false, true, false):
            return .top
        default:
            return .bottom
        }
    }
}
