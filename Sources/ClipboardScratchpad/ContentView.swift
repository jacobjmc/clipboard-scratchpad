import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ScratchpadStore
    @State private var showingClearAlert = false

    var body: some View {
        VStack(spacing: 0) {
            if let warning = store.persistenceWarning {
                Text(warning)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
            }

            PlainTextView(text: $store.noteText) {
                store.scheduleSave()
            }

            Divider()

            HStack(spacing: 16) {
                Button {
                    store.setCapturing(!store.isCapturing)
                } label: {
                    Image(systemName: store.isCapturing ? "pause.fill" : "play.fill")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help(store.isCapturing ? "Pause Capturing" : "Start Capturing")
                .accessibilityLabel(store.isCapturing ? "Pause Capturing" : "Start Capturing")

                Button {
                    store.copyAll()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Copy All")
                .accessibilityLabel("Copy All")
                .disabled(store.noteText.isEmpty)

                Button {
                    if !store.noteText.isEmpty {
                        showingClearAlert = true
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Clear")
                .accessibilityLabel("Clear")
                .disabled(store.noteText.isEmpty)
            }
            .padding(.vertical, 8)

            if let message = store.toolbarMessage {
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                    .transition(.opacity)
            }
        }
        .alert("Clear Scratchpad?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                store.clear()
            }
        } message: {
            Text("This will remove all content. This cannot be undone.")
        }
    }
}
