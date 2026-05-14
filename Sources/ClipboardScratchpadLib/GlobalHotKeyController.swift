import Foundation

public struct HotKeyRegistration: Equatable {
    public let id: Int

    public init(id: Int) {
        self.id = id
    }
}

public protocol HotKeyRegistering {
    func register(_ shortcut: GlobalKeyboardShortcut) -> HotKeyRegistration?
    func unregister(_ registration: HotKeyRegistration)
}

public final class GlobalHotKeyController {
    public enum AssignmentResult: Equatable {
        case registered
        case unavailable
        case invalid(GlobalKeyboardShortcut.ValidationError)
        case cleared
    }

    public private(set) var savedShortcut: GlobalKeyboardShortcut?
    public private(set) var activeShortcut: GlobalKeyboardShortcut?
    public private(set) var isUnavailable = false

    private let registrar: HotKeyRegistering
    private var activeRegistration: HotKeyRegistration?

    public init(savedShortcut: GlobalKeyboardShortcut? = nil, registrar: HotKeyRegistering) {
        self.savedShortcut = savedShortcut
        self.registrar = registrar
    }

    @discardableResult
    public func assign(_ shortcut: GlobalKeyboardShortcut) -> AssignmentResult {
        if let validationError = shortcut.validationError {
            return .invalid(validationError)
        }

        guard let registration = registrar.register(shortcut) else {
            isUnavailable = true
            return .unavailable
        }

        if let activeRegistration {
            registrar.unregister(activeRegistration)
        }
        activeRegistration = registration
        activeShortcut = shortcut
        savedShortcut = shortcut
        isUnavailable = false
        return .registered
    }

    @discardableResult
    public func restoreSavedShortcut() -> AssignmentResult {
        guard let savedShortcut else {
            return .cleared
        }
        return assign(savedShortcut)
    }

    public func clear() {
        if let activeRegistration {
            registrar.unregister(activeRegistration)
        }
        activeRegistration = nil
        activeShortcut = nil
        savedShortcut = nil
        isUnavailable = false
    }
}
