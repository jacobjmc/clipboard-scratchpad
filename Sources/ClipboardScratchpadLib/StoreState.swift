import CoreGraphics
import Foundation

public struct ClipShelfItem: Codable, Identifiable, Equatable {
    public let id: UUID
    public let content: String
    public let capturedAt: Date
    public let sourceAppName: String?
    public let sourceBundleID: String?

    public init(id: UUID, content: String, capturedAt: Date, sourceAppName: String?, sourceBundleID: String?) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
        self.sourceAppName = sourceAppName
        self.sourceBundleID = sourceBundleID
    }
}

public struct StoreState: Codable {
    public var noteText: String
    public var updatedAt: Date?
    public var clips: [ClipShelfItem]
    public var windowFrame: CGRect?
    public var globalShortcut: GlobalKeyboardShortcut?
    public var appearancePreference: AppearancePreference
    public var paperFinishEnabled: Bool

    public init(
        noteText: String,
        updatedAt: Date? = nil,
        clips: [ClipShelfItem] = [],
        windowFrame: CGRect? = nil,
        globalShortcut: GlobalKeyboardShortcut? = nil,
        appearancePreference: AppearancePreference = .system,
        paperFinishEnabled: Bool = true
    ) {
        self.noteText = noteText
        self.updatedAt = updatedAt
        self.clips = clips
        self.windowFrame = windowFrame
        self.globalShortcut = globalShortcut
        self.appearancePreference = appearancePreference
        self.paperFinishEnabled = paperFinishEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case noteText
        case updatedAt
        case clips
        case windowFrame
        case globalShortcut
        case appearancePreference
        case paperFinishEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        noteText = try container.decode(String.self, forKey: .noteText)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        clips = try container.decodeIfPresent([ClipShelfItem].self, forKey: .clips) ?? []
        windowFrame = try container.decodeIfPresent(CGRect.self, forKey: .windowFrame)
        globalShortcut = try container.decodeIfPresent(GlobalKeyboardShortcut.self, forKey: .globalShortcut)
        appearancePreference = try container.decodeIfPresent(AppearancePreference.self, forKey: .appearancePreference) ?? .system
        paperFinishEnabled = try container.decodeIfPresent(Bool.self, forKey: .paperFinishEnabled) ?? true
    }
}

// MARK: - Legacy migration types

public struct LegacyManualBlock: Codable {
    public let id: UUID
    public let timestamp: Date
    public let content: String
}

public struct LegacyCapturedBlock: Codable {
    public let id: UUID
    public let timestamp: Date
    public let content: String
    public let sourceAppName: String?
    public let sourceBundleID: String?
}

public enum LegacyScratchBlock: Codable {
    case manual(LegacyManualBlock)
    case captured(LegacyCapturedBlock)
}
