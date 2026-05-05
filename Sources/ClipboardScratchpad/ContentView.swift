import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ScratchpadStore
    @State private var inputText = ""
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

            if store.blocks.isEmpty {
                Spacer()
                Text("Start typing or turn on capture to collect clips.")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(store.blocks) { block in
                                BlockRow(block: block)
                                    .id(block.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: store.blocks.count) { _, _ in
                        if let last = store.blocks.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            Divider()

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    TextEditor(text: $inputText)
                        .font(.body)
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )

                    Button("Add Note") {
                        submitManual()
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                HStack(spacing: 12) {
                    Button(store.isCapturing ? "Pause Capture" : "Start Capture") {
                        store.isCapturing.toggle()
                    }

                    Button("Copy All") {
                        let text = store.copyAll()
                        store.writeToPasteboard(text)
                    }
                    .disabled(store.blocks.isEmpty)

                    Button("Clear") {
                        if !store.blocks.isEmpty {
                            showingClearAlert = true
                        }
                    }
                    .disabled(store.blocks.isEmpty)
                }
            }
            .padding()

            Text("Captured text stays on this Mac.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
        .alert("Clear Scratchpad?", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                store.clear()
            }
        } message: {
            Text("This will remove all blocks. This cannot be undone.")
        }
    }

    private func submitManual() {
        store.appendManual(content: inputText)
        inputText = ""
    }
}

struct BlockRow: View {
    let block: ScratchBlock

    var body: some View {
        switch block {
        case .manual(let manual):
            ManualBlockRow(block: manual)
        case .captured(let captured):
            CapturedBlockRow(block: captured)
        }
    }
}

struct ManualBlockRow: View {
    let block: ManualBlock
    @EnvironmentObject var store: ScratchpadStore

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(block.content)
                .font(.body)
                .textSelection(.enabled)
            Spacer()
            Button {
                store.deleteBlock(id: block.id)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
    }
}

struct CapturedBlockRow: View {
    let block: CapturedBlock
    @EnvironmentObject var store: ScratchpadStore

    private var metadataText: String {
        let time = block.timestamp.formatted(date: .omitted, time: .shortened)
        if let app = block.sourceAppName {
            return "\(app) · \(time)"
        }
        return time
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(block.content)
                .font(.body)
                .textSelection(.enabled)

            Text(metadataText)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("Copy") {
                    store.writeToPasteboard(block.content)
                }
                Button("Convert") {
                    store.convertToManual(id: block.id)
                }
                Button("Delete") {
                    store.deleteBlock(id: block.id)
                }
            }
            .font(.caption)
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}
