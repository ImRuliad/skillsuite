import Testing
@testable import SkillSuite
import Foundation

/// FileWatcher wraps FSEvents — a real macOS kernel API.
/// Unit tests cover the public interface contract and lifecycle.
/// The integration test verifies the callback fires on an actual file write.
@Suite("FileWatcher")
@MainActor
struct FileWatcherTests {

    // MARK: - Lifecycle

    @Test("stop() before start() does not crash")
    func stopWithoutStart() {
        let watcher = FileWatcher()
        watcher.stop() // must not crash
    }

    @Test("stop() called twice does not crash")
    func doubleStop() {
        let watcher = FileWatcher()
        watcher.start(paths: [NSTemporaryDirectory()])
        watcher.stop()
        watcher.stop() // idempotent
    }

    @Test("start() with empty paths does not crash")
    func startEmptyPaths() {
        let watcher = FileWatcher()
        watcher.start(paths: [])
        watcher.stop()
    }

    @Test("Restarting replaces the previous stream")
    func restartReplacesStream() {
        let watcher = FileWatcher()
        watcher.start(paths: [NSTemporaryDirectory()])
        // Starting again must stop the previous stream without crashing
        watcher.start(paths: [NSTemporaryDirectory()])
        watcher.stop()
    }

    @Test("start stop start stop leaves stream nil")
    func startStopStartStopLeavesStreamNil() {
        let watcher = FileWatcher()
        watcher.start(paths: [NSTemporaryDirectory()])
        watcher.stop()
        watcher.start(paths: [NSTemporaryDirectory()])
        watcher.stop()

        #expect(watcher.stream == nil)
    }

    @Test("onChange is nil by default")
    func onChangeDefaultsNil() {
        let watcher = FileWatcher()
        #expect(watcher.onChange == nil)
    }

    @Test("onChange can be set and cleared")
    func onChangeAssignable() {
        let watcher = FileWatcher()
        watcher.onChange = { }
        #expect(watcher.onChange != nil)
        watcher.onChange = nil
        #expect(watcher.onChange == nil)
    }

    // MARK: - Integration: real FSEvents callback

    @Test("Fires onChange callback when a file is written in a watched directory")
    func callbackFiredOnFileWrite() async throws {
        // Create a temp directory unique to this test run
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("FileWatcherTest-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let watcher = FileWatcher()
        defer { watcher.stop() }

        var callbackFired = false
        watcher.onChange = { callbackFired = true }
        watcher.start(paths: [tmpDir.path])

        // Short delay to let FSEvents register the stream before writing
        try await Task.sleep(for: .milliseconds(100))

        // Write a file — this should trigger FSEvents
        let testFile = tmpDir.appendingPathComponent("trigger.md")
        try "hello".write(to: testFile, atomically: true, encoding: .utf8)

        // FSEvents latency is 0.25s; allow up to 1.5s for CI headroom
        let deadline = ContinuousClock.now + .seconds(1.5)
        while !callbackFired && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }

        #expect(callbackFired, "FSEvents callback should fire after file write within 1.5 seconds")
    }
}
