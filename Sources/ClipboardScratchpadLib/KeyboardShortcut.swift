import Foundation

public struct GlobalKeyboardShortcut: Codable, Equatable {
    public struct Modifiers: OptionSet, Codable, Equatable {
        public let rawValue: Int

        public static let command = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let control = Modifiers(rawValue: 1 << 2)
        public static let shift = Modifiers(rawValue: 1 << 3)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public enum ValidationError: Equatable {
        case missingNonShiftModifier
        case invalidKey
        case reservedShortcut
    }

    public let keyCode: UInt16
    public let modifiers: Modifiers

    public init(keyCode: UInt16, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public var validationError: ValidationError? {
        if modifiers.intersection([.command, .option, .control]).isEmpty {
            return .missingNonShiftModifier
        }
        if Self.invalidKeyCodes.contains(keyCode) {
            return .invalidKey
        }
        if modifiers == .command, Self.reservedCommandKeyCodes.contains(keyCode) {
            return .reservedShortcut
        }
        return nil
    }

    public var displayString: String {
        "\(modifierDisplay)\(keyDisplay)"
    }

    private var modifierDisplay: String {
        var parts: [String] = []
        if modifiers.contains(.control) {
            parts.append("⌃")
        }
        if modifiers.contains(.option) {
            parts.append("⌥")
        }
        if modifiers.contains(.command) {
            parts.append("⌘")
        }
        if modifiers.contains(.shift) {
            parts.append("⇧")
        }
        return parts.joined()
    }

    private var keyDisplay: String {
        Self.keyDisplayNames[keyCode] ?? "Key \(keyCode)"
    }

    private static let invalidKeyCodes: Set<UInt16> = [
        36, // Return
        53, // Escape
        123, 124, 125, 126 // Arrows
    ]

    private static let reservedCommandKeyCodes: Set<UInt16> = [
        0,  // A
        6,  // Z
        7,  // X
        8,  // C
        9,  // V
        1,  // S
        12, // Q
        13, // W
        45, // N
        31, // O
        35  // P
    ]

    private static let keyDisplayNames: [UInt16: String] = [
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        4: "H",
        5: "G",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        16: "Y",
        17: "T",
        31: "O",
        32: "U",
        34: "I",
        35: "P",
        37: "L",
        38: "J",
        40: "K",
        45: "N",
        46: "M",
        49: "Space"
    ]
}
