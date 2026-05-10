import XCTest
@testable import ClipboardScratchpadLib

final class WindowDragRegionTests: XCTestCase {
    private let contentSize = CGSize(width: 440, height: 520)

    func testTopHeaderBackgroundIsDraggable() {
        XCTAssertTrue(WindowDragRegion.isDraggable(
            point: CGPoint(x: 120, y: 505),
            contentSize: contentSize
        ))
    }

    func testBodyIsNotDraggable() {
        XCTAssertFalse(WindowDragRegion.isDraggable(
            point: CGPoint(x: 120, y: 470),
            contentSize: contentSize
        ))
    }

    func testTrailingHeaderControlsAreNotDraggable() {
        XCTAssertFalse(WindowDragRegion.isDraggable(
            point: CGPoint(x: 410, y: 505),
            contentSize: contentSize
        ))
    }

    func testWindowMovementPreservesSize() {
        let frame = CGRect(x: 100, y: 200, width: 440, height: 520)

        let moved = WindowDragRegion.movedFrame(
            frame,
            from: CGPoint(x: 20, y: 510),
            to: CGPoint(x: 40, y: 500)
        )

        XCTAssertEqual(moved.origin, CGPoint(x: 120, y: 190))
        XCTAssertEqual(moved.size, frame.size)
    }
}
