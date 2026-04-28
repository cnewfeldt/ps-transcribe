import Foundation

/// Global mutex used by every Phase 18 test that touches `NSPasteboard.general`.
///
/// Swift Testing's `.serialized` trait only serializes tests WITHIN a suite — multiple
/// suites still run in parallel, which causes pasteboard races between suites
/// (`ClipboardRestoreTests` writes "OLD" while `DictationCommitFlowTests` is asleep
/// expecting "USER_OLD", etc.).
///
/// Pattern: every clipboard-touching test does
///   ```
///   await PasteboardTestLock.shared.acquire()
///   defer { Task { await PasteboardTestLock.shared.release() } }
///   ```
/// before any NSPasteboard read/write. The actor's serial reentrancy queue ensures
/// only one test at a time has live access to the system pasteboard.
actor PasteboardTestLock {
    static let shared = PasteboardTestLock()

    private var locked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if !locked {
            locked = true
            return
        }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            waiters.append(cont)
        }
    }

    func release() {
        guard !waiters.isEmpty else {
            locked = false
            return
        }
        let next = waiters.removeFirst()
        next.resume()
    }
}
