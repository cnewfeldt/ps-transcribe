---
phase: 10
slug: final-defect-fixes-obsidian-deeplink
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-08
---

# Phase 10 -- Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Filesystem path -> session type | Transcript path compared against vault paths for type inference | Local file path (low sensitivity) |
| User vault path -> Obsidian URL | File path from LibraryEntry matched against Obsidian vault config | Local file path + vault name |
| App -> External app (Obsidian) | NSWorkspace.shared.open() launches Obsidian via custom URL scheme | obsidian:// URL with vault name + relative path |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-10-01 | Tampering | crash recovery path inference | accept | Path from SessionCheckpoint (app-written, not user input); defaults to .callCapture | closed |
| T-10-02 | Info Disclosure | removeUtterance speaker label | accept | Label from parsed transcript already on disk; no new information exposed | closed |
| T-10-03 | Tampering | makeObsidianURL file path | mitigate | `filePath.hasPrefix(vaultRoot)` guard at TranscriptParser.swift:109 prevents path traversal | closed |
| T-10-04 | Tampering | vault name derivation | accept | Derived from Obsidian's own config file (obsidian.json), not external input | closed |
| T-10-05 | Info Disclosure | obsidian:// URL | accept | Local-only data (vault name + relative path), not transmitted over network | closed |
| T-10-06 | Spoofing | NSWorkspace.shared.open | accept | Standard macOS URL scheme dispatch; malicious app registration is OS-level concern | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-10-01 | T-10-01 | SessionCheckpoint is app-internal; no external input vector | Claude (automated) | 2026-04-08 |
| AR-10-02 | T-10-02 | Speaker labels come from already-parsed transcript content on disk | Claude (automated) | 2026-04-08 |
| AR-10-03 | T-10-04 | Vault name read from user's local Obsidian config, not external | Claude (automated) | 2026-04-08 |
| AR-10-04 | T-10-05 | obsidian:// URL only contains local filesystem paths, never sent to network | Claude (automated) | 2026-04-08 |
| AR-10-05 | T-10-06 | URL scheme spoofing is a macOS system-level concern, standard app behavior | Claude (automated) | 2026-04-08 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-08 | 6 | 6 | 0 | Claude Opus 4.6 |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-08
