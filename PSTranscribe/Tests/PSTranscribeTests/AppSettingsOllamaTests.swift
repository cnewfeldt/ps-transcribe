import Testing
import Foundation
@testable import PSTranscribe

@Suite("AppSettings Ollama Tests")
struct AppSettingsOllamaTests {

    @Test @MainActor func selectedOllamaModelPersistsToUserDefaults() {
        // Clean slate
        UserDefaults.standard.removeObject(forKey: "selectedOllamaModel")

        let settings = AppSettings()
        #expect(settings.selectedOllamaModel == "")

        settings.selectedOllamaModel = "llama3.2:3b"
        let stored = UserDefaults.standard.string(forKey: "selectedOllamaModel")
        #expect(stored == "llama3.2:3b")

        // New instance reads persisted value
        let settings2 = AppSettings()
        #expect(settings2.selectedOllamaModel == "llama3.2:3b")

        // Cleanup
        UserDefaults.standard.removeObject(forKey: "selectedOllamaModel")
    }
}
