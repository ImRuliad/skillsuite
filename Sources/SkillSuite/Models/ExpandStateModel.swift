struct ExpandStateModel: Sendable {
    var providerExpanded: [AIProvider: Bool] = [:]
    var codebaseExpanded: [String: Bool] = [:]
    var subdirectoryExpanded: [String: Bool] = [:]
}
