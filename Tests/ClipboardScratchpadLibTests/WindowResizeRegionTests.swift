import XCTest
@testable import ClipboardScratchpadLib

final class WindowResizeRegionTests: XCTestCase {
    private let contentSize = CGSize(width: 440, height: 520)
    private let minimumSize = CGSize(width: 360, height: 320)

    func testBottomRightCornerIsResizable() {
        XCTAssertEqual(
            WindowResizeRegion.region(for: CGPoint(x: 438, y: 2), contentSize: contentSize),
            [.right, .bottom]
        )
    }

    func testCenterIsNotResizable() {
        XCTAssertNil(WindowResizeRegion.region(for: CGPoint(x: 220, y: 260), contentSize: contentSize))
    }

    func testRightEdgeResizePreservesLeftEdge() {
        let frame = CGRect(x: 100, y: 100, width: 440, height: 520)
        let result = WindowResizeRegion.resizedFrame(
            frame,
            region: [.right],
            delta: CGSize(width: 40, height: 0),
            minimumSize: minimumSize
        )

        XCTAssertEqual(result, CGRect(x: 100, y: 100, width: 480, height: 520))
    }

    func testLeftEdgeResizeMovesOriginAndPreservesRightEdge() {
        let frame = CGRect(x: 100, y: 100, width: 440, height: 520)
        let result = WindowResizeRegion.resizedFrame(
            frame,
            region: [.left],
            delta: CGSize(width: -40, height: 0),
            minimumSize: minimumSize
        )

        XCTAssertEqual(result, CGRect(x: 60, y: 100, width: 480, height: 520))
    }

    func testBottomEdgeResizeRespectsMinimumHeight() {
        let frame = CGRect(x: 100, y: 100, width: 440, height: 520)
        let result = WindowResizeRegion.resizedFrame(
            frame,
            region: [.bottom],
            delta: CGSize(width: 0, height: 300),
            minimumSize: minimumSize
        )

        XCTAssertEqual(result, CGRect(x: 100, y: 300, width: 440, height: 320))
    }
}
