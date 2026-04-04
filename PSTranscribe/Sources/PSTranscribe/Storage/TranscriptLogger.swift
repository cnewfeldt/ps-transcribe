import Foundation
import os

private let log = Logger(subsystem: "com.pstranscribe.app", category: "TranscriptLogger")

enum TranscriptLoggerError: LocalizedError {
    case cannotCreateFile(String)
    var errorDescription: String? {
        switch self { case .cannotCreateFile(let p): return "Cannot create transcript at \(p)" }
    }
}

/// Writes structured markdown transcripts to the vault.
actor TranscriptLogger {
    private var fileHandle: FileHandle?
    private var currentFilePath: URL?
    private var sessionStartTime: Date?
    private var speakersDetected: Set<String> = []
    private var sourceApp: String = "manual"
    private var sessionContext: String = ""
    private var utteranceBuffer: [(speaker: String, text: String, timestamp: Date)] = []
    private var speakerCounter: Int = 1  // starts at 1, "You" is implicit

    // Map from raw speaker identity to display label
    private var speakerLabels: [String: String] = [:]

    // Retained from last session for post-session diarization and frontmatter finalization
    private var lastSessionFilePath: URL?
    private var lastSessionStartTime: Date?
    private var lastSpeakersDetected: Set<String> = []
    private var lastSessionContext: String = ""

    // Checkpoint integration for STAB-03
    private var sessionStore: SessionStore?
    private var currentSessionId: String?

    // MARK: - Security Helpers

    /// Validates a vault path against traversal patterns before any file operations.
    private func validatedVaultPath(_ rawPath: String) throws -> URL {
        let expanded = NSString(string: rawPath).expandingTildeInPath
        // Reject traversal patterns and null bytes before resolution
        guard !expanded.contains("\0"),
              !expanded.contains("..") else {
            log.error("Invalid vault path rejected: contains traversal pattern")
            throw TranscriptLoggerError.cannotCreateFile("Invalid vault path: contains prohibited characters")
        }
        let resolved = URL(fileURLWithPath: expanded).resolvingSymlinksInPath()
        return resolved.standardized
    }

    /// Sanitizes a string for use as a filename component using a whitelist approach.
    private func sanitizedFilenameComponent(_ input: String) -> String {
        let allowed = CharacterSet.alphanumerics
            .union(CharacterSet(charactersIn: " -_."))
        let filtered = String(input.unicodeScalars.filter { allowed.contains($0) })
        return String(filtered.trimmingCharacters(in: .whitespaces).prefix(50))
    }

    /// Atomically rewrites a file: writes to temp, removes original, moves temp to destination.
    /// If any step fails, the original is left intact (or the temp is cleaned up) and the error is thrown.
    private func atomicRewrite(at filePath: URL, newPath: URL? = nil, content: String) throws {
        let dir = filePath.deletingLastPathComponent()
        let tmpPath = dir.appendingPathComponent(".\(filePath.lastPathComponent).tmp")

        // Write to temp -- if this fails, original is untouched
        do {
            try content.write(to: tmpPath, atomically: false, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: NSNumber(value: 0o600)],
                ofItemAtPath: tmpPath.path
            )
        } catch {
            log.error("atomicRewrite: failed to write temp file: \(error.localizedDescription, privacy: .public)")
            try? FileManager.default.removeItem(at: tmpPath)
            throw error
        }

        let destination = newPath ?? filePath
        // Remove original -- if this fails, temp is orphaned but original intact
        do {
            if FileManager.default.fileExists(atPath: filePath.path) {
                try FileManager.default.removeItem(at: filePath)
            }
        } catch {
            log.error("atomicRewrite: failed to remove original: \(error.localizedDescription, privacy: .public)")
            try? FileManager.default.removeItem(at: tmpPath)
            throw error
        }

        // Move temp to final -- if this fails, data is in tmpPath (logged prominently)
        do {
            try FileManager.default.moveItem(at: tmpPath, to: destination)
        } catch {
            log.error("atomicRewrite: CRITICAL -- move failed, data at \(tmpPath.path, privacy: .private): \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    // MARK: - Session Lifecycle

    func startSession(sourceApp: String, vaultPath: String, sessionType: SessionType = .callCapture, sessionStore: SessionStore? = nil, sessionId: String? = nil) throws {
        self.sessionStore = sessionStore
        self.currentSessionId = sessionId
        self.sourceApp = sourceApp
        self.sessionStartTime = Date()
        self.speakersDetected = []
        self.speakerLabels = [:]
        self.speakerCounter = 1
        self.sessionContext = ""
        self.utteranceBuffer = []

        let directory = try validatedVaultPath(vaultPath)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let now = sessionStartTime!
        let fileFmt = DateFormatter()
        fileFmt.dateFormat = "yyyy-MM-dd HH-mm-ss"

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        let dateStr = dateFmt.string(from: now)
        let timeStr = timeFmt.string(from: now)

        let isVoiceMemo = sessionType == .voiceMemo
        let fileLabel = isVoiceMemo ? "Voice Memo" : "Call Recording"
        let noteType = isVoiceMemo ? "fleeting" : "meeting"
        let logTag = isVoiceMemo ? "log/voice" : "log/meeting"
        let sourceTag = isVoiceMemo ? "source/voice" : "source/meeting"

        let filename = "\(fileFmt.string(from: now)) \(fileLabel).md"
        currentFilePath = directory.appendingPathComponent(filename)

        let content = """
---
type: \(noteType)
created: "\(dateStr)"
time: "\(timeStr)"
duration: "00:00"
source_app: "\(sourceApp)"
source_file: "\(filename)"
attendees: []
context: ""
tags:
  - \(logTag)
  - status/inbox
  - \(sourceTag)
  - source/tome
---

# \(fileLabel) — \(dateStr) \(timeStr)

**Duration:** 00:00 | **Speakers:** 0

---

## Context



---

## Transcript

"""

        guard FileManager.default.createFile(atPath: currentFilePath!.path, contents: content.data(using: .utf8)) else {
            throw TranscriptLoggerError.cannotCreateFile(currentFilePath!.path)
        }
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o600)],
            ofItemAtPath: currentFilePath!.path
        )
        fileHandle = try FileHandle(forWritingTo: currentFilePath!)
        fileHandle?.seekToEndOfFile()
    }

    func append(speaker: String, text: String, timestamp: Date) {
        let label = labelForSpeaker(speaker)
        speakersDetected.insert(label)
        utteranceBuffer.append((speaker: label, text: text, timestamp: timestamp))
        flushBuffer()  // Flush every utterance for crash safety
    }

    /// Periodic flush — call from a timer or at intervals
    func flushIfNeeded() {
        if !utteranceBuffer.isEmpty {
            flushBuffer()
        }
    }

    private func flushBuffer() {
        guard let fileHandle, !utteranceBuffer.isEmpty else { return }

        var lines = ""
        for entry in utteranceBuffer {
            // Use session-relative offset (HH:mm:ss as duration) instead of clock time
            // This avoids midnight-crossing bugs (STAB-02)
            let offsetSeconds = entry.timestamp.timeIntervalSince(sessionStartTime ?? entry.timestamp)
            let totalSeconds = max(0, Int(offsetSeconds))
            let hh = totalSeconds / 3600
            let mm = (totalSeconds % 3600) / 60
            let ss = totalSeconds % 60
            let relativeTimestamp = String(format: "%02d:%02d:%02d", hh, mm, ss)
            lines += "**\(entry.speaker)** (\(relativeTimestamp))\n"
            lines += "\(entry.text)\n\n"
        }

        if let data = lines.data(using: .utf8) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        }

        utteranceBuffer.removeAll()
    }

    func updateContext(_ text: String) throws {
        sessionContext = text
        guard let filePath = currentFilePath else { return }

        // Flush any buffered utterances first
        flushBuffer()
        try? fileHandle?.close()  // SAFE: cleanup before rewrite, handle nilled anyway
        fileHandle = nil

        var content: String
        do {
            content = try String(contentsOf: filePath, encoding: .utf8)
        } catch {
            log.error("updateContext: failed to read file: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        // Update frontmatter context field
        if let range = content.range(of: #"context: ".*""#, options: .regularExpression) {
            let escaped = text.replacingOccurrences(of: "\"", with: "\\\"")
            content.replaceSubrange(range, with: "context: \"\(escaped)\"")
        }

        // Update ## Context body section
        if let contextStart = content.range(of: "## Context\n"),
           let contextEnd = content.range(of: "\n---\n\n## Transcript", range: contextStart.upperBound..<content.endIndex) {
            let replaceRange = contextStart.upperBound..<contextEnd.lowerBound
            content.replaceSubrange(replaceRange, with: "\n\(text)\n")
        }

        try atomicRewrite(at: filePath, content: content)

        // Reopen file handle
        do {
            fileHandle = try FileHandle(forWritingTo: filePath)
            fileHandle?.seekToEndOfFile()
        } catch {
            log.error("updateContext: failed to reopen file handle: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func endSession() async {
        // Flush remaining buffer
        flushBuffer()

        // Close file handle immediately so next session can start
        try? fileHandle?.close()  // SAFE: cleanup, state is being reset regardless
        fileHandle = nil

        // Retain for post-session diarization and frontmatter finalization
        lastSessionFilePath = currentFilePath
        lastSessionStartTime = sessionStartTime
        lastSpeakersDetected = speakersDetected
        lastSessionContext = sessionContext

        // Update checkpoint: transcript buffer flushed and file handle closed (STAB-03)
        if let id = currentSessionId {
            await sessionStore?.updateCheckpoint(sessionId: id, step: "transcript_written")
        }

        // Reset state immediately so next session can start
        currentFilePath = nil
        sessionStartTime = nil
        speakersDetected = []
        sessionContext = ""
        speakerLabels = [:]
        speakerCounter = 1

        // Frontmatter rewrite is NOT called here — caller must call
        // finalizeFrontmatter() AFTER diarization completes to avoid race.
    }

    /// Call AFTER diarization is complete. Rewrites frontmatter with correct
    /// duration, speaker count, attendees, and optionally renames the file.
    @discardableResult
    func finalizeFrontmatter() async -> URL? {
        guard let filePath = lastSessionFilePath,
              let startTime = lastSessionStartTime else { return nil }

        await rewriteFrontmatter(
            filePath: filePath,
            startTime: startTime,
            speakers: lastSpeakersDetected,
            context: lastSessionContext
        )

        // Update lastSessionFilePath if the file was renamed
        if !lastSessionContext.isEmpty {
            let truncated = sanitizedFilenameComponent(lastSessionContext)
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "yyyy-MM-dd HH-mm-ss"
            let datePrefix = dateFmt.string(from: startTime)
            let newFilename = "\(datePrefix) \(truncated).md"
            let newPath = filePath.deletingLastPathComponent().appendingPathComponent(newFilename)
            lastSessionFilePath = newPath
        }

        // Update checkpoint: frontmatter rewrite complete (STAB-03)
        if let id = currentSessionId {
            await sessionStore?.updateCheckpoint(sessionId: id, step: "frontmatter_done")
            // Finalization sequence complete -- remove checkpoint file
            await sessionStore?.finalizeCheckpoint(sessionId: id)
        }

        let savedPath = lastSessionFilePath
        lastSessionStartTime = nil
        lastSpeakersDetected = []
        lastSessionContext = ""
        currentSessionId = nil
        sessionStore = nil
        return savedPath
    }

    private func rewriteFrontmatter(
        filePath: URL,
        startTime: Date,
        speakers: Set<String>,
        context: String
    ) async {
        var content: String
        do {
            content = try String(contentsOf: filePath, encoding: .utf8)
        } catch {
            log.error("rewriteFrontmatter: failed to read file: \(error.localizedDescription, privacy: .public)")
            return
        }

        // Calculate duration
        let elapsed = Date().timeIntervalSince(startTime)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        let durationStr = String(format: "%02d:%02d", minutes, seconds)

        // Build attendees array
        let sortedSpeakers = speakers.sorted()
        let attendeesYaml = sortedSpeakers.isEmpty ? "[]" : "[\"\(sortedSpeakers.joined(separator: "\", \""))\"]"

        // Update frontmatter fields (regex to handle already-rewritten values)
        if let range = content.range(of: #"duration: "\d{2}:\d{2}""#, options: .regularExpression) {
            content.replaceSubrange(range, with: "duration: \"\(durationStr)\"")
        }
        if let range = content.range(of: #"attendees: \[.*\]"#, options: .regularExpression) {
            content.replaceSubrange(range, with: "attendees: \(attendeesYaml)")
        }

        // Update header line (regex to handle already-rewritten values)
        if let range = content.range(of: #"\*\*Duration:\*\* \d{2}:\d{2} \| \*\*Speakers:\*\* \d+"#, options: .regularExpression) {
            content.replaceSubrange(range, with: "**Duration:** \(durationStr) | **Speakers:** \(speakers.count)")
        }

        // Context-based file rename
        var finalPath = filePath
        if !context.isEmpty {
            let truncated = sanitizedFilenameComponent(context)
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "yyyy-MM-dd HH-mm-ss"
            let datePrefix = dateFmt.string(from: startTime)
            let newFilename = "\(datePrefix) \(truncated).md"
            let newPath = filePath.deletingLastPathComponent().appendingPathComponent(newFilename)

            // Update source_file in content
            if let range = content.range(of: #"source_file: ".*""#, options: .regularExpression) {
                content.replaceSubrange(range, with: "source_file: \"\(newFilename)\"")
            }

            finalPath = newPath
        }

        // Atomic write -- uses atomicRewrite helper for rename or same-name paths
        do {
            try atomicRewrite(at: filePath, newPath: finalPath != filePath ? finalPath : nil, content: content)
        } catch {
            log.error("rewriteFrontmatter: atomic write failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Rewrite the transcript file, replacing "Them" labels with diarized speaker IDs.
    /// Segments are (speakerId, startTimeSeconds, endTimeSeconds) from the offline diarizer.
    func rewriteWithDiarization(segments: [(speakerId: String, startTime: Float, endTime: Float)]) async throws {
        guard let filePath = currentFilePath ?? lastSessionFilePath else { return }

        var content: String
        do {
            content = try String(contentsOf: filePath, encoding: .utf8)
        } catch {
            log.error("rewriteWithDiarization: failed to read file: \(error.localizedDescription, privacy: .public)")
            throw error
        }

        // Build a map of unique diarization speaker IDs → friendly labels (Speaker 2, 3, etc.)
        var diarSpeakerMap: [String: String] = [:]
        var nextSpeakerNum = 2
        for seg in segments {
            if diarSpeakerMap[seg.speakerId] == nil {
                diarSpeakerMap[seg.speakerId] = "Speaker \(nextSpeakerNum)"
                nextSpeakerNum += 1
            }
        }

        // For each "**Them** (HH:mm:ss)" line, find the best matching diarization segment
        let pattern = #"\*\*Them\*\* \((\d{2}:\d{2}:\d{2})\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }  // SAFE: hardcoded pattern, failure is a bug

        let nsContent = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsContent.length))

        // Process in reverse so range offsets stay valid
        for match in matches.reversed() {
            let timeRange = match.range(at: 1)
            let timeStr = nsContent.substring(with: timeRange)

            // Parse HH:mm:ss as a session-relative duration (not clock time -- STAB-02)
            // No subtraction needed: the values ARE already offsets from session start
            let parts = timeStr.split(separator: ":").compactMap { Int($0) }
            guard parts.count == 3 else { continue }
            let offsetSeconds = Float(parts[0] * 3600 + parts[1] * 60 + parts[2])

            // Find best matching segment
            var bestMatch: String?
            for seg in segments {
                if offsetSeconds >= seg.startTime && offsetSeconds <= seg.endTime {
                    bestMatch = diarSpeakerMap[seg.speakerId]
                    break
                }
            }

            // Also try closest segment if no exact overlap
            if bestMatch == nil {
                var minDist: Float = .infinity
                for seg in segments {
                    let midpoint = (seg.startTime + seg.endTime) / 2
                    let dist = abs(offsetSeconds - midpoint)
                    if dist < minDist && dist < 10 { // within 10 seconds
                        minDist = dist
                        bestMatch = diarSpeakerMap[seg.speakerId]
                    }
                }
            }

            if let label = bestMatch {
                let fullRange = match.range(at: 0)
                let replacement = "**\(label)** (\(timeStr))"
                content = (content as NSString).replacingCharacters(in: fullRange, with: replacement)
            }
        }

        // Update speaker count in header and frontmatter
        let allSpeakers = Set(diarSpeakerMap.values).union(["You"])
        if let range = content.range(of: #"\*\*Speakers:\*\* \d+"#, options: .regularExpression) {
            content.replaceSubrange(range, with: "**Speakers:** \(allSpeakers.count)")
        }

        try atomicRewrite(at: filePath, content: content)

        // Update checkpoint: diarization rewrite complete (STAB-03)
        if let id = currentSessionId {
            await sessionStore?.updateCheckpoint(sessionId: id, step: "diarization_done")
        }
    }

    // MARK: - Analysis

    /// Appends the final analysis section to a transcript file. Called after finalizeFrontmatter().
    /// Per D-14: written once at session end. Per LLMA-07: saved alongside transcript.
    /// Per D-12/D-13: format is ## Analysis > ### Summary, ### Action Items (checkboxes), ### Key Topics (comma-separated).
    func appendAnalysis(to filePath: URL, summary: String, actionItems: [String], keyTopics: [String]) {
        // Guard: omit section entirely if no analysis was generated (UI-SPEC persistence contract)
        guard !summary.isEmpty || !actionItems.isEmpty || !keyTopics.isEmpty else {
            log.info("appendAnalysis: no analysis data, skipping")
            return
        }

        // Build markdown per D-12/D-13
        var content = "\n\n## Analysis\n\n### Summary\n\n\(summary)\n\n### Action Items\n\n"
        for item in actionItems {
            content += "- [ ] \(item)\n"
        }
        content += "\n### Key Topics\n\n"
        content += keyTopics.joined(separator: ", ")
        content += "\n"

        // Append to file
        guard let handle = try? FileHandle(forWritingTo: filePath) else {
            log.error("appendAnalysis: cannot open file at \(filePath.path, privacy: .public)")
            return
        }
        handle.seekToEndOfFile()
        if let data = content.data(using: .utf8) {
            handle.write(data)
        }
        try? handle.close()
        log.info("appendAnalysis: wrote analysis section to \(filePath.lastPathComponent, privacy: .public)")
    }

    // MARK: - Naming

    /// The file URL for the active session, or the last session's path post-finalization.
    var currentFilePathURL: URL? {
        currentFilePath ?? lastSessionFilePath
    }

    /// Sets a user-provided name for the current session. Renames the file on disk.
    /// Call with debounce (500ms) from the UI to avoid rapid rename races.
    func setName(_ name: String) throws {
        guard let filePath = currentFilePath, let startTime = sessionStartTime else { return }

        // Flush buffer before rename
        flushBuffer()
        try? fileHandle?.close()  // SAFE: cleanup before rename
        fileHandle = nil

        let sanitized = sanitizedFilenameComponent(name)
        guard !sanitized.isEmpty else {
            // Reopen handle at existing path
            fileHandle = try FileHandle(forWritingTo: filePath)
            fileHandle?.seekToEndOfFile()
            return
        }

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd HH-mm-ss"
        let datePrefix = dateFmt.string(from: startTime)
        let newFilename = "\(datePrefix) \(sanitized).md"
        let newPath = filePath.deletingLastPathComponent().appendingPathComponent(newFilename)

        // Read current content
        var content: String
        do {
            content = try String(contentsOf: filePath, encoding: .utf8)
        } catch {
            log.error("setName: failed to read file: \(error.localizedDescription, privacy: .public)")
            // Reopen at old path
            fileHandle = try FileHandle(forWritingTo: filePath)
            fileHandle?.seekToEndOfFile()
            throw error
        }

        // Update source_file in frontmatter
        if let range = content.range(of: #"source_file: ".*""#, options: .regularExpression) {
            content.replaceSubrange(range, with: "source_file: \"\(newFilename)\"")
        }

        // Atomic rename
        try atomicRewrite(at: filePath, newPath: newPath, content: content)
        currentFilePath = newPath

        // Reopen file handle at new path
        do {
            fileHandle = try FileHandle(forWritingTo: newPath)
            fileHandle?.seekToEndOfFile()
        } catch {
            log.error("setName: failed to reopen after rename: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    /// Renames a finalized transcript file on disk. For post-session renames from the library.
    /// Returns the new file URL on success.
    func renameFinalized(at filePath: URL, to newName: String) throws -> URL {
        let sanitized = sanitizedFilenameComponent(newName)
        guard !sanitized.isEmpty else { throw TranscriptLoggerError.cannotCreateFile("Empty name") }

        // Extract date prefix from existing filename (format: "yyyy-MM-dd HH-mm-ss ...")
        let existingName = filePath.deletingPathExtension().lastPathComponent
        let datePrefix: String
        if existingName.count >= 19 {
            datePrefix = String(existingName.prefix(19))
        } else {
            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "yyyy-MM-dd HH-mm-ss"
            datePrefix = dateFmt.string(from: Date())
        }

        let newFilename = "\(datePrefix) \(sanitized).md"
        let newPath = filePath.deletingLastPathComponent().appendingPathComponent(newFilename)

        // Read, update source_file, atomic rename
        var content = try String(contentsOf: filePath, encoding: .utf8)
        if let range = content.range(of: #"source_file: ".*""#, options: .regularExpression) {
            content.replaceSubrange(range, with: "source_file: \"\(newFilename)\"")
        }
        try atomicRewrite(at: filePath, newPath: newPath, content: content)
        return newPath
    }

    // MARK: - Speaker Labels

    private func labelForSpeaker(_ rawSpeaker: String) -> String {
        // "You" always maps to "You"
        if rawSpeaker.lowercased() == "you" { return "You" }

        // Check if we already assigned a label
        if let existing = speakerLabels[rawSpeaker] {
            return existing
        }

        // Assign new label
        speakerCounter += 1
        let label = "Speaker \(speakerCounter)"
        speakerLabels[rawSpeaker] = label
        return label
    }
}
