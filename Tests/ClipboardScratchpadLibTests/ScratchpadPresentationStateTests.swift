import XCTest
@testable import ClipboardScratchpadLib

final class ScratchpadPresentationStateTests: XCTestCase {
    func testMenuBarClickShowsAndHidesUnpinnedPopover() {
        var state = ScratchpadPresentationState()

        state.menuBarItemClicked()
        XCTAssertEqual(state, ScratchpadPresentationState(mode: .popover, visibility: .visible))

        state.menuBarItemClicked()
        XCTAssertEqual(state, ScratchpadPresentationState(mode: .popover, visibility: .hidden))
    }

    func testPinningShowsFloatingWindowAndHidesPopoverMode() {
        var state = ScratchpadPresentationState(mode: .popover, visibility: .visible)

        state.pinChanged(isPinned: true)

        XCTAssertEqual(state, ScratchpadPresentationState(mode: .floatingWindow, visibility: .visible))
    }

    func testMenuBarClickTogglesFloatingWindowVisibilityWithoutUnpinning() {
        var state = ScratchpadPresentationState(mode: .floatingWindow, visibility: .visible)

        state.menuBarItemClicked()
        XCTAssertEqual(state, ScratchpadPresentationState(mode: .floatingWindow, visibility: .hidden))

        state.menuBarItemClicked()
        XCTAssertEqual(state, ScratchpadPresentationState(mode: .floatingWindow, visibility: .visible))
    }

    func testClosingFloatingWindowHidesWithoutUnpinning() {
        var state = ScratchpadPresentationState(mode: .floatingWindow, visibility: .visible)

        state.windowClosed()

        XCTAssertEqual(state, ScratchpadPresentationState(mode: .floatingWindow, visibility: .hidden))
    }

    func testUnpinningReturnsToVisiblePopover() {
        var state = ScratchpadPresentationState(mode: .floatingWindow, visibility: .hidden)

        state.pinChanged(isPinned: false)

        XCTAssertEqual(state, ScratchpadPresentationState(mode: .popover, visibility: .visible))
    }

    func testOutsideClickOnlyHidesVisiblePopover() {
        var popover = ScratchpadPresentationState(mode: .popover, visibility: .visible)
        var floatingWindow = ScratchpadPresentationState(mode: .floatingWindow, visibility: .visible)

        popover.outsideClicked()
        floatingWindow.outsideClicked()

        XCTAssertEqual(popover, ScratchpadPresentationState(mode: .popover, visibility: .hidden))
        XCTAssertEqual(floatingWindow, ScratchpadPresentationState(mode: .floatingWindow, visibility: .visible))
    }
}
