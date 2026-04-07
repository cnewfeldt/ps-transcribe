import Foundation
import os

/// Errors thrown by NotionService operations.
enum NotionError: Error, LocalizedError {
    case notAuthenticated
    case invalidResponse
    case httpError(statusCode: Int, message: String)
    case rateLimited(retryAfter: TimeInterval)
    case invalidDatabaseID

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Notion API key is not configured."
        case .invalidResponse:
            return "Received an unexpected response from Notion."
        case .httpError(let code, let message):
            return "Notion API error \(code): \(message)"
        case .rateLimited(let retryAfter):
            return "Notion is busy. Retry after \(Int(retryAfter)) seconds."
        case .invalidDatabaseID:
            return "The database ID format is invalid."
        }
    }
}

/// Actor that handles all Notion API interactions: authentication, database validation,
/// transcript conversion, and page creation.
actor NotionService {
    private let baseURL = "https://api.notion.com/v1"
    private let apiVersion = "2022-06-28"
    private let keychainService = "com.pstranscribe.app"
    private let keychainKey = "notion-api-key"

    private let logger = Logger(subsystem: "com.pstranscribe.app", category: "NotionService")

    /// The name of the title property in the connected database (default "Name", may vary)
    private(set) var titlePropertyName: String = "Name"

    // MARK: - Keychain-backed API key

    func apiKey() -> String? {
        guard let data = KeychainHelper.read(key: keychainKey, service: keychainService) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func setApiKey(_ key: String) throws {
        guard let data = key.data(using: .utf8) else { return }
        try KeychainHelper.save(key: keychainKey, service: keychainService, data: data)
    }

    func deleteApiKey() throws {
        try KeychainHelper.delete(key: keychainKey, service: keychainService)
    }

    // MARK: - Connection validation

    /// Validates the stored API key by calling /v1/users/me.
    /// Returns the workspace name on success.
    func testConnection() async throws -> String {
        guard let key = apiKey() else { throw NotionError.notAuthenticated }
        let url = URL(string: "\(baseURL)/users/me")!
        let request = makeRequest(url: url, method: "GET", apiKey: key)
        let (data, response) = try await performRequest(request)
        try checkHTTPStatus(response, data: data)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let bot = json["bot"] as? [String: Any],
              let workspace = bot["workspace_name"] as? String else {
            // Fall back to any workspace_name field at root level (some API responses differ)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let name = json["name"] as? String {
                return name
            }
            throw NotionError.invalidResponse
        }
        return workspace
    }

    /// Validates a database ID by fetching the database metadata.
    /// Returns the database title on success.
    func validateDatabase(id: String) async throws -> String {
        guard let key = apiKey() else { throw NotionError.notAuthenticated }
        let cleanID = cleanDatabaseID(id)
        guard !cleanID.isEmpty else { throw NotionError.invalidDatabaseID }
        let url = URL(string: "\(baseURL)/databases/\(cleanID)")!
        let request = makeRequest(url: url, method: "GET", apiKey: key)
        let (data, response) = try await performRequest(request)
        try checkHTTPStatus(response, data: data)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NotionError.invalidResponse
        }

        // Detect the title property name
        let existingProps = (json["properties"] as? [String: Any]) ?? [:]
        for (name, value) in existingProps {
            if let propDict = value as? [String: Any],
               let type = propDict["type"] as? String,
               type == "title" {
                titlePropertyName = name
                logger.info("Title property detected as: \(name)")
                break
            }
        }

        return extractDatabaseTitle(from: json)
    }


    // MARK: - Page management

    /// Archives (soft-deletes) a Notion page by URL.
    func archivePage(urlString: String) async throws {
        guard let key = apiKey() else { throw NotionError.notAuthenticated }
        let pageID = extractPageID(from: urlString)
        guard !pageID.isEmpty else { return }

        let url = URL(string: "\(baseURL)/pages/\(pageID)")!
        var request = makeRequest(url: url, method: "PATCH", apiKey: key)
        let body: [String: Any] = ["archived": true]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await performRequest(request)
        try checkHTTPStatus(response, data: data)
        logger.info("Archived Notion page: \(pageID)")
    }

    /// Updates an existing Notion page with fresh transcript content.
    /// Fetches database schema to detect title property name and available properties.
    func updateTranscript(
        pageURLString: String,
        databaseID: String,
        title: String,
        date: Date,
        duration: TimeInterval,
        sourceApp: String,
        sessionType: String,
        speakers: [String],
        tags: [String],
        transcriptMarkdown: String
    ) async throws {
        guard let key = apiKey() else { throw NotionError.notAuthenticated }
        let pageID = extractPageID(from: pageURLString)
        guard !pageID.isEmpty else { return }
        let cleanID = cleanDatabaseID(databaseID)

        // Fetch database schema for property detection (same as sendTranscript)
        let dbURL = URL(string: "\(baseURL)/databases/\(cleanID)")!
        let dbRequest = makeRequest(url: dbURL, method: "GET", apiKey: key)
        var availableProps = Set<String>()
        var detectedTitleProp = "Name"
        if let (dbData, _) = try? await URLSession.shared.data(for: dbRequest),
           let dbJSON = try? JSONSerialization.jsonObject(with: dbData) as? [String: Any],
           let props = dbJSON["properties"] as? [String: Any] {
            availableProps = Set(props.keys)
            for (name, value) in props {
                if let propDict = value as? [String: Any],
                   let type = propDict["type"] as? String,
                   type == "title" {
                    detectedTitleProp = name
                    break
                }
            }
        }

        let allBlocks = transcriptToBlocks(transcriptMarkdown)
        let allProperties = buildProperties(
            title: title, date: date, duration: duration,
            sourceApp: sourceApp, sessionType: sessionType,
            speakers: speakers, tags: tags,
            titlePropertyName: detectedTitleProp
        )

        // Filter to available properties
        var properties: [String: Any] = [:]
        for (k, v) in allProperties {
            if availableProps.isEmpty || availableProps.contains(k) {
                properties[k] = v
            }
        }

        // 1. Update properties
        let pageURL = URL(string: "\(baseURL)/pages/\(pageID)")!
        var propRequest = makeRequest(url: pageURL, method: "PATCH", apiKey: key)
        propRequest.httpBody = try JSONSerialization.data(withJSONObject: ["properties": properties])
        let (propData, propResponse) = try await performRequest(propRequest)
        try checkHTTPStatus(propResponse, data: propData)

        // 2. Delete existing child blocks
        let childrenURL = URL(string: "\(baseURL)/blocks/\(pageID)/children?page_size=100")!
        let listRequest = makeRequest(url: childrenURL, method: "GET", apiKey: key)
        let (listData, listResponse) = try await performRequest(listRequest)
        try checkHTTPStatus(listResponse, data: listData)

        if let listJSON = try? JSONSerialization.jsonObject(with: listData) as? [String: Any],
           let results = listJSON["results"] as? [[String: Any]] {
            for block in results {
                if let blockID = block["id"] as? String {
                    let deleteURL = URL(string: "\(baseURL)/blocks/\(blockID)")!
                    let deleteRequest = makeRequest(url: deleteURL, method: "DELETE", apiKey: key)
                    let (_, deleteResponse) = try await performRequest(deleteRequest)
                    // Ignore 404s (already deleted)
                    if deleteResponse.statusCode != 404 {
                        try checkHTTPStatus(deleteResponse, data: Data())
                    }
                }
            }
        }

        // 3. Add new blocks
        try await appendBlocks(pageID: pageID, blocks: allBlocks, apiKey: key)
        logger.info("Updated Notion page: \(pageID)")
    }

    /// Extracts a 32-hex-char page ID from a Notion URL.
    private nonisolated func extractPageID(from urlString: String) -> String {
        let cleaned = urlString.components(separatedBy: "?").first ?? urlString
        let pattern = #"([a-f0-9]{32}|[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.matches(in: cleaned, range: NSRange(location: 0, length: (cleaned as NSString).length)).last else {
            return ""
        }
        return (cleaned as NSString).substring(with: match.range(at: 1)).replacingOccurrences(of: "-", with: "")
    }

    // MARK: - Core send

    /// Converts a transcript and creates a Notion database page.
    /// Returns the URL of the created page.
    func sendTranscript(
        databaseID: String,
        title: String,
        date: Date,
        duration: TimeInterval,
        sourceApp: String,
        sessionType: String,
        speakers: [String],
        tags: [String],
        transcriptMarkdown: String
    ) async throws -> URL {
        guard let key = apiKey() else { throw NotionError.notAuthenticated }
        let cleanID = cleanDatabaseID(databaseID)
        guard !cleanID.isEmpty else { throw NotionError.invalidDatabaseID }

        // Fetch database schema to know which properties exist
        let dbURL = URL(string: "\(baseURL)/databases/\(cleanID)")!
        let dbRequest = makeRequest(url: dbURL, method: "GET", apiKey: key)
        var availableProps = Set<String>()
        var detectedTitleProp = titlePropertyName
        if let (dbData, _) = try? await URLSession.shared.data(for: dbRequest),
           let dbJSON = try? JSONSerialization.jsonObject(with: dbData) as? [String: Any],
           let props = dbJSON["properties"] as? [String: Any] {
            availableProps = Set(props.keys)
            logger.info("Database properties: \(availableProps.sorted())")
            // Detect title property name
            for (name, value) in props {
                if let propDict = value as? [String: Any],
                   let type = propDict["type"] as? String,
                   type == "title" {
                    detectedTitleProp = name
                    break
                }
            }
        }

        let allBlocks = transcriptToBlocks(transcriptMarkdown)
        let allProperties = buildProperties(
            title: title,
            date: date,
            duration: duration,
            sourceApp: sourceApp,
            sessionType: sessionType,
            speakers: speakers,
            tags: tags,
            titlePropertyName: detectedTitleProp
        )

        // Only include properties that exist on the database -- skip unknown ones
        var properties: [String: Any] = [:]
        for (key, value) in allProperties {
            if availableProps.isEmpty || availableProps.contains(key) {
                properties[key] = value
            } else {
                logger.info("Skipping property '\(key)' -- not on database")
            }
        }

        // First 100 blocks go in the initial page creation
        let firstBatch = Array(allBlocks.prefix(100))
        let body: [String: Any] = [
            "parent": ["database_id": cleanID],
            "properties": properties,
            "children": firstBatch,
        ]

        let url = URL(string: "\(baseURL)/pages")!
        var request = makeRequest(url: url, method: "POST", apiKey: key)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await performRequest(request)
        try checkHTTPStatus(response, data: data)

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pageID = json["id"] as? String,
              let urlString = json["url"] as? String,
              let pageURL = URL(string: urlString) else {
            throw NotionError.invalidResponse
        }

        // Append remaining blocks in batches of 100
        if allBlocks.count > 100 {
            let remaining = Array(allBlocks.dropFirst(100))
            try await appendBlocks(pageID: pageID, blocks: remaining, apiKey: key)
        }

        logger.info("Created Notion page: \(pageURL.absoluteString)")
        return pageURL
    }

    // MARK: - Internal helpers (internal access for testing)

    /// Converts a markdown transcript string into an array of Notion block dictionaries.
    ///
    /// Conversion rules:
    /// - YAML frontmatter (between first two `---` lines) is stripped
    /// - `**Speaker** (HH:mm:ss)` lines become a paragraph block with bold rich_text
    /// - Non-empty plain-text lines become paragraph blocks with plain rich_text
    /// - Empty lines are skipped
    /// - `---` lines outside frontmatter become divider blocks
    nonisolated func transcriptToBlocks(_ markdown: String) -> [[String: Any]] {
        let lines = markdown.components(separatedBy: "\n")

        // Strip YAML frontmatter
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

        let bodyLines = Array(lines[bodyStart...])

        // Speaker line pattern: **SpeakerName** (HH:mm:ss)
        let speakerPattern = try? NSRegularExpression(pattern: #"^\*\*(.+?)\*\* \((\d{2}:\d{2}:\d{2})\)$"#)

        var blocks: [[String: Any]] = []
        for line in bodyLines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                continue
            }

            if trimmed == "---" {
                blocks.append(["object": "block", "type": "divider", "divider": [:]])
                continue
            }

            // Headings: # H1, ## H2, ### H3
            if trimmed.hasPrefix("# ") {
                let text = String(trimmed.dropFirst(2))
                blocks.append([
                    "object": "block",
                    "type": "heading_1",
                    "heading_1": ["rich_text": parseInlineBold(text)],
                ])
                continue
            }
            if trimmed.hasPrefix("## ") {
                let text = String(trimmed.dropFirst(3))
                blocks.append([
                    "object": "block",
                    "type": "heading_2",
                    "heading_2": ["rich_text": parseInlineBold(text)],
                ])
                continue
            }
            if trimmed.hasPrefix("### ") {
                let text = String(trimmed.dropFirst(4))
                blocks.append([
                    "object": "block",
                    "type": "heading_3",
                    "heading_3": ["rich_text": parseInlineBold(text)],
                ])
                continue
            }

            // Check if this is a speaker header line
            let nsLine = trimmed as NSString
            if let pattern = speakerPattern,
               let match = pattern.firstMatch(in: trimmed, range: NSRange(location: 0, length: nsLine.length)),
               match.numberOfRanges == 3 {
                let speaker = nsLine.substring(with: match.range(at: 1))
                let timestamp = nsLine.substring(with: match.range(at: 2))
                let boldText = "\(speaker) (\(timestamp))"

                let richText: [String: Any] = [
                    "type": "text",
                    "text": ["content": boldText],
                    "annotations": ["bold": true],
                ]
                blocks.append([
                    "object": "block",
                    "type": "paragraph",
                    "paragraph": ["rich_text": [richText]],
                ])
                continue
            }

            // Paragraph with inline bold parsing
            blocks.append([
                "object": "block",
                "type": "paragraph",
                "paragraph": ["rich_text": parseInlineBold(trimmed)],
            ])
        }

        return blocks
    }

    /// Parses inline **bold** markers into Notion rich_text segments.
    /// "Hello **world** today" becomes [{text:"Hello "}, {text:"world", bold:true}, {text:" today"}]
    private nonisolated func parseInlineBold(_ text: String) -> [[String: Any]] {
        let boldPattern = try? NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#)
        guard let pattern = boldPattern else {
            return [["type": "text", "text": ["content": text]]]
        }

        let ns = text as NSString
        let matches = pattern.matches(in: text, range: NSRange(location: 0, length: ns.length))

        if matches.isEmpty {
            return [["type": "text", "text": ["content": text]]]
        }

        var segments: [[String: Any]] = []
        var cursor = 0

        for match in matches {
            let fullRange = match.range
            // Text before the bold
            if fullRange.location > cursor {
                let before = ns.substring(with: NSRange(location: cursor, length: fullRange.location - cursor))
                segments.append(["type": "text", "text": ["content": before]])
            }
            // The bold text (group 1, without **)
            let boldText = ns.substring(with: match.range(at: 1))
            segments.append([
                "type": "text",
                "text": ["content": boldText],
                "annotations": ["bold": true],
            ])
            cursor = fullRange.location + fullRange.length
        }

        // Text after the last bold
        if cursor < ns.length {
            let after = ns.substring(from: cursor)
            segments.append(["type": "text", "text": ["content": after]])
        }

        return segments
    }

    /// Extracts unique speaker names from a markdown transcript.
    nonisolated func extractSpeakers(_ markdown: String) -> [String] {
        let speakerPattern = try? NSRegularExpression(pattern: #"^\*\*(.+?)\*\* \(\d{2}:\d{2}:\d{2}\)$"#, options: .anchorsMatchLines)
        guard let pattern = speakerPattern else { return [] }

        let ns = markdown as NSString
        let matches = pattern.matches(in: markdown, range: NSRange(location: 0, length: ns.length))

        var seen = Set<String>()
        var ordered = [String]()
        for match in matches where match.numberOfRanges == 2 {
            let name = ns.substring(with: match.range(at: 1))
            if seen.insert(name).inserted {
                ordered.append(name)
            }
        }
        return ordered
    }

    /// Builds the Notion page properties dictionary for the given session metadata.
    nonisolated func buildProperties(
        title: String,
        date: Date,
        duration: TimeInterval,
        sourceApp: String,
        sessionType: String,
        speakers: [String],
        tags: [String],
        titlePropertyName: String = "Name"
    ) -> [String: Any] {
        let dateStr = ISO8601DateFormatter().string(from: date).prefix(10).description // "YYYY-MM-DD"
        let durationStr = formatDuration(duration)

        return [
            titlePropertyName: [
                "title": [["type": "text", "text": ["content": title]]]
            ],
            "Date": [
                "date": ["start": dateStr]
            ],
            "Duration": [
                "rich_text": [["type": "text", "text": ["content": durationStr]]]
            ],
            "Source App": [
                "select": ["name": sourceApp]
            ],
            "Session Type": [
                "select": ["name": sessionType]
            ],
            "Speakers": [
                "multi_select": speakers.map { ["name": $0] }
            ],
            "Tags": [
                "multi_select": tags.map { ["name": $0] }
            ],
        ]
    }

    // MARK: - Private helpers

    private func appendBlocks(pageID: String, blocks: [[String: Any]], apiKey: String) async throws {
        let chunks = stride(from: 0, to: blocks.count, by: 100).map {
            Array(blocks[$0..<min($0 + 100, blocks.count)])
        }
        let url = URL(string: "\(baseURL)/blocks/\(pageID)/children")!
        for chunk in chunks {
            let body: [String: Any] = ["children": chunk]
            var request = makeRequest(url: url, method: "PATCH", apiKey: apiKey)
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await performRequest(request)
            try checkHTTPStatus(response, data: data)
        }
    }

    private nonisolated func makeRequest(url: URL, method: String, apiKey: String) -> URLRequest {
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue(apiVersion, forHTTPHeaderField: "Notion-Version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw NotionError.invalidResponse
        }
        // Handle rate limiting with one automatic retry
        if http.statusCode == 429 {
            let retryAfter = TimeInterval(http.value(forHTTPHeaderField: "Retry-After") ?? "1") ?? 1.0
            try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
            let (retryData, retryResponse) = try await URLSession.shared.data(for: request)
            guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                throw NotionError.invalidResponse
            }
            if retryHTTP.statusCode == 429 {
                throw NotionError.rateLimited(retryAfter: retryAfter)
            }
            return (retryData, retryHTTP)
        }
        return (data, http)
    }

    private func checkHTTPStatus(_ response: HTTPURLResponse, data: Data) throws {
        guard response.statusCode >= 200 && response.statusCode < 300 else {
            let fullBody = String(data: data, encoding: .utf8) ?? "(no body)"
            logger.error("Notion API \(response.statusCode): \(fullBody)")
            let message = extractErrorMessage(from: data) ?? "Unknown error"
            throw NotionError.httpError(statusCode: response.statusCode, message: message)
        }
    }

    private nonisolated func extractErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? String else { return nil }
        return message
    }

    private nonisolated func extractDatabaseTitle(from json: [String: Any]) -> String {
        // Notion returns title as an array of rich_text objects
        if let titleArray = json["title"] as? [[String: Any]],
           let first = titleArray.first,
           let text = first["text"] as? [String: Any],
           let content = text["content"] as? String, !content.isEmpty {
            return content
        }
        // Some databases return title under "properties" > "title" > "title" array
        if let props = json["properties"] as? [String: Any],
           let titleProp = props["title"] as? [String: Any],
           let titleArr = titleProp["title"] as? [[String: Any]],
           let first = titleArr.first,
           let text = first["text"] as? [String: Any],
           let content = text["content"] as? String {
            return content
        }
        return "Untitled"
    }

    private nonisolated func cleanDatabaseID(_ id: String) -> String {
        // Accept full Notion URLs or bare IDs with/without hyphens
        // Extract 32-hex-char ID from URL if present
        if id.contains("notion.so") {
            let parts = id.components(separatedBy: "/")
            let lastPart = parts.last ?? ""
            // Remove query string
            let withoutQuery = lastPart.components(separatedBy: "?").first ?? lastPart
            // Remove hyphens
            return withoutQuery.replacingOccurrences(of: "-", with: "")
        }
        return id.replacingOccurrences(of: "-", with: "")
    }

    private nonisolated func formatDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let minutes = total / 60
        let secs = total % 60
        if minutes == 0 {
            return "\(secs)s"
        }
        return secs == 0 ? "\(minutes)m" : "\(minutes)m \(secs)s"
    }
}
