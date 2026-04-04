import SwiftUI

struct OllamaModelBrowseSheet: View {
    var ollamaState: OllamaState
    @Binding var selectedModel: String
    @Environment(\.dismiss) private var dismiss
    @State private var models: [OllamaModel] = []
    @State private var isLoading = true
    @State private var fetchError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Downloaded Models")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.fg1)
                .padding(.bottom, 4)

            Text("Select a model to use for analysis")
                .font(.system(size: 13))
                .foregroundStyle(Color.fg2)
                .padding(.bottom, 16)

            if isLoading {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(Color.accent1)
                        Text("Loading models...")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.fg3)
                    }
                    Spacer()
                }
                Spacer()
            } else if fetchError {
                Spacer()
                Text("Unable to connect to Ollama. Make sure Ollama is running.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fg2)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else if models.isEmpty {
                Spacer()
                Text("No models found -- run `ollama pull llama3.2:3b` in Terminal")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.fg2)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                List(models) { model in
                    HStack {
                        Text(model.name)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.fg1)
                        Spacer()
                        if model.name == selectedModel {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accent1)
                                .font(.system(size: 12))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedModel = model.name
                    }
                }
                .listStyle(.plain)
            }

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding(.top, 12)
        }
        .padding(24)
        .frame(minWidth: 400, minHeight: 300)
        .task {
            isLoading = true
            fetchError = false
            await ollamaState.refresh()
            models = ollamaState.models
            fetchError = ollamaState.connectionStatus != .connected
            isLoading = false
        }
    }
}
