import Testing
import Foundation
@testable import PSTranscribe

@Suite("TranscriptParser Tests")
struct TranscriptParserTests {
    let sampleTranscript = """
---
type: meeting
created: "2026-04-02"
---

# Call Recording -- 2026-04-02 14:30

**Duration:** 05:00 | **Speakers:** 2

---

## Transcript

**You** (00:01:23)
Hello world

**Speaker 2** (00:01:30)
Hi there

"""

    let frontmatterOnlyTranscript = """
---
type: meeting
created: "2026-04-02"
---

# Call Recording -- 2026-04-02 14:30

**Duration:** 00:00 | **Speakers:** 0

---

## Transcript

"""

    @Test func parsesSampleTranscriptCorrectly() {
        let utterances = parseTranscriptContent(sampleTranscript)
        #expect(utterances.count == 2)
        #expect(utterances[0].text == "Hello world")
        #expect(utterances[0].speaker == .you)
        #expect(utterances[1].text == "Hi there")
        #expect(utterances[1].speaker == .them)
    }

    @Test func returnsEmptyForFrontmatterOnly() {
        let utterances = parseTranscriptContent(frontmatterOnlyTranscript)
        #expect(utterances.isEmpty)
    }

    @Test func parsesFromDisk() throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-transcript-\(UUID().uuidString).md")
        try sampleTranscript.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let utterances = try parseTranscript(at: tempFile)
        #expect(utterances.count == 2)
    }

    @Test func youSpeakerMapsToSpeakerYou() {
        let utterances = parseTranscriptContent(sampleTranscript)
        #expect(utterances.first?.speaker == .you)
    }

    @Test func otherSpeakerMapsToSpeakerThem() {
        let utterances = parseTranscriptContent(sampleTranscript)
        #expect(utterances.last?.speaker == .them)
    }

    // MARK: - parseAnalysis Tests

    let transcriptWithAnalysis = """
---
type: meeting
created: "2026-04-02"
---

# Call Recording -- 2026-04-02 14:30

**Duration:** 05:00 | **Speakers:** 2

---

## Transcript

**You** (00:01:23)
Hello world

**Speaker 2** (00:01:30)
Hi there


## Analysis

### Summary

The team discussed the Q2 roadmap and aligned on priorities.

### Action Items

- [ ] Draft the proposal
- [ ] Schedule follow-up meeting
- [ ] Review budget

### Key Topics

roadmap, budget, hiring
"""

    @Test func parseAnalysisReturnsNilForContentWithoutAnalysisSection() {
        let result = parseAnalysisContent(sampleTranscript)
        #expect(result == nil)
    }

    @Test func parseAnalysisExtractsSummary() {
        let result = parseAnalysisContent(transcriptWithAnalysis)
        #expect(result != nil)
        #expect(result?.summary == "The team discussed the Q2 roadmap and aligned on priorities.")
    }

    @Test func parseAnalysisExtractsActionItemsStrippingCheckboxPrefix() {
        let result = parseAnalysisContent(transcriptWithAnalysis)
        #expect(result?.actionItems.count == 3)
        #expect(result?.actionItems[0] == "Draft the proposal")
        #expect(result?.actionItems[1] == "Schedule follow-up meeting")
        #expect(result?.actionItems[2] == "Review budget")
    }

    @Test func parseAnalysisExtractsKeyTopicsAsArray() {
        let result = parseAnalysisContent(transcriptWithAnalysis)
        #expect(result?.keyTopics == ["roadmap", "budget", "hiring"])
    }

    @Test func parseAnalysisFromDiskReturnsNilForMissingFile() {
        let missingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("does-not-exist-\(UUID().uuidString).md")
        let result = parseAnalysis(at: missingURL)
        #expect(result == nil)
    }

    @Test func parseAnalysisFromDiskExtractsAnalysis() throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-analysis-disk-\(UUID().uuidString).md")
        try transcriptWithAnalysis.write(to: tempFile, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempFile) }

        let result = parseAnalysis(at: tempFile)
        #expect(result != nil)
        #expect(result?.summary.contains("roadmap") == true)
        #expect(result?.actionItems.count == 3)
        #expect(result?.keyTopics.count == 3)
    }
}
