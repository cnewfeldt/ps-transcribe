#!/usr/bin/env swift

// Phase 17 release tooling -- generates the model-manifest.json published to
// cnewfeldt/ps-transcribe-releases:main. Walks the on-disk parakeet model
// directory, computes SHA-256 per leaf file, emits JSON conforming to
// ModelManifest.Codable in PSTranscribe.
//
// RESEARCH Pitfall #1 (refined): the manifest enumerates LEAF FILES inside
// the .mlmodelc directories (e.g., "Encoder.mlmodelc/weights/weight.bin"),
// NOT the top-level .mlpackage names sketched in CONTEXT.md D-05. HuggingFace
// serves files at this granularity; SHA-256 per leaf file gives exact integrity.
//
// RESEARCH Pitfall #2: the on-disk folder name is `parakeet-tdt-0.6b-v3`
// (NOT `-coreml` suffixed). FluidAudio's Repo.folderName strips the suffix.
//
// Usage:
//   swift Scripts/generate-model-manifest.swift > model-manifest.json
//   swift Scripts/generate-model-manifest.swift --version=20260601 --min-app=1.3.0 > model-manifest.json
//   swift Scripts/generate-model-manifest.swift --models-dir=/custom/path > model-manifest.json
//
// Defaults:
//   --version    today as yyyyMMdd (UTC)
//   --min-app    "1.2.0" (Phase 17 ship target)
//   --models-dir ~/Library/Application Support/FluidAudio/Models/parakeet-tdt-0.6b-v3

import Foundation
import CryptoKit

struct ManifestFile: Codable {
    let name: String
    let url: String
    let sha256: String
    let size: Int64
}

struct ModelManifest: Codable {
    let model_id: String
    let version: String
    let min_app_version: String
    let total_size_bytes: Int64
    let released_at: String?
    let files: [ManifestFile]
}

// MARK: - CLI parsing

func parseArgs() -> (version: String, minApp: String, modelsDir: URL) {
    let now = Date()
    let f = DateFormatter()
    f.dateFormat = "yyyyMMdd"
    f.timeZone = TimeZone(identifier: "UTC")
    var version = f.string(from: now)
    var minApp = "1.2.0"

    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    var modelsDir = appSupport.appendingPathComponent("FluidAudio/Models/parakeet-tdt-0.6b-v3")

    for arg in CommandLine.arguments.dropFirst() {
        if arg.hasPrefix("--version=") {
            version = String(arg.dropFirst("--version=".count))
        } else if arg.hasPrefix("--min-app=") {
            minApp = String(arg.dropFirst("--min-app=".count))
        } else if arg.hasPrefix("--models-dir=") {
            modelsDir = URL(fileURLWithPath: String(arg.dropFirst("--models-dir=".count)))
        }
    }
    return (version, minApp, modelsDir)
}

// MARK: - Walking + hashing

func leafFiles(under root: URL) throws -> [URL] {
    let enumerator = FileManager.default.enumerator(
        at: root,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
    )
    var leaves: [URL] = []
    while let next = enumerator?.nextObject() as? URL {
        let values = try next.resourceValues(forKeys: [.isRegularFileKey])
        if values.isRegularFile == true { leaves.append(next) }
    }
    return leaves.sorted(by: { $0.path < $1.path })
}

func sha256Hex(of url: URL) throws -> String {
    let handle = try FileHandle(forReadingFrom: url)
    defer { try? handle.close() }
    var hasher = SHA256()
    while true {
        let chunk = try handle.read(upToCount: 256 * 1024) ?? Data()
        if chunk.isEmpty { break }
        hasher.update(data: chunk)
    }
    let digest = hasher.finalize()
    return digest.map { String(format: "%02x", $0) }.joined()
}

func relativeName(of url: URL, root: URL) -> String {
    // Drop the root prefix and the leading "/"
    let rootPath = root.standardizedFileURL.path
    var p = url.standardizedFileURL.path
    if p.hasPrefix(rootPath) { p.removeFirst(rootPath.count) }
    if p.hasPrefix("/") { p.removeFirst() }
    return p
}

// MARK: - Main

let args = parseArgs()
guard FileManager.default.fileExists(atPath: args.modelsDir.path) else {
    FileHandle.standardError.write(
        "ERROR: models directory not found at \(args.modelsDir.path)\n".data(using: .utf8) ?? Data()
    )
    exit(1)
}

let leaves = try leafFiles(under: args.modelsDir)
guard !leaves.isEmpty else {
    FileHandle.standardError.write("ERROR: no files under \(args.modelsDir.path)\n".data(using: .utf8) ?? Data())
    exit(1)
}

var entries: [ManifestFile] = []
var totalSize: Int64 = 0
for leaf in leaves {
    let size = (try leaf.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
    let sha = try sha256Hex(of: leaf)
    let name = relativeName(of: leaf, root: args.modelsDir)
    // HuggingFace URL pattern matches FluidAudio's DownloadUtils -- repo slug includes "-coreml".
    let url = "https://huggingface.co/FluidInference/parakeet-tdt-0.6b-v3-coreml/resolve/main/\(name)"
    entries.append(ManifestFile(name: name, url: url, sha256: sha, size: size))
    totalSize += size
}

let isoFmt = ISO8601DateFormatter()
let manifest = ModelManifest(
    model_id: "parakeet-tdt-0.6b-v3-coreml",
    version: args.version,
    min_app_version: args.minApp,
    total_size_bytes: totalSize,
    released_at: isoFmt.string(from: Date()),
    files: entries
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let data = try encoder.encode(manifest)
FileHandle.standardOutput.write(data)
FileHandle.standardOutput.write(Data([0x0A]))   // trailing newline
