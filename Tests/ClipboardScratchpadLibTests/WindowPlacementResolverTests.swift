import XCTest
@testable import ClipboardScratchpadLib

final class WindowPlacementResolverTests: XCTestCase {
    private let fallback = CGRect(x: 200, y: 200, width: 440, height: 520)

    func testVisibleSavedFrameIsReturned() {
        let saved = CGRect(x: 100, y: 100, width: 440, height: 520)
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let result = WindowPlacementResolver.resolve(
            savedFrame: saved,
            screenFrames: [screen],
            fallbackFrame: fallback
        )

        XCTAssertEqual(result, saved)
    }

    func testOffScreenSavedFrameReturnsFallback() {
        let saved = CGRect(x: 3000, y: 3000, width: 440, height: 520)
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let result = WindowPlacementResolver.resolve(
            savedFrame: saved,
            screenFrames: [screen],
            fallbackFrame: fallback
        )

        XCTAssertEqual(result, fallback)
    }

    func testPartiallyVisibleFrameIsReturnedIfEnoughArea() {
        let saved = CGRect(x: 1800, y: 100, width: 440, height: 520)
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let result = WindowPlacementResolver.resolve(
            savedFrame: saved,
            screenFrames: [screen],
            fallbackFrame: fallback
        )

        let visibleWidth = 1920 - 1800
        let visibleArea = visibleWidth * 520
        if visibleArea >= 10_000 {
            XCTAssertEqual(result, saved)
        } else {
            XCTAssertEqual(result, fallback)
        }
    }

    func testSlightlyVisibleFrameReturnsFallback() {
        let saved = CGRect(x: 1910, y: 100, width: 440, height: 520)
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let result = WindowPlacementResolver.resolve(
            savedFrame: saved,
            screenFrames: [screen],
            fallbackFrame: fallback
        )

        XCTAssertEqual(result, fallback)
    }

    func testEmptyScreenFramesReturnsFallback() {
        let saved = CGRect(x: 100, y: 100, width: 440, height: 520)

        let result = WindowPlacementResolver.resolve(
            savedFrame: saved,
            screenFrames: [],
            fallbackFrame: fallback
        )

        XCTAssertEqual(result, fallback)
    }

    func testZeroSizeSavedFrameReturnsFallback() {
        let saved = CGRect(x: 100, y: 100, width: 0, height: 0)
        let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)

        let result = WindowPlacementResolver.resolve(
            savedFrame: saved,
            screenFrames: [screen],
            fallbackFrame: fallback
        )

        XCTAssertEqual(result, fallback)
    }

    func testFrameVisibleOnSecondScreenIsReturned() {
        let saved = CGRect(x: 2500, y: 100, width: 440, height: 520)
        let firstScreen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let secondScreen = CGRect(x: 1920, y: 0, width: 1920, height: 1080)

        let result = WindowPlacementResolver.resolve(
            savedFrame: saved,
            screenFrames: [firstScreen, secondScreen],
            fallbackFrame: fallback
        )

        XCTAssertEqual(result, saved)
    }

    func testDefaultFrameAppearsBelowMenuBarItem() {
        let menuBarItemFrame = CGRect(x: 900, y: 1080, width: 24, height: 22)
        let contentSize = CGSize(width: 440, height: 520)

        let result = WindowPlacementResolver.defaultFrame(
            below: menuBarItemFrame,
            contentSize: contentSize
        )

        XCTAssertEqual(result, CGRect(x: 692, y: 556, width: 440, height: 520))
    }

    func testSavedFrameSmallerThanMinimumUsesMinimumSize() {
        let saved = CGRect(x: 100, y: 100, width: 200, height: 200)

        let result = WindowPlacementResolver.enforceMinimumSize(
            saved,
            minimumSize: CGSize(width: 360, height: 320)
        )

        XCTAssertEqual(result, CGRect(x: 100, y: 100, width: 360, height: 320))
    }

    func testSavedFrameLargerThanMinimumKeepsSize() {
        let saved = CGRect(x: 100, y: 100, width: 800, height: 700)

        let result = WindowPlacementResolver.enforceMinimumSize(
            saved,
            minimumSize: CGSize(width: 360, height: 320)
        )

        XCTAssertEqual(result, saved)
    }
}
