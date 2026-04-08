import Foundation

/// Parses a markdown transcript file written by TranscriptLogger into an array of Utterance.
///
/// The expected format is:
/// ```
/// ---
/// (YAML frontmatter)
/// ---
///
/// **Speaker** (HH:mm:ss)
/// text
///
/// ```
func parseTranscript(at url: URL) throws -> [Utterance] {
    let content = try String(contentsOf: url, encoding: .utf8)
    return parseTranscriptContent(content)
}

/// Internal parse function exposed for testing without disk I/O.
func parseTranscriptContent(_ content: String) -> [Utterance] {
    // Skip YAML frontmatter: find the second occurrence of "---" on its own line
    let lines = content.components(separatedBy: "\n")
    var bodyStart = 0
    var dashCount = 0
    for (i, line) in lines.enumerated() {
        if line.trimmingCharacters(in: .whitespaces) == "---" {
            dashCount += 1
            if dashCount == 2 {
                bodyStart = i + 1
                break
            }
        }
    }
    let body = lines[bodyStart...].joined(separator: "\n")

    // Match: **Speaker** (HH:mm:ss)\ntext\n\n
    // Speaker can be "You", "Them", or "Speaker N"
    let pattern = #"\*\*(You|Them|Speaker \d+)\*\* \((\d{2}:\d{2}:\d{2})\)\n(.*?)(?=\n\n|\z)"#
    guard let regex = try? NSRegularExpression(
        pattern: pattern,
        options: [.dotMatchesLineSeparators]
    ) else { return [] }

    let nsBody = body as NSString
    let matches = regex.matches(in: body, range: NSRange(location: 0, length: nsBody.length))

    return matches.compactMap { match -> Utterance? in
        guard match.numberOfRanges == 4 else { return nil }

        let speakerStr = nsBody.substring(with: match.range(at: 1))
        let timeStr = nsBody.substring(with: match.range(at: 2))
        let textRange = match.range(at: 3)
        guard textRange.location != NSNotFound else { return nil }
        let text = nsBody.substring(with: textRange).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { return nil }

        let speaker: Speaker
        switch speakerStr {
        case "You":  speaker = .you
        case "Them": speaker = .them
        default:     speaker = .named(speakerStr)
        }

        // Parse HH:mm:ss into a Date offset from distantPast
        let parts = timeStr.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        let offsetSeconds = TimeInterval(parts[0] * 3600 + parts[1] * 60 + parts[2])
        let timestamp = Date.distantPast.addingTimeInterval(offsetSeconds)

        return Utterance(text: text, speaker: speaker, timestamp: timestamp)
    }
}

/// Derives the Obsidian vault name from a vault subfolder path.
/// Given "/Users/cary/Documents/MyVault/Meetings", returns "MyVault".
/// Returns nil if the path is empty or has no meaningful parent.
func obsidianVaultName(from vaultSubPath: String) -> String? {
    guard !vaultSubPath.isEmpty else { return nil }
    let url = URL(fileURLWithPath: vaultSubPath)
    let name = url.deletingLastPathComponent().lastPathComponent
    // Guard against root paths where lastPathComponent is "/" or empty
    guard !name.isEmpty, name != "/" else { return nil }
    return name
}

/// Constructs an obsidian://open URL for a transcript file.
/// - Parameters:
///   - filePath: Absolute path to the transcript file on disk
///   - vaultRoot: Absolute path to the Obsidian vault root directory
///   - vaultName: Name of the Obsidian vault (typically vaultRoot's lastPathComponent)
/// - Returns: An obsidian://open URL with vault and file query parameters, or nil if inputs are invalid
func makeObsidianURL(filePath: String, vaultRoot: String, vaultName: String) -> URL? {
    guard !filePath.isEmpty,
          !vaultRoot.isEmpty,
          !vaultName.isEmpty,
          filePath.hasPrefix(vaultRoot) else { return nil }

    // Strip vault root prefix and leading separator to get vault-relative path
    var relative = String(filePath.dropFirst(vaultRoot.count))
    if relative.hasPrefix("/") { relative = String(relative.dropFirst()) }
    guard !relative.isEmpty else { return nil }

    var components = URLComponents()
    components.scheme = "obsidian"
    components.host = "open"
    components.queryItems = [
        URLQueryItem(name: "vault", value: vaultName),
        URLQueryItem(name: "file", value: relative)
    ]
    return components.url
}
