import Foundation

struct ClipShelfItem: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let capturedAt: Date
    let sourceAppName: String?
    let sourceBundleID: String?
}

struct StoreState: Codable {
    var noteText: String
    var updatedAt: Date?
    var clips: [ClipShelfItem]

    init(noteText: String, updatedAt: Date? = nil, clips: [ClipShelfItem] = []) {
        self.noteText = noteText
        self.updatedAt = updatedAt
        self.clips = clips
    }

    private enum CodingKeys: String, CodingKey {
        case noteText
        case updatedAt
        case clips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        noteText = try container.decode(String.self, forKey: .noteText)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        clips = try container.decodeIfPresent([ClipShelfItem].self, forKey: .clips) ?? []
    }
}

// MARK: - Legacy migration types

struct LegacyManualBlock: Codable {
    let id: UUID
    let timestamp: Date
    let content: String
}

struct LegacyCapturedBlock: Codable {
    let id: UUID
    let timestamp: Date
    let content: String
    let sourceAppName: String?
    let sourceBundleID: String?
}

enum LegacyScratchBlock: Codable {
    case manual(LegacyManualBlock)
    case captured(LegacyCapturedBlock)
}
