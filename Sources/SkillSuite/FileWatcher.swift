import Foundation
final class FileWatcher: @unchecked Sendable {
    var onChange: (() -> Void)?
    func start(paths _: [String]) {}
    func stop() {}
}
