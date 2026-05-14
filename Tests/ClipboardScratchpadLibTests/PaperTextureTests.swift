import XCTest
@testable import ClipboardScratchpadLib

final class PaperTextureTests: XCTestCase {
    func testSamplesAreDeterministic() {
        let first = PaperTexture.sample(appearance: .light, x: 12, y: 34)
        let second = PaperTexture.sample(appearance: .light, x: 12, y: 34)

        XCTAssertEqual(first, second)
    }

    func testLightAndDarkSamplesUseDifferentBaseRanges() {
        let light = PaperTexture.sample(appearance: .light, x: 24, y: 48)
        let dark = PaperTexture.sample(appearance: .dark, x: 24, y: 48)

        XCTAssertGreaterThan(light.red, dark.red)
        XCTAssertGreaterThan(light.green, dark.green)
        XCTAssertGreaterThan(light.blue, dark.blue)
    }

    func testSamplesStayWithinSubtleContrastBounds() {
        let lightBase = PaperTexture.Appearance.light.baseColor
        let darkBase = PaperTexture.Appearance.dark.baseColor

        for coordinate in stride(from: 0, through: 128, by: 16) {
            let light = PaperTexture.sample(appearance: .light, x: coordinate, y: coordinate / 2)
            let dark = PaperTexture.sample(appearance: .dark, x: coordinate, y: coordinate / 2)

            XCTAssertLessThanOrEqual(abs(light.red - lightBase.red), PaperTexture.Appearance.light.maxDelta)
            XCTAssertLessThanOrEqual(abs(light.green - lightBase.green), PaperTexture.Appearance.light.maxDelta)
            XCTAssertLessThanOrEqual(abs(light.blue - lightBase.blue), PaperTexture.Appearance.light.maxDelta)
            XCTAssertLessThanOrEqual(abs(dark.red - darkBase.red), PaperTexture.Appearance.dark.maxDelta)
            XCTAssertLessThanOrEqual(abs(dark.green - darkBase.green), PaperTexture.Appearance.dark.maxDelta)
            XCTAssertLessThanOrEqual(abs(dark.blue - darkBase.blue), PaperTexture.Appearance.dark.maxDelta)
        }
    }
}
