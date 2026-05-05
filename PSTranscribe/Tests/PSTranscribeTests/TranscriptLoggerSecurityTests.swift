// TranscriptLoggerSecurityTests
// Phase 24 (NYQUIST-02) -- Phase 02 SECR-03 (path traversal), SECR-06 (0o600 permissions),
// SECR-09 (atomicRewrite normal-path), SECR-10 (filename sanitization).
//
// Tests run through TranscriptLogger's public actor surface. Per RESEARCH.md Risk #4,
// `validatedVaultPath`, `sanitizedFilenameComponent`, and `atomicRewrite` are file-private
// helpers in TranscriptLogger.swift -- `@testable import` does NOT cross `private`. The
// DictationLoggerTests prove this approach works (rejectsTraversal, rejectsNullByte,
// outputFileHasRestrictivePermissions are all behavioral, not direct-helper, tests).
//
// The atomicRewrite-under-kill (SIGKILL during write) variant of SECR-09 is WITHDRAWN
// per Phase 24 D-03 (force-quit out of scope). This file covers the normal-path
// atomic-write integrity only.

import Testing
import Foundation
@testable import PSTranscribe

@Suite("TranscriptLoggerSecurityTests", .serialized)
struct TranscriptLoggerSecurityTests {

    private func tempDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("TranscriptLoggerSecurityTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func rejectsPathTraversal() async throws {
        let logger = TranscriptLogger()
        await #expect(throws: TranscriptLoggerError.self) {
            try await logger.startSession(sourceApp: "Test", vaultPath: "../../../etc")
        }
    }

    @Test func rejectsNullByteInVaultPath() async throws {
        let logger = TranscriptLogger()
        await #expect(throws: TranscriptLoggerError.self) {
            try await logger.startSession(sourceApp: "Test", vaultPath: "/tmp/foo\0bar")
        }
    }

    @Test func finalizedTranscriptHas0o600Permissions() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = TranscriptLogger()
        try await logger.startSession(sourceApp: "Test", vaultPath: dir.path)
        await logger.append(speaker: "You", text: "perms test", timestamp: Date())
        await logger.endSession()
        let url = await logger.finalizeFrontmatter()

        guard let url else { Issue.record("finalizeFrontmatter returned nil"); return }
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let perms = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0
        #expect(perms == 0o600,
                "Finalized transcript must be 0o600 (owner-only); got \(String(perms, radix: 8))")
    }

    @Test func setNameAtomicRewriteProducesValidFile() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = TranscriptLogger()
        try await logger.startSession(sourceApp: "Test", vaultPath: dir.path)
        await logger.append(speaker: "You", text: "atomic test content", timestamp: Date())
        try await logger.setName("Valid Name")
        await logger.endSession()
        let url = await logger.finalizeFrontmatter()

        guard let url else { Issue.record("finalizeFrontmatter returned nil"); return }
        #expect(FileManager.default.fileExists(atPath: url.path))
        let contents = try String(contentsOf: url, encoding: .utf8)
        #expect(contents.contains("atomic test content"))
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        let perms = (attrs[.posixPermissions] as? NSNumber)?.intValue ?? 0
        #expect(perms == 0o600)
    }

    @Test func sanitizesAdversarialFilenameComponents() async throws {
        let dir = try tempDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let logger = TranscriptLogger()
        try await logger.startSession(sourceApp: "Test", vaultPath: dir.path)
        await logger.append(speaker: "You", text: "x", timestamp: Date())
        // Adversarial: path traversal + angle brackets + script tags. Note: a literal NUL
        // ("\0") in the input would trip the source's own NSString conversion; the helper
        // accepts strings, so the behavioral assertion here is filename-component
        // whitelist, not raw-byte sanitization.
        try await logger.setName("../evil/<script>alert('xss')</script>")

        let allFiles = try FileManager.default.subpathsOfDirectory(atPath: dir.path)
        // The on-disk filename component (last path component) must match a strict whitelist:
        // alphanumeric + space + hyphen + underscore + period, <=50 chars per filename component.
        let filenames = allFiles.map { ($0 as NSString).lastPathComponent }
        // Only inspect .md files -- temp files like ".foo.md.tmp" may briefly exist mid-rewrite
        // but should be cleaned up; we only care about the final transcript filename.
        let mdFiles = filenames.filter { $0.hasSuffix(".md") && !$0.hasPrefix(".") }
        #expect(!mdFiles.isEmpty, "Expected at least one .md file after setName")
        for name in mdFiles {
            #expect(!name.contains("/"), "Filename component must not contain '/': \(name)")
            #expect(!name.contains("<"), "Filename component must not contain '<': \(name)")
            #expect(!name.contains(">"), "Filename component must not contain '>': \(name)")
            // SECR-10 whitelist contract from sanitizedFilenameComponent (TranscriptLogger.swift:53-58):
            // alphanumerics + space + "." + "-" + "_". An internal ".." substring within a
            // SINGLE filename component is benign because no path separator accompanies it
            // -- the sanitizer correctly strips '/' so traversal is impossible. The test
            // therefore enforces the whitelist (the production invariant) rather than an
            // overly strict no-".." rule that the sanitizer never promised.
            #expect(name.range(of: #"^[A-Za-z0-9 ._-]+$"#, options: .regularExpression) != nil,
                    "Filename component must match whitelist [A-Za-z0-9 ._-]+: \(name)")
        }
    }
}
