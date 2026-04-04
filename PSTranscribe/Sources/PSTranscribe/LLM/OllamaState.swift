import Foundation
import Observation

@Observable
@MainActor
final class OllamaState {
    var connectionStatus: OllamaService.ConnectionStatus = .notFound
    var models: [OllamaModel] = []
    var isCheckingConnection = false

    private let service = OllamaService()

    func refresh() async {
        isCheckingConnection = true
        connectionStatus = await service.checkConnection()
        if connectionStatus == .connected {
            models = (try? await service.fetchModels()) ?? []
        } else {
            models = []
        }
        isCheckingConnection = false
    }
}
