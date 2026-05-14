import XCTest
@testable import ClipboardScratchpadLib

final class GlobalHotKeyControllerTests: XCTestCase {
    func testAssigningShortcutSavesOnlyAfterSuccessfulRegistration() {
        let registrar = TestHotKeyRegistrar(results: [.success(HotKeyRegistration(id: 1))])
        let controller = GlobalHotKeyController(registrar: registrar)
        let shortcut = GlobalKeyboardShortcut(keyCode: 49, modifiers: [.command, .shift])

        let result = controller.assign(shortcut)

        XCTAssertEqual(result, .registered)
        XCTAssertEqual(controller.savedShortcut, shortcut)
        XCTAssertEqual(registrar.registeredShortcuts, [shortcut])
    }

    func testFailedReplacementKeepsPreviousWorkingShortcut() {
        let first = GlobalKeyboardShortcut(keyCode: 49, modifiers: [.command, .shift])
        let second = GlobalKeyboardShortcut(keyCode: 8, modifiers: [.control, .option])
        let registrar = TestHotKeyRegistrar(results: [.success(HotKeyRegistration(id: 1)), .failure])
        let controller = GlobalHotKeyController(registrar: registrar)

        XCTAssertEqual(controller.assign(first), .registered)
        XCTAssertEqual(controller.assign(second), .unavailable)

        XCTAssertEqual(controller.savedShortcut, first)
        XCTAssertEqual(controller.activeShortcut, first)
        XCTAssertEqual(registrar.unregisteredIDs, [])
    }

    func testClearUnregistersActiveShortcut() {
        let shortcut = GlobalKeyboardShortcut(keyCode: 49, modifiers: [.command, .shift])
        let registrar = TestHotKeyRegistrar(results: [.success(HotKeyRegistration(id: 7))])
        let controller = GlobalHotKeyController(registrar: registrar)

        controller.assign(shortcut)
        controller.clear()

        XCTAssertNil(controller.savedShortcut)
        XCTAssertNil(controller.activeShortcut)
        XCTAssertEqual(registrar.unregisteredIDs, [7])
    }

    func testRestoreSavedShortcutReportsLaunchFailureButKeepsSavedValueVisible() {
        let shortcut = GlobalKeyboardShortcut(keyCode: 49, modifiers: [.command, .shift])
        let registrar = TestHotKeyRegistrar(results: [.failure])
        let controller = GlobalHotKeyController(savedShortcut: shortcut, registrar: registrar)

        let result = controller.restoreSavedShortcut()

        XCTAssertEqual(result, .unavailable)
        XCTAssertEqual(controller.savedShortcut, shortcut)
        XCTAssertNil(controller.activeShortcut)
        XCTAssertTrue(controller.isUnavailable)
    }
}

private final class TestHotKeyRegistrar: HotKeyRegistering {
    enum Result {
        case success(HotKeyRegistration)
        case failure
    }

    private var results: [Result]
    private(set) var registeredShortcuts: [GlobalKeyboardShortcut] = []
    private(set) var unregisteredIDs: [Int] = []

    init(results: [Result]) {
        self.results = results
    }

    func register(_ shortcut: GlobalKeyboardShortcut) -> HotKeyRegistration? {
        registeredShortcuts.append(shortcut)
        switch results.removeFirst() {
        case .success(let registration):
            return registration
        case .failure:
            return nil
        }
    }

    func unregister(_ registration: HotKeyRegistration) {
        unregisteredIDs.append(registration.id)
    }
}
