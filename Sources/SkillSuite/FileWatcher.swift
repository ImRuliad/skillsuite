import Foundation
import CoreServices

/// Watches a set of filesystem paths for changes using FSEvents.
///
/// The 0.25s `latency` parameter passed to `FSEventStreamCreate` acts as the
/// built-in debounce — the callback will not fire more frequently than that
/// window even for rapid successive writes.
///
/// Owned by `AppModel`. Call `start(paths:)` after the initial scan completes.
/// Call `start(paths:)` again (it stops the existing stream internally) whenever
/// the watched path list changes (codebase added/removed).
final class FileWatcher: @unchecked Sendable {

    // MARK: - State

    private var stream: FSEventStreamRef?

    /// Called on the main thread when any watched path changes.
    var onChange: (() -> Void)?

    // MARK: - Public Interface

    func start(paths: [String]) {
        stop() // always tear down existing stream first
        guard !paths.isEmpty else { return }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
            guard let info else { return }
            let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
            watcher.onChange?()
        }

        stream = FSEventStreamCreate(
            nil,
            callback,
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.25,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        )

        guard let stream else { return }
        FSEventStreamSetDispatchQueue(stream, .main)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    deinit { stop() }
}
