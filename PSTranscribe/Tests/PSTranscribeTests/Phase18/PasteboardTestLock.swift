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
///
/// IN-02 (KNOWN LIMITATION): the `defer { Task { await ...release() } }` pattern is
/// fire-and-forget. If Swift Testing tears the test down before the detached Task is
/// scheduled, the next `.serialized` test in the suite can `acquire()` while the
/// prior lease is notionally still held. In practice the `.serialized` trait gates
/// intra-suite parallelism and inter-suite tests are already gated by this lock, so
/// the practical risk is low and no flakiness has been observed. If a future test
/// flake is traced to this race, the fix is to convert the lock to a synchronous
/// release primitive (e.g. an `NSLock`-backed class) and replace each `defer` Task
/// with an explicit `await release()` at end-of-body.
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
