import Testing
import Foundation
@testable import PSTranscribe

@Suite("NotionService Tests")
struct NotionServiceTests {
    // Sample transcript with YAML frontmatter and speaker lines
    let sampleTranscript = """
---
type: meeting
created: "2026-04-04"
duration: 745
sourceApp: Teams
---

**You** (00:01:23)
Hello world

**Speaker 2** (00:01:30)
Hi there

"""

    let transcriptWithDivider = """
---
type: meeting
created: "2026-04-04"
---

**You** (00:01:23)
Before divider

---

**Speaker 2** (00:02:00)
After divider

"""

    // MARK: - transcriptToBlocks

    @Test func transcriptToBlocksConvertsSpeakerLines() async {
        let service = NotionService()
        let blocks = await service.transcriptToBlocks("**You** (00:01:23)\nHello")
        // Should have at least one block for the speaker line and one for the text
        #expect(!blocks.isEmpty)

        // Find a paragraph block with bold rich_text for speaker
        let hasBoldSpeaker = blocks.contains { block in
            guard let type = block["type"] as? String, type == "paragraph",
                  let para = block["paragraph"] as? [String: Any],
                  let richText = para["rich_text"] as? [[String: Any]] else { return false }
            return richText.contains { rt in
                guard let annotations = rt["annotations"] as? [String: Any] else { return false }
                return annotations["bold"] as? Bool == true
            }
        }
        #expect(hasBoldSpeaker)
    }

    @Test func transcriptToBlocksParsesMulipleSpeakers() async {
        let service = NotionService()
        let blocks = await service.transcriptToBlocks(sampleTranscript)
        #expect(!blocks.isEmpty)

        // Both "You" and "Speaker 2" should appear as bold annotations
        let speakerBlocks = blocks.filter { block in
            guard let type = block["type"] as? String, type == "paragraph",
                  let para = block["paragraph"] as? [String: Any],
                  let richText = para["rich_text"] as? [[String: Any]] else { return false }
            return richText.contains { rt in
                guard let annotations = rt["annotations"] as? [String: Any] else { return false }
                return annotations["bold"] as? Bool == true
            }
        }
        // At least 2 speaker header blocks (one per speaker)
        #expect(speakerBlocks.count >= 2)
    }

    @Test func transcriptToBlocksStripsFrontmatter() async {
        let service = NotionService()
        let blocks = await service.transcriptToBlocks(sampleTranscript)
        // Frontmatter keys should not appear in block content
        let allText = blocks.compactMap { block -> String? in
            guard let para = block["paragraph"] as? [String: Any],
                  let richText = para["rich_text"] as? [[String: Any]] else { return nil }
            return richText.compactMap { $0["text"] as? [String: Any] }.compactMap { $0["content"] as? String }.joined()
        }.joined()

        #expect(!allText.contains("type: meeting"))
        #expect(!allText.contains("created:"))
    }

    @Test func transcriptToBlocksHandlesDividers() async {
        let service = NotionService()
        let blocks = await service.transcriptToBlocks(transcriptWithDivider)
        let hasDivider = blocks.contains { block in
            (block["type"] as? String) == "divider"
        }
        #expect(hasDivider)
    }

    @Test func transcriptToBlocksSplitsLongTranscripts() async {
        let service = NotionService()
        // Build a transcript with > 100 lines so we'd get > 100 blocks
        var lines = [String]()
        for i in 0..<60 {
            lines.append("**You** (00:\(String(format: "%02d", i)):00)")
            lines.append("Line number \(i)")
            lines.append("")
        }
        let longTranscript = lines.joined(separator: "\n")
        let blocks = await service.transcriptToBlocks(longTranscript)
        // We should get at least 60 speaker blocks + 60 text blocks from 60 speaker pairs
        #expect(blocks.count >= 60)
    }

    // MARK: - extractSpeakers

    @Test func extractSpeakersFindsAllUniqueSpeakers() async {
        let service = NotionService()
        let speakers = await service.extractSpeakers(sampleTranscript)
        #expect(speakers.contains("You"))
        #expect(speakers.contains("Speaker 2"))
        #expect(speakers.count == 2)
    }

    // MARK: - buildProperties

    @Test func buildPropertiesCreatesCorrectSchema() async {
        let service = NotionService()
        let date = Date(timeIntervalSince1970: 0)
        let props = await service.buildProperties(
            title: "Test Meeting",
            date: date,
            duration: 750,
            sourceApp: "Teams",
            sessionType: "Call Capture",
            speakers: ["You", "Speaker 2"],
            tags: ["engineering"]
        )

        // Title
        let title = props["Title"] as? [String: Any]
        #expect(title != nil)
        let titleArr = title?["title"] as? [[String: Any]]
        #expect(titleArr?.isEmpty == false)

        // Date
        let dateField = props["Date"] as? [String: Any]
        #expect(dateField != nil)
        let dateObj = dateField?["date"] as? [String: Any]
        #expect(dateObj?["start"] as? String != nil)

        // Duration
        let duration = props["Duration"] as? [String: Any]
        #expect(duration != nil)
        let durationRT = duration?["rich_text"] as? [[String: Any]]
        #expect(durationRT?.isEmpty == false)

        // Source App
        let sourceApp = props["Source App"] as? [String: Any]
        #expect(sourceApp != nil)
        let selectVal = sourceApp?["select"] as? [String: Any]
        #expect(selectVal?["name"] as? String == "Teams")

        // Session Type
        let sessionType = props["Session Type"] as? [String: Any]
        #expect(sessionType != nil)

        // Speakers
        let speakers = props["Speakers"] as? [String: Any]
        #expect(speakers != nil)
        let multiSelect = speakers?["multi_select"] as? [[String: Any]]
        #expect(multiSelect?.count == 2)

        // Tags
        let tags = props["Tags"] as? [String: Any]
        #expect(tags != nil)
        let tagsArr = tags?["multi_select"] as? [[String: Any]]
        #expect(tagsArr?.count == 1)
        #expect(tagsArr?.first?["name"] as? String == "engineering")
    }
}
