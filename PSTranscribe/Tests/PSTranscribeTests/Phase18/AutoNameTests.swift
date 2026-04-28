import Testing
import Foundation
@testable import PSTranscribe

@Suite("AutoNameTests")
struct AutoNameTests {

    @MainActor
    private func makeCoordinator() -> DictationCoordinator {
        let settings = AppSettings()
        let coordinator = SessionCoordinator()
        let library = LibraryStore()
        return DictationCoordinator(settings: settings, sessionCoordinator: coordinator, libraryStore: library)
    }

    @Test @MainActor func first5WordsBecomeName() {
        let dict = makeCoordinator()
        #expect(dict.autoNameFromTranscript("the quick brown fox jumps over the lazy dog") == "the quick brown fox jumps")
    }

    @Test @MainActor func emptyTranscriptFallsBackToTimestamp() {
        let dict = makeCoordinator()
        #expect(dict.autoNameFromTranscript("").hasPrefix("Dictation "))
    }

    @Test @MainActor func whitespaceOnlyFallsBackToTimestamp() {
        let dict = makeCoordinator()
        #expect(dict.autoNameFromTranscript("   \n\t  ").hasPrefix("Dictation "))
    }

    @Test @MainActor func longSingleTokenTruncatedAt50() {
        let dict = makeCoordinator()
        let result = dict.autoNameFromTranscript(String(repeating: "x", count: 80))
        #expect(result.hasSuffix("…"))
        #expect(result.count <= 51)
    }

    @Test @MainActor func leadingTrailingPunctuationStripped() {
        let dict = makeCoordinator()
        #expect(dict.autoNameFromTranscript("...hello world...") == "hello world")
    }

    @Test @MainActor func allPunctuationFallsBackToTimestamp() {
        let dict = makeCoordinator()
        #expect(dict.autoNameFromTranscript("...,,,").hasPrefix("Dictation "))
    }

    @Test @MainActor func exactly50CharsNotTruncated() {
        let dict = makeCoordinator()
        let input = "aaaaaaaaaa bbbbbbbbbb cccccccccc dddddddddd eeeeee"
        #expect(input.count == 50)
        let result = dict.autoNameFromTranscript(input)
        #expect(result == input)
        #expect(!result.hasSuffix("…"))
    }
}
