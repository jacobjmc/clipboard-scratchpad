import AppKit
import SwiftUI
import ClipboardScratchpadLib

final class StatusBarController: NSObject, NSPopoverDelegate, NSWindowDelegate {
    private static let contentSize = NSSize(width: 440, height: 520)
    private static let minimumWindowSize = NSSize(width: 360, height: 320)

    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let store: ScratchpadStore
    private var eventMonitor: EventMonitor?
    private var activationObserver: NSObjectProtocol?
    private var floatingWindow: FloatingWindow?
    private var detachedWindow: FloatingWindow?
    private var presentationState = ScratchpadPresentationState()
    private var isResettingWindowFrame = false

    init(store: ScratchpadStore) {
        self.store = store

        popover = NSPopover()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        popover.contentSize = Self.contentSize
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(store)
        )

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Scratchpad")
            button.action = #selector(toggleVisibility)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.popover.isShown else { return }
            self.presentationState.outsideClicked()
            self.applyPresentationState(event)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pinChanged(_:)),
            name: .scratchpadPinChanged,
            object: nil
        )

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.store.recordExternalApplication(application)
        }
    }

    deinit {
        if let activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(activationObserver)
        }
    }

    @objc private func toggleVisibility(_ sender: AnyObject?) {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusMenu()
            return
        }
        if presentationState.mode == .popover, detachedWindow?.isVisible == true {
            bringDetachedWindowForward()
            return
        }
        syncPresentationStateWithAppKit()
        presentationState.menuBarItemClicked()
        applyPresentationState(sender)
    }

    @objc private func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            discardDetachedWindow()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            NSApp.activate(ignoringOtherApps: true)
            applyPopoverLevel()
            popover.contentViewController?.view.window?.makeKey()
            NotificationCenter.default.post(name: .scratchpadPopoverDidShow, object: nil)
            if !store.isPinned {
                eventMonitor?.start()
            }
        }
    }

    @objc private func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }

    private func applyPopoverLevel() {
        popover.contentViewController?.view.window?.level = store.isPinned ? .floating : .normal
    }

    private func showFloatingWindow() {
        let shouldAnimate = floatingWindow == nil
        let resolved = resolveFloatingFrame()
        if floatingWindow == nil {
            floatingWindow = FloatingWindow(
                contentRect: resolved,
                level: .floating,
                contentView: ContentView().environmentObject(store)
            )
            floatingWindow?.onMove = { [weak self] frame in
                guard self?.isResettingWindowFrame == false else { return }
                self?.store.windowFrame = frame
            }
            floatingWindow?.onResize = { [weak self] frame in
                guard self?.isResettingWindowFrame == false else { return }
                self?.store.windowFrame = frame
            }
            floatingWindow?.onClose = { [weak self] in
                self?.presentationState.windowClosed()
                self?.applyPresentationState(nil)
            }
        } else {
            floatingWindow?.setFrame(resolved, display: true)
        }
        if shouldAnimate {
            floatingWindow?.alphaValue = 0
        }
        floatingWindow?.makeKeyAndOrderFront(nil)
        if shouldAnimate {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.14
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                floatingWindow?.animator().alphaValue = 1
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideFloatingWindow() {
        floatingWindow?.orderOut(nil)
    }

    private func syncPresentationStateWithAppKit() {
        switch presentationState.mode {
        case .popover:
            if detachedWindow?.isVisible == true {
                presentationState.visibility = .visible
            } else if !popover.isShown {
                presentationState.visibility = .hidden
            }
        case .floatingWindow:
            if floatingWindow?.isVisible != true {
                presentationState.visibility = .hidden
            }
        }
    }

    private func showStatusMenu() {
        let menu = NSMenu()
        let resetItem = NSMenuItem(
            title: "Reset Window Size and Location",
            action: #selector(resetWindowSizeAndLocation),
            keyEquivalent: ""
        )
        resetItem.target = self
        resetItem.isEnabled = store.windowFrame != nil || floatingWindow != nil || popover.contentViewController?.view.window != nil
        menu.addItem(resetItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func resetWindowSizeAndLocation() {
        let frame = fallbackFrame()
        isResettingWindowFrame = true
        store.windowFrame = nil
        floatingWindow?.setFrame(frame, display: true)
        detachedWindow?.setFrame(frame, display: true)
        popover.contentViewController?.view.window?.setFrame(frame, display: true)
        isResettingWindowFrame = false
        if presentationState.mode == .floatingWindow {
            presentationState.visibility = .visible
            applyPresentationState(nil)
        }
    }

    private func resolveFloatingFrame() -> CGRect {
        guard let saved = store.windowFrame else {
            return fallbackFrame()
        }
        let screens = NSScreen.screens.map { $0.frame }
        return WindowPlacementResolver.resolve(
            savedFrame: WindowPlacementResolver.enforceMinimumSize(saved, minimumSize: Self.minimumWindowSize),
            screenFrames: screens,
            fallbackFrame: fallbackFrame()
        )
    }

    private func fallbackFrame() -> CGRect {
        var frame = CGRect(origin: .zero, size: Self.contentSize)
        if let button = statusItem.button, let window = button.window {
            let buttonRect = button.convert(button.bounds, to: nil)
            let screenPoint = window.convertToScreen(buttonRect)
            frame = WindowPlacementResolver.defaultFrame(
                below: screenPoint,
                contentSize: Self.contentSize
            )
        }
        return frame
    }

    @objc private func pinChanged(_ notification: Notification) {
        guard let pinned = notification.object as? Bool else { return }
        if pinned, let detachedWindow, detachedWindow.isVisible {
            store.windowFrame = WindowPlacementResolver.enforceMinimumSize(
                detachedWindow.frame,
                minimumSize: Self.minimumWindowSize
            )
        } else if pinned, let window = popover.contentViewController?.view.window, !popover.isShown {
            store.windowFrame = window.frame
        }
        presentationState.pinChanged(isPinned: pinned)
        applyPresentationState(nil)
    }

    private func applyPresentationState(_ sender: AnyObject?) {
        switch (presentationState.mode, presentationState.visibility) {
        case (.popover, .visible):
            hideFloatingWindow()
            showPopover(sender)
        case (.popover, .hidden):
            hideFloatingWindow()
            hideDetachedWindow()
            closePopover(sender)
        case (.floatingWindow, .visible):
            closePopover(nil)
            hideDetachedWindow()
            showFloatingWindow()
        case (.floatingWindow, .hidden):
            closePopover(nil)
            hideDetachedWindow()
            hideFloatingWindow()
        }
    }

    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        true
    }

    func detachableWindow(for popover: NSPopover) -> NSWindow? {
        presentationState.popoverDetached()
        discardDetachedWindow()

        let window = FloatingWindow(
            contentRect: resolveFloatingFrame(),
            level: .normal,
            contentView: ContentView().environmentObject(store)
        )
        window.onMove = { [weak self] frame in
            guard self?.isResettingWindowFrame == false else { return }
            self?.store.windowFrame = frame
        }
        window.onResize = { [weak self] frame in
            guard self?.isResettingWindowFrame == false else { return }
            self?.store.windowFrame = frame
        }
        window.onClose = { [weak self, weak window] in
            if self?.detachedWindow === window {
                self?.detachedWindow = nil
            }
            self?.presentationState.windowClosed()
        }
        detachedWindow = window
        store.windowFrame = window.frame
        eventMonitor?.stop()
        return window
    }

    func popoverDidDetach(_ popover: NSPopover) {
        presentationState.popoverDetached()

        let window = popover.contentViewController?.view.window
        window?.styleMask.insert(.resizable)
        window?.minSize = Self.minimumWindowSize
        window?.acceptsMouseMovedEvents = true
        window?.delegate = self
        if let frame = window?.frame {
            store.windowFrame = frame
        }
    }

    private func hideDetachedWindow() {
        if let detachedWindow, detachedWindow.isVisible, !isResettingWindowFrame {
            store.windowFrame = detachedWindow.frame
        }
        detachedWindow?.orderOut(nil)
    }

    private func bringDetachedWindowForward() {
        guard let detachedWindow else { return }
        NSApp.activate(ignoringOtherApps: true)
        detachedWindow.makeKeyAndOrderFront(nil)
        detachedWindow.orderFrontRegardless()
    }

    private func discardDetachedWindow() {
        guard let window = detachedWindow else { return }
        if !isResettingWindowFrame {
            store.windowFrame = window.frame
        }
        window.orderOut(nil)
        detachedWindow = nil
    }

    func popoverDidClose(_ notification: Notification) {
        guard presentationState.mode == .popover else { return }
        presentationState.visibility = .hidden
        eventMonitor?.stop()
    }

    func windowDidMove(_ notification: Notification) {
        guard !isResettingWindowFrame else { return }
        guard let window = notification.object as? NSWindow else { return }
        guard window === popover.contentViewController?.view.window || window === detachedWindow else { return }
        store.windowFrame = window.frame
    }

    func windowDidResize(_ notification: Notification) {
        guard !isResettingWindowFrame else { return }
        guard let window = notification.object as? NSWindow else { return }
        guard window === popover.contentViewController?.view.window || window === detachedWindow else { return }
        store.windowFrame = window.frame
    }
}
