import XCTest
@testable import ClipboardScratchpadLib

final class StoreStateTests: XCTestCase {
    func testDecodesJSONWithoutWindowFrame() throws {
        let json = """
        {
            "noteText": "Hello",
            "updatedAt": 1704067200.0,
            "clips": []
        }
        """
        let data = Data(json.utf8)
        let state = try JSONDecoder().decode(StoreState.self, from: data)
        XCTAssertEqual(state.noteText, "Hello")
        XCTAssertEqual(state.clips.count, 0)
        XCTAssertNil(state.windowFrame)
    }

    func testRoundTripsWithWindowFrame() throws {
        let state = StoreState(
            noteText: "Hello",
            updatedAt: Date(timeIntervalSince1970: 1000),
            clips: [],
            windowFrame: CGRect(x: 10, y: 20, width: 440, height: 520)
        )
        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(StoreState.self, from: data)
        XCTAssertEqual(decoded.windowFrame, CGRect(x: 10, y: 20, width: 440, height: 520))
    }

    func testEncodedStateDoesNotPersistPinMode() throws {
        let state = StoreState(
            noteText: "Hello",
            clips: [],
            windowFrame: CGRect(x: 10, y: 20, width: 440, height: 520)
        )

        let data = try JSONEncoder().encode(state)
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertFalse(json.contains("isPinned"))
        XCTAssertFalse(json.contains("floatingFrame"))
        XCTAssertTrue(json.contains("windowFrame"))
    }

    func testDecodesJSONWithWindowFrame() throws {
        let json = """
        {
            "noteText": "Hello",
            "updatedAt": 1704067200.0,
            "clips": [],
            "windowFrame": [[100,200],[440,520]]
        }
        """
        let data = Data(json.utf8)
        let state = try JSONDecoder().decode(StoreState.self, from: data)
        XCTAssertEqual(state.windowFrame, CGRect(x: 100, y: 200, width: 440, height: 520))
    }

    func testDoesNotDecodeOldFloatingFrameKey() throws {
        let json = """
        {
            "noteText": "Hello",
            "updatedAt": 1704067200.0,
            "clips": [],
            "floatingFrame": [[100,200],[440,520]]
        }
        """
        let data = Data(json.utf8)
        let state = try JSONDecoder().decode(StoreState.self, from: data)
        XCTAssertNil(state.windowFrame)
    }
}
