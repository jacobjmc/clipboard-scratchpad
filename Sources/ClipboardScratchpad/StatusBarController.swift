import AppKit
import SwiftUI

final class StatusBarController {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var eventMonitor: EventMonitor?

    init(store: ScratchpadStore) {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 440, height: 520)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(store)
        )

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Scratchpad")
            button.action = #selector(togglePopover)
            button.target = self
        }

        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.popover.isShown else { return }
            self.closePopover(event)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pinChanged(_:)),
            name: .scratchpadPinChanged,
            object: nil
        )
    }

    @objc private func pinChanged(_ notification: Notification) {
        guard let pinned = notification.object as? Bool else { return }
        popover.behavior = pinned ? .applicationDefined : .transient
        if pinned {
            eventMonitor?.stop()
        } else {
            if popover.isShown {
                eventMonitor?.start()
            }
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()
            NotificationCenter.default.post(name: .scratchpadPopoverDidShow, object: nil)
            eventMonitor?.start()
        }
    }

    func closePopover(_ sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
}

final class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void

    init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }

    deinit {
        stop()
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
