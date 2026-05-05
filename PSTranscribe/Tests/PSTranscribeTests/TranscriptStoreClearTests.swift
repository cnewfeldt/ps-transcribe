// TranscriptStoreClearTests
// Phase 24 (NYQUIST-04) -- Phase 8 STAB-03: stopSession clears transcriptStore state.
//
// Asserts that calling .clear() on a populated TranscriptStore empties its accumulated
// state. ContentView.swift:526 (start) and :665 (stop) call this; the unit test isolates
// the data-store behavior from the view lifecycle.

import Testing
import Foundation
@testable import PSTranscribe

@Suite("TranscriptStoreClearTests", .serialized)
struct TranscriptStoreClearTests {

    @Test @MainActor func clearEmptiesAccumulatedState() {
        let store = TranscriptStore()

        // Populate with multiple utterances and volatile partials so .clear() has
        // every accumulated field to reset (utterances + volatileYouText + volatileThemText
        // + lastUtteranceTimestamp).
        store.append(Utterance(text: "first", speaker: .you, timestamp: Date(timeIntervalSince1970: 1_700_000_000)))
        store.append(Utterance(text: "second", speaker: .them, timestamp: Date(timeIntervalSince1970: 1_700_000_005)))
        store.append(Utterance(text: "third", speaker: .named("Speaker 2"), timestamp: Date(timeIntervalSince1970: 1_700_000_010)))
        store.volatileYouText = "partial-you"
        store.volatileThemText = "partial-them"

        // Pre-condition: state IS populated.
        #expect(!store.utterances.isEmpty)
        #expect(store.utterances.count == 3)
        #expect(store.volatileYouText == "partial-you")
        #expect(store.volatileThemText == "partial-them")
        #expect(store.lastUtteranceTimestamp != nil)

        // Action under test.
        store.clear()

        // Post-condition: every accumulated field is reset.
        #expect(store.utterances.isEmpty)
        #expect(store.volatileYouText == "")
        #expect(store.volatileThemText == "")
        #expect(store.lastUtteranceTimestamp == nil)
    }
}
