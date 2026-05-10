import CoreGraphics
import Foundation

public enum WindowDragRegion {
    public static let headerHeight: CGFloat = 32
    public static let trailingControlsWidth: CGFloat = 104

    public static func isDraggable(point: CGPoint, contentSize: CGSize) -> Bool {
        guard point.y >= contentSize.height - headerHeight else { return false }
        return point.x < contentSize.width - trailingControlsWidth
    }

    public static func movedFrame(_ frame: CGRect, from start: CGPoint, to current: CGPoint) -> CGRect {
        var moved = frame
        moved.origin.x += current.x - start.x
        moved.origin.y += current.y - start.y
        return moved
    }
}
