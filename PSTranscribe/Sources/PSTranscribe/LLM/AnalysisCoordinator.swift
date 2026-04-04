import Foundation
import os

private let log = Logger(subsystem: "com.pstranscribe.app", category: "AnalysisCoordinator")

/// Coordinates live LLM analysis during a recording session.
///
/// Enforces:
/// - Utterance threshold (D-06): wait for at least `utteranceThreshold` utterances before firing.
/// - Cooldown (D-07): at least `cooldownSeconds` between successful triggers.
/// - In-flight guard (D-08): never overlap generate() calls.
///
/// Failures are silent per LLMA-06 -- a failed generate() returns nil and the
/// caller continues recording without surfacing an error to the user.
actor AnalysisCoordinator {

    // MARK: - Dependencies

    private let service: OllamaService

    // MARK: - Tunables

    let utteranceThreshold: Int = 8
    let cooldownSeconds: TimeInterval = 30
    let generateTimeout: TimeInterval = 120

    // MARK: - State (observable via tests)

    private(set) var utterancesSinceLastUpdate: Int = 0
    private(set) var lastUpdateTime: Date = .distantPast
    private(set) var isGenerating: Bool = false

    // MARK: - Init

    init(service: OllamaService = OllamaService()) {
        self.service = service
    }

    // MARK: - Public API

    /// Record a new utterance. Returns an `AnalysisResult` when all conditions
    /// are met (threshold reached, not in-flight, cooldown elapsed) and the
    /// Ollama generate() call succeeds. Returns nil otherwise.
    func onNewUtterance(transcript: String, model: String) async -> AnalysisResult? {
        utterancesSinceLastUpdate += 1

        guard utterancesSinceLastUpdate >= utteranceThreshold else { return nil }
        guard !isGenerating else { return nil }
        guard Date().timeIntervalSince(lastUpdateTime) >= cooldownSeconds else { return nil }

        isGenerating = true
        utterancesSinceLastUpdate = 0
        lastUpdateTime = Date()
        defer { isGenerating = false }

        do {
            let response = try await service.generate(
                prompt: buildPrompt(transcript),
                model: model,
                timeout: generateTimeout
            )
            let result = parseAnalysisResponse(response)
            log.info("Analysis updated: \(result.summary.prefix(60), privacy: .public)...")
            return result
        } catch {
            log.warning("Analysis generation failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Clear all coordinator state. Called when a session ends or restarts.
    func reset() {
        utterancesSinceLastUpdate = 0
        lastUpdateTime = .distantPast
        isGenerating = false
    }

    // MARK: - Prompt Building (non-private for direct testing)

    func buildPrompt(_ transcript: String) -> String {
        """
        Analyze this conversation transcript and respond with EXACTLY this format:

        SUMMARY:
        [2-3 sentence summary of the conversation so far]

        ACTION_ITEMS:
        - [action item 1]
        - [action item 2]

        KEY_TOPICS:
        - [topic 1]
        - [topic 2]

        If there are no action items or key topics, write "None" under that section.

        Transcript:
        \(transcript)
        """
    }

    // MARK: - Response Parsing (non-private for direct testing)

    func parseAnalysisResponse(_ response: String) -> AnalysisResult {
        let summaryText = extractSection(in: response, after: "SUMMARY:", before: "ACTION_ITEMS:")
        let actionBlock = extractSection(in: response, after: "ACTION_ITEMS:", before: "KEY_TOPICS:")
        let topicsBlock = extractSection(in: response, after: "KEY_TOPICS:", before: nil)

        return AnalysisResult(
            summary: summaryText,
            actionItems: parseList(actionBlock),
            keyTopics: parseList(topicsBlock)
        )
    }

    // MARK: - Parsing helpers

    private func extractSection(in source: String, after marker: String, before nextMarker: String?) -> String {
        guard let startRange = source.range(of: marker) else { return "" }
        let fromStart = source[startRange.upperBound...]
        if let next = nextMarker, let endRange = fromStart.range(of: next) {
            return String(fromStart[..<endRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return String(fromStart).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseList(_ block: String) -> [String] {
        block.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.hasPrefix("- ") }
            .map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.lowercased() != "none" }
    }
}
