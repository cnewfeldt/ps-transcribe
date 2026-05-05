// TranscriptRenameTests
// Phase 24 (NYQUIST-03) -- Phase 3 NAME-02 + NAME-03 + NAME-05: file-on-disk rename behavior.
//
// NAME-02: TranscriptLogger.setName(_:) during a session updates the on-disk filename.
// NAME-03: TranscriptLogger.renameFinalized(at:to:) after finalization moves the file
//          to a new path and preserves content.
// NAME-05: file path renames are preserved on disk -- same surface as NAME-02 + NAME-03.
//
// Tests run through public actor methods; the private helpers
// (validatedVaultPath, sanitizedFilenameComponent, atomicRewrite) are file-private
// in TranscriptLogger and not directly callable per RESEARCH.md Risk #4
// (`@testable import` does NOT cross `private`). Going through the public surface
// is the supported pattern (DictationLogger tests use the same approach).
//
// File is intentionally separate from any TranscriptLoggerSecurityTests.swift
// added by Plan 24-05 per RESEARCH.md Open Question #4 (avoid cross-plan
// file-growth coordination).

import Testing
import Foundation
@testable import PSTranscribe

@Suite("TranscriptRenameTests", .serialized)
struct TranscriptRenameTests {

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TranscriptRenameTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// NAME-02: setName(_:) during an active session must rename the on-disk file
    /// to a path containing the sanitized form of the user-provided name.
    @Test func setNameDuringSessionUpdatesOnDiskFilename() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = TranscriptLogger()
        try await logger.startSession(sourceApp: "Teams", vaultPath: dir.path)
        await logger.append(speaker: "You", text: "ping", timestamp: Date())
        try await logger.setName("Custom Name 1")

        // List dir contents (recursive -- TranscriptLogger writes the .md directly into vaultPath).
        let contents = try FileManager.default.subpathsOfDirectory(atPath: dir.path)

        // Sanitization (TranscriptLogger.sanitizedFilenameComponent) preserves alphanumerics,
        // space, hyphen, underscore, period -- so the literal "Custom Name 1" should appear.
        // Tolerate underscore/hyphen variants in case sanitization shifts under future change.
        let matches = contents.filter {
            $0.contains("Custom Name 1")
                || $0.contains("Custom_Name_1")
                || $0.contains("Custom-Name-1")
        }
        #expect(!matches.isEmpty,
                "After setName('Custom Name 1'), at least one file/path under \(dir.path) must contain the sanitized name. Found: \(contents)")
    }

    /// NAME-03 / NAME-05: renameFinalized(at:to:) on a finalized transcript must move
    /// the file to a new path and preserve the previously-appended content.
    @Test func renameFinalizedAfterSessionMovesFileAndPreservesContent() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = TranscriptLogger()
        try await logger.startSession(sourceApp: "Teams", vaultPath: dir.path)
        await logger.append(speaker: "You", text: "preserved text", timestamp: Date())
        await logger.endSession()
        let finalizedURL = await logger.finalizeFrontmatter()

        let oldURL = try #require(finalizedURL,
                                  "finalizeFrontmatter returned nil -- cannot proceed with renameFinalized test")
        #expect(FileManager.default.fileExists(atPath: oldURL.path),
                "Pre-rename: finalized file must exist at \(oldURL.path)")

        let newURL = try await logger.renameFinalized(at: oldURL, to: "Final Renamed Name")

        // Old path must no longer exist.
        #expect(!FileManager.default.fileExists(atPath: oldURL.path),
                "Post-rename: old finalized URL must not exist at \(oldURL.path)")

        // New file must exist at the returned URL and contain the earlier utterance text.
        #expect(FileManager.default.fileExists(atPath: newURL.path),
                "Post-rename: new file must exist at \(newURL.path)")

        // Filename should contain the sanitized form of "Final Renamed Name".
        let newFilename = newURL.lastPathComponent
        #expect(newFilename.contains("Final Renamed Name")
                    || newFilename.contains("Final_Renamed_Name")
                    || newFilename.contains("Final-Renamed-Name"),
                "Renamed filename must contain sanitized form of 'Final Renamed Name'. Got: \(newFilename)")

        let newContents = try String(contentsOf: newURL, encoding: .utf8)
        #expect(newContents.contains("preserved text"),
                "Renamed file must preserve session content (utterance 'preserved text')")
    }
}
