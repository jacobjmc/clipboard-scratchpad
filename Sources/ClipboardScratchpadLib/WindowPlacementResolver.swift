import CoreGraphics
import Foundation

public enum WindowPlacementResolver {
    public static let defaultGapBelowAnchor: CGFloat = 4

    public static func resolve(
        savedFrame: CGRect,
        screenFrames: [CGRect],
        fallbackFrame: CGRect
    ) -> CGRect {
        let minVisibleArea: CGFloat = 100 * 100
        for screen in screenFrames {
            let intersection = savedFrame.intersection(screen)
            if intersection.width * intersection.height >= minVisibleArea {
                return savedFrame
            }
        }
        return fallbackFrame
    }

    public static func defaultFrame(
        below anchorFrame: CGRect,
        contentSize: CGSize,
        gap: CGFloat = defaultGapBelowAnchor
    ) -> CGRect {
        CGRect(
            x: anchorFrame.midX - contentSize.width / 2,
            y: anchorFrame.minY - contentSize.height - gap,
            width: contentSize.width,
            height: contentSize.height
        )
    }
}
