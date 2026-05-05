// ErrorPathLoggingTests
// Phase 24 (NYQUIST-02 + NYQUIST-04) -- Phase 02 SECR-02/11 + Phase 08 print-removal.
//
// Static source-file assertions: refactor tripwires for invariants whose absence
// (zero matches) is the security/quality property. Reads source files as Strings
// and asserts substring/regex absence or presence.
//
//   - 08-print-removal: zero `print(` calls in error paths (SystemAudioCapture,
//     MicCapture, SessionStore, TranscriptionEngine). All error logging goes
//     through os.Logger (committed to in Phase 8).
//   - SECR-02: zero `/tmp/tome.log` or `/tmp/PSTranscribe` write paths in
//     TranscriptionEngine.swift. The runtime-absence assertion is provable from
//     static source: if the string isn't there, no code path can write it.
//   - SECR-11: speechSamples buffer in StreamingTranscriber must release backing
//     storage with `keepingCapacity: false` to prevent memory residue (verbatim
//     code at lines 96, 106, 114, 125 of StreamingTranscriber.swift).
//
// Working-directory assumption: `swift test` runs from `PSTranscribe/`. Source
// files are at `Sources/PSTranscribe/<subdir>/<file>.swift`.
//
// Note (deviation from plan): plan listed `Persistence/SessionStore.swift` for
// 08-print-removal coverage; the actual source location is `Storage/SessionStore.swift`.

import Testing
import Foundation

@Suite("ErrorPathLoggingTests")
struct ErrorPathLoggingTests {

    private func readSource(_ relativePath: String) throws -> String {
        let url = URL(fileURLWithPath: "Sources/PSTranscribe/\(relativePath)")
        let content = try String(contentsOf: url, encoding: .utf8)
        try #require(!content.isEmpty,
                     "Read empty content from \(relativePath); is the test cwd PSTranscribe/?")
        return content
    }

    @Test func noPrintInErrorPaths() throws {
        let files = [
            "Audio/SystemAudioCapture.swift",
            "Audio/MicCapture.swift",
            "Storage/SessionStore.swift",
            "Transcription/TranscriptionEngine.swift",
        ]
        for path in files {
            let src = try readSource(path)
            // Filter out comment lines so a header-comment containing `print(` doesn't trip us
            let nonComment = src.split(separator: "\n").filter {
                !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//")
            }
            let body = nonComment.joined(separator: "\n")
            #expect(!body.contains("print("),
                    "\(path) contains a print() call (08-print-removal invariant)")
        }
    }

    @Test func noTmpLogWritesInTranscriptionEngine() throws {
        let src = try readSource("Transcription/TranscriptionEngine.swift")
        #expect(!src.contains("/tmp/tome.log"))
        #expect(!src.contains("/tmp/PSTranscribe"))
        #expect(!src.contains(#"FileHandle(forWritingAtPath: "/tmp"#))
    }

    @Test func speechSamplesUsesNoCapacityRetention() throws {
        let src = try readSource("Transcription/StreamingTranscriber.swift")
        #expect(!src.contains("speechSamples.removeAll(keepingCapacity: true)"),
                "speechSamples must release backing storage (SECR-11)")
        #expect(src.contains("speechSamples.removeAll(keepingCapacity: false)"),
                "speechSamples must use removeAll(keepingCapacity: false) (SECR-11)")
    }
}
