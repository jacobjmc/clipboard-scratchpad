import Carbon
import ClipboardScratchpadLib

final class CarbonHotKeyRegistrar: HotKeyRegistering {
    private static var callbacks: [UInt32: () -> Void] = [:]
    private static var isHandlerInstalled = false
    private static let signature = fourCharacterCode("CSHK")

    private var registrations: [Int: EventHotKeyRef] = [:]
    private var nextID: UInt32 = 1
    private let onTrigger: () -> Void

    init(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger
        Self.installHandlerIfNeeded()
    }

    func register(_ shortcut: GlobalKeyboardShortcut) -> HotKeyRegistration? {
        let id = nextID
        nextID += 1

        var hotKeyRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: Self.signature, id: id)
        let status = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr, let hotKeyRef else {
            return nil
        }

        registrations[Int(id)] = hotKeyRef
        Self.callbacks[id] = onTrigger
        return HotKeyRegistration(id: Int(id))
    }

    func unregister(_ registration: HotKeyRegistration) {
        guard let hotKeyRef = registrations.removeValue(forKey: registration.id) else { return }
        UnregisterEventHotKey(hotKeyRef)
        Self.callbacks.removeValue(forKey: UInt32(registration.id))
    }

    private static func installHandlerIfNeeded() {
        guard !isHandlerInstalled else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, _ in
                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                CarbonHotKeyRegistrar.callbacks[hotKeyID.id]?()
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
        isHandlerInstalled = true
    }

    private static func fourCharacterCode(_ string: String) -> OSType {
        string.utf8.reduce(0) { ($0 << 8) + OSType($1) }
    }
}

private extension GlobalKeyboardShortcut {
    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) {
            result |= UInt32(cmdKey)
        }
        if modifiers.contains(.option) {
            result |= UInt32(optionKey)
        }
        if modifiers.contains(.control) {
            result |= UInt32(controlKey)
        }
        if modifiers.contains(.shift) {
            result |= UInt32(shiftKey)
        }
        return result
    }
}
