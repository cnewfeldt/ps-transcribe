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

}
