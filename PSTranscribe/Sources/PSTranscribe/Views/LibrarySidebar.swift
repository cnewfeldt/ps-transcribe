import SwiftUI

struct LibrarySidebar: View {
    let entries: [LibraryEntry]
    @Binding var selectedID: UUID?
    let activeEntryID: UUID?
    var onRename: ((UUID, String) -> Void)?

    var body: some View {
        if entries.isEmpty {
            emptyState
        } else {
            List(entries, id: \.id, selection: $selectedID) { entry in
                LibraryEntryRow(
                    entry: entry,
                    isSelected: selectedID == entry.id,
                    onRename: { newName in
                        onRename?(entry.id, newName)
                    }
                )
                .tag(entry.id)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.sidebar)
            .scrollContentBackground(.hidden)
            .background(Color.bg2)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.circle")
                .font(.system(size: 28))
                .foregroundStyle(Color.fg3)
            Text("No recordings yet")
                .font(.system(size: 12))
                .foregroundStyle(Color.fg2)
            Text("Start a call capture or voice memo to begin transcribing.")
                .font(.system(size: 11))
                .foregroundStyle(Color.fg3)
                .multilineTextAlignment(.center)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bg2)
    }
}
