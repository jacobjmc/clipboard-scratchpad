import Foundation

struct StoreState: Codable {
    var noteText: String
}

// MARK: - Legacy migration types

enum LegacyScratchBlock: Codable {
    case manual(id: UUID, timestamp: Date, content: String)
    case captured(id: UUID, timestamp: Date, content: String, sourceApp: String?)
}
