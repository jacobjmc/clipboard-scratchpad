public struct ScratchpadPresentationState: Equatable {
    public enum Mode: Equatable {
        case popover
        case floatingWindow
    }

    public enum Visibility: Equatable {
        case hidden
        case visible
    }

    public var mode: Mode
    public var visibility: Visibility

    public init(mode: Mode = .popover, visibility: Visibility = .hidden) {
        self.mode = mode
        self.visibility = visibility
    }

    public mutating func menuBarItemClicked() {
        visibility = visibility == .visible ? .hidden : .visible
    }

    public mutating func pinChanged(isPinned: Bool) {
        mode = isPinned ? .floatingWindow : .popover
        visibility = .visible
    }

    public mutating func popoverDetached() {
        visibility = .visible
    }

    public mutating func windowClosed() {
        visibility = .hidden
    }

    public mutating func outsideClicked() {
        guard mode == .popover else { return }
        visibility = .hidden
    }
}
