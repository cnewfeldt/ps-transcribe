import Foundation

enum Speaker: Codable, Sendable, Equatable {
    case you
    case them
    case named(String)

    enum CodingKeys: String, CodingKey { case type, label }

    init(from decoder: Decoder) throws {
        // Legacy: bare string format ("you" / "them") from old RawRepresentable encoding
        if let sv = try? decoder.singleValueContainer(),
           let raw = try? sv.decode(String.self) {
            switch raw {
            case "you":  self = .you
            case "them": self = .them
            default:     self = .them
            }
            return
        }
        // New: keyed container format
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(String.self, forKey: .type)
        switch type {
        case "you":   self = .you
        case "them":  self = .them
        case "named": self = .named(try c.decode(String.self, forKey: .label))
        default:      self = .them
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .you:
            try c.encode("you", forKey: .type)
        case .them:
            try c.encode("them", forKey: .type)
        case .named(let label):
            try c.encode("named", forKey: .type)
            try c.encode(label, forKey: .label)
        }
    }

    /// String representation for logging and display.
    var rawValue: String {
        switch self {
        case .you:              return "you"
        case .them:             return "them"
        case .named(let label): return label
        }
    }
}

enum SessionType: String, Codable, Sendable {
    case callCapture
    case voiceMemo
    case dictation  // Phase 16, D-09
}

// MARK: - v1.2 Dictation Modes (Phase 16, D-10 / D-11)

/// Where dictation transcripts are written when a hotkey-triggered dictation session ends.
/// Default is `.clipboard` (D-08): plain folder is opt-in so no files appear on disk
/// without explicit user action.
enum DictationOutputMode: String, Codable, Sendable {
    case clipboard
    case plainFolder
    case both
}

/// Hotkey activation model. `.toggle` (default) starts on first tap, stops on second.
/// `.pressAndHold` records only while the hotkey is held down.
enum DictationHotkeyMode: String, Codable, Sendable {
    case toggle
    case pressAndHold
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
