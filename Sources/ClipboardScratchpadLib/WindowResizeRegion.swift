import CoreGraphics
import Foundation

public struct WindowResizeRegion: OptionSet, Equatable {
    public let rawValue: Int

    public static let left = WindowResizeRegion(rawValue: 1 << 0)
    public static let right = WindowResizeRegion(rawValue: 1 << 1)
    public static let bottom = WindowResizeRegion(rawValue: 1 << 2)
    public static let top = WindowResizeRegion(rawValue: 1 << 3)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static func region(
        for point: CGPoint,
        contentSize: CGSize,
        edgeThickness: CGFloat = 16
    ) -> WindowResizeRegion? {
        var region: WindowResizeRegion = []

        if point.x <= edgeThickness {
            region.insert(.left)
        } else if point.x >= contentSize.width - edgeThickness {
            region.insert(.right)
        }

        if point.y <= edgeThickness {
            region.insert(.bottom)
        } else if point.y >= contentSize.height - edgeThickness {
            region.insert(.top)
        }

        return region.isEmpty ? nil : region
    }

    public static func resizedFrame(
        _ frame: CGRect,
        region: WindowResizeRegion,
        delta: CGSize,
        minimumSize: CGSize
    ) -> CGRect {
        var next = frame

        if region.contains(.right) {
            next.size.width = max(minimumSize.width, frame.width + delta.width)
        }

        if region.contains(.left) {
            let proposedWidth = frame.width - delta.width
            let width = max(minimumSize.width, proposedWidth)
            next.origin.x = frame.maxX - width
            next.size.width = width
        }

        if region.contains(.top) {
            next.size.height = max(minimumSize.height, frame.height + delta.height)
        }

        if region.contains(.bottom) {
            let proposedHeight = frame.height - delta.height
            let height = max(minimumSize.height, proposedHeight)
            next.origin.y = frame.maxY - height
            next.size.height = height
        }

        return next
    }
}
