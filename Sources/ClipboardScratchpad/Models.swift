import Foundation

struct ManualBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: Date
    var content: String
}

struct CapturedBlock: Identifiable, Codable, Equatable {
    let id: UUID
    var timestamp: Date
    var content: String
    var sourceAppName: String?
    var sourceBundleID: String?
}

enum ScratchBlock: Identifiable, Codable, Equatable {
    case manual(ManualBlock)
    case captured(CapturedBlock)

    var id: UUID {
        switch self {
        case .manual(let block): return block.id
        case .captured(let block): return block.id
        }
    }

    var content: String {
        switch self {
        case .manual(let block): return block.content
        case .captured(let block): return block.content
        }
    }

    var timestamp: Date {
        switch self {
        case .manual(let block): return block.timestamp
        case .captured(let block): return block.timestamp
        }
    }
}
