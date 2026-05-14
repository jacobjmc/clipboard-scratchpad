import SwiftUI
import AppKit
import ClipboardScratchpadLib

struct ScratchpadRootView: View {
    @ObservedObject var store: ScratchpadStore

    var body: some View {
        ContentView()
            .environmentObject(store)
            .preferredColorScheme(store.appearancePreference.colorScheme)
    }
}

extension AppearancePreference {
    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var nsAppearance: NSAppearance? {
        switch self {
        case .system:
            return nil
        case .light:
            return NSAppearance(named: .aqua)
        case .dark:
            return NSAppearance(named: .darkAqua)
        }
    }
}
