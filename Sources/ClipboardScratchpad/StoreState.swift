import Foundation

struct StoreState: Codable {
    var noteText: String
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
