import Foundation

public enum PaperTexture {
    public enum Appearance {
        case light
        case dark

        public var baseColor: ColorSample {
            switch self {
            case .light:
                ColorSample(red: 0.965, green: 0.945, blue: 0.895)
            case .dark:
                ColorSample(red: 0.135, green: 0.125, blue: 0.105)
            }
        }

        public var maxDelta: Double {
            switch self {
            case .light:
                0.035
            case .dark:
                0.018
            }
        }
    }

    public struct ColorSample: Equatable {
        public let red: Double
        public let green: Double
        public let blue: Double

        public init(red: Double, green: Double, blue: Double) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }

    private static let seed: UInt32 = 0xC1A0_7EAF

    public static func sample(appearance: Appearance, x: Int, y: Int) -> ColorSample {
        let base = appearance.baseColor
        let grain = fractalNoise(x: x, y: y)
        let delta = (grain - 0.5) * 2.0 * appearance.maxDelta
        let fiber = (valueNoise(x: x / 9, y: y / 3, octave: 7) - 0.5) * appearance.maxDelta * 0.35
        let total = delta + fiber

        return ColorSample(
            red: clamp(base.red + total),
            green: clamp(base.green + total),
            blue: clamp(base.blue + total)
        )
    }

    private static func fractalNoise(x: Int, y: Int) -> Double {
        let first = valueNoise(x: x, y: y, octave: 0)
        let second = valueNoise(x: x / 2, y: y / 2, octave: 1)
        let third = valueNoise(x: x / 5, y: y / 5, octave: 2)
        let fourth = valueNoise(x: x / 13, y: y / 13, octave: 3)
        return first * 0.42 + second * 0.28 + third * 0.20 + fourth * 0.10
    }

    private static func valueNoise(x: Int, y: Int, octave: UInt32) -> Double {
        var value = UInt32(truncatingIfNeeded: x &* 374_761_393)
        value &+= UInt32(truncatingIfNeeded: y &* 668_265_263)
        value &+= seed
        value &+= octave &* 2_246_822_519
        value = (value ^ (value >> 13)) &* 1_274_126_177
        value ^= value >> 16
        return Double(value) / Double(UInt32.max)
    }

    private static func clamp(_ value: Double) -> Double {
        min(1.0, max(0.0, value))
    }
}
