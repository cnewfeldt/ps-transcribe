import Foundation

enum Speaker: String, Codable, Sendable {
    case you
    case them
}

enum SessionType: String, Codable, Sendable {
    case callCapture
    case voiceMemo
}

struct LibraryEntry: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String?
    let sessionType: SessionType
    let startDate: Date
    var duration: TimeInterval
    var filePath: String
    let sourceApp: String
    var isFinalized: Bool
    var firstLinePreview: String?
    var notionPageURL: String?  // set after successful Notion send

    var displayName: String {
        if let name, !name.isEmpty { return name }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d, yyyy"
        let dateStr = fmt.string(from: startDate)
        return sessionType == .callCapture
            ? "Call Recording -- \(dateStr)"
            : "Voice Memo -- \(dateStr)"
    }
}

struct Utterance: Identifiable, Codable, Sendable {
    let id: UUID
    let text: String
    let speaker: Speaker
    let timestamp: Date

    init(text: String, speaker: Speaker, timestamp: Date = .now) {
        self.id = UUID()
        self.text = text
        self.speaker = speaker
        self.timestamp = timestamp
    }
}

// MARK: - Session Record

/// Codable record for JSONL session persistence
struct SessionRecord: Codable {
    let speaker: Speaker
    let text: String
    let timestamp: Date

    init(speaker: Speaker, text: String, timestamp: Date) {
        self.speaker = speaker
        self.text = text
        self.timestamp = timestamp
    }
}
