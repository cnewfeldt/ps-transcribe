import Foundation
import Observation

/// Immutable result of a single analysis generation pass.
struct AnalysisResult: Sendable {
    let summary: String
    let actionItems: [String]
    let keyTopics: [String]
}

/// @Observable bridge between the `AnalysisCoordinator` actor and SwiftUI.
@Observable
@MainActor
final class AnalysisState {
    var summary: String = ""
    var actionItems: [String] = []
    var keyTopics: [String] = []
    var isUpdating: Bool = false

    var hasData: Bool {
        !summary.isEmpty || !actionItems.isEmpty || !keyTopics.isEmpty
    }

    func apply(_ result: AnalysisResult) {
        summary = result.summary
        actionItems = result.actionItems
        keyTopics = result.keyTopics
    }

    func clear() {
        summary = ""
        actionItems = []
        keyTopics = []
        isUpdating = false
    }
}
