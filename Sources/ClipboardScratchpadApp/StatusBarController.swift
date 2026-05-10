import AppKit
import SwiftUI
import ClipboardScratchpadLib

final class StatusBarController {
    private static let contentSize = NSSize(width: 440, height: 520)

    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let store: ScratchpadStore
    private var eventMonitor: EventMonitor?
    private var activationObserver: NSObjectProtocol?
    private var floatingWindow: FloatingWindow?
    private var presentationState = ScratchpadPresentationState()

    init(store: ScratchpadStore) {
        self.store = store

        popover = NSPopover()
        popover.contentSize = Self.contentSize
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(store)
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Scratchpad")
            button.action = #selector(toggleVisibility)
            button.target = self
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
        presentationState.menuBarItemClicked()
        applyPresentationState(sender)
    }

    @objc private func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
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
        if floatingWindow == nil {
            let resolved = resolveFloatingFrame()
            floatingWindow = FloatingWindow(
                contentRect: resolved,
                contentView: ContentView().environmentObject(store)
            )
            floatingWindow?.onMove = { [weak self] frame in
                self?.store.floatingFrame = frame
            }
            floatingWindow?.onClose = { [weak self] in
                self?.presentationState.windowClosed()
                self?.applyPresentationState(nil)
            }
        }
        floatingWindow?.orderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func hideFloatingWindow() {
        floatingWindow?.orderOut(nil)
    }

    private func resolveFloatingFrame() -> CGRect {
        guard let saved = store.floatingFrame else {
            return fallbackFrame()
        }
        let screens = NSScreen.screens.map { $0.frame }
        return WindowPlacementResolver.resolve(
            savedFrame: saved,
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
            closePopover(sender)
        case (.floatingWindow, .visible):
            closePopover(nil)
            showFloatingWindow()
        case (.floatingWindow, .hidden):
            closePopover(nil)
            hideFloatingWindow()
        }
    }
}
