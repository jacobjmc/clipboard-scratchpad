import XCTest
@testable import ClipboardScratchpadLib

final class GlobalKeyboardShortcutTests: XCTestCase {
    func testCommandShiftSpaceIsValidAndFormatted() {
        let shortcut = GlobalKeyboardShortcut(keyCode: 49, modifiers: [.command, .shift])

        XCTAssertNil(shortcut.validationError)
        XCTAssertEqual(shortcut.displayString, "⌘⇧Space")
    }

    func testRejectsShortcutsWithoutNonShiftModifier() {
        XCTAssertEqual(
            GlobalKeyboardShortcut(keyCode: 0, modifiers: []).validationError,
            .missingNonShiftModifier
        )
        XCTAssertEqual(
            GlobalKeyboardShortcut(keyCode: 0, modifiers: [.shift]).validationError,
            .missingNonShiftModifier
        )
    }

    func testRejectsInvalidKeys() {
        XCTAssertEqual(
            GlobalKeyboardShortcut(keyCode: 53, modifiers: [.command]).validationError,
            .invalidKey
        )
        XCTAssertEqual(
            GlobalKeyboardShortcut(keyCode: 36, modifiers: [.command]).validationError,
            .invalidKey
        )
        XCTAssertEqual(
            GlobalKeyboardShortcut(keyCode: 123, modifiers: [.command]).validationError,
            .invalidKey
        )
    }

    func testRejectsReservedCommandShortcuts() {
        XCTAssertEqual(
            GlobalKeyboardShortcut(keyCode: 8, modifiers: [.command]).validationError,
            .reservedShortcut
        )
        XCTAssertEqual(
            GlobalKeyboardShortcut(keyCode: 9, modifiers: [.command]).validationError,
            .reservedShortcut
        )
    }

    func testFormatsLetterShortcuts() {
        let shortcut = GlobalKeyboardShortcut(keyCode: 8, modifiers: [.control, .option])

        XCTAssertEqual(shortcut.displayString, "⌃⌥C")
    }
}
