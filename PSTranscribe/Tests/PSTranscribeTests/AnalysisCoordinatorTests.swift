import Testing
import Foundation
@testable import PSTranscribe

@Suite("AnalysisCoordinator Tests")
struct AnalysisCoordinatorTests {

    // MARK: - Threshold

    @Test func onNewUtteranceReturnsNilBelowThreshold() async {
        let coordinator = AnalysisCoordinator()
        // 7 calls -- below threshold of 8 -- all should return nil
        for _ in 0..<7 {
            let result = await coordinator.onNewUtterance(transcript: "hello", model: "test")
            #expect(result == nil)
        }
        let count = await coordinator.utterancesSinceLastUpdate
        #expect(count == 7)
    }

    // MARK: - Reset

    @Test func resetClearsAllState() async {
        let coordinator = AnalysisCoordinator()
        for _ in 0..<5 {
            _ = await coordinator.onNewUtterance(transcript: "hi", model: "test")
        }
        await coordinator.reset()
        let count = await coordinator.utterancesSinceLastUpdate
        let inflight = await coordinator.isGenerating
        let last = await coordinator.lastUpdateTime
        #expect(count == 0)
        #expect(inflight == false)
        #expect(last == .distantPast)
    }

    // MARK: - Parsing

    @Test func parseAnalysisResponseExtractsSummary() async {
        let coordinator = AnalysisCoordinator()
        let response = """
        SUMMARY:
        Alice and Bob discussed the roadmap. They agreed on the Q2 priorities.

        ACTION_ITEMS:
        - Write the spec
        - Share with team

        KEY_TOPICS:
        - Roadmap
        - Q2 planning
        """
        let result = await coordinator.parseAnalysisResponse(response)
        #expect(result.summary.contains("Alice and Bob"))
        #expect(result.summary.contains("Q2 priorities"))
    }

    @Test func parseAnalysisResponseExtractsActionItems() async {
        let coordinator = AnalysisCoordinator()
        let response = """
        SUMMARY:
        A short summary.

        ACTION_ITEMS:
        - First action
        - Second action
        - Third action

        KEY_TOPICS:
        - Topic A
        """
        let result = await coordinator.parseAnalysisResponse(response)
        #expect(result.actionItems.count == 3)
        #expect(result.actionItems[0] == "First action")
        #expect(result.actionItems[1] == "Second action")
        #expect(result.actionItems[2] == "Third action")
    }

    @Test func parseAnalysisResponseExtractsKeyTopics() async {
        let coordinator = AnalysisCoordinator()
        let response = """
        SUMMARY:
        A summary.

        ACTION_ITEMS:
        - Do a thing

        KEY_TOPICS:
        - Topic one
        - Topic two
        """
        let result = await coordinator.parseAnalysisResponse(response)
        #expect(result.keyTopics.count == 2)
        #expect(result.keyTopics[0] == "Topic one")
        #expect(result.keyTopics[1] == "Topic two")
    }

    @Test func parseAnalysisResponseHandlesNoneSections() async {
        let coordinator = AnalysisCoordinator()
        let response = """
        SUMMARY:
        Only a summary here.

        ACTION_ITEMS:
        None

        KEY_TOPICS:
        None
        """
        let result = await coordinator.parseAnalysisResponse(response)
        #expect(result.summary.contains("Only a summary"))
        #expect(result.actionItems.isEmpty)
        #expect(result.keyTopics.isEmpty)
    }

    @Test func parseAnalysisResponseHandlesMissingSections() async {
        let coordinator = AnalysisCoordinator()
        let response = "garbage response with no markers"
        let result = await coordinator.parseAnalysisResponse(response)
        #expect(result.summary == "")
        #expect(result.actionItems.isEmpty)
        #expect(result.keyTopics.isEmpty)
    }

    // MARK: - Prompt

    @Test func buildPromptIncludesAllMarkers() async {
        let coordinator = AnalysisCoordinator()
        let prompt = await coordinator.buildPrompt("transcript text")
        #expect(prompt.contains("SUMMARY:"))
        #expect(prompt.contains("ACTION_ITEMS:"))
        #expect(prompt.contains("KEY_TOPICS:"))
        #expect(prompt.contains("transcript text"))
    }

    // MARK: - AnalysisState

    @Test @MainActor func analysisStateAppliesResult() {
        let state = AnalysisState()
        #expect(state.hasData == false)
        let result = AnalysisResult(
            summary: "A summary",
            actionItems: ["item1"],
            keyTopics: ["topic1"]
        )
        state.apply(result)
        #expect(state.summary == "A summary")
        #expect(state.actionItems == ["item1"])
        #expect(state.keyTopics == ["topic1"])
        #expect(state.hasData == true)
    }

    @Test @MainActor func analysisStateClearResetsAll() {
        let state = AnalysisState()
        state.apply(AnalysisResult(summary: "s", actionItems: ["a"], keyTopics: ["k"]))
        state.isUpdating = true
        state.clear()
        #expect(state.summary == "")
        #expect(state.actionItems.isEmpty)
        #expect(state.keyTopics.isEmpty)
        #expect(state.isUpdating == false)
        #expect(state.hasData == false)
    }
}
