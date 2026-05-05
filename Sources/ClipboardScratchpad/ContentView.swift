import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ScratchpadStore
    @State private var showingClearAlert = false
    @State private var isShowingClips = false
    @State private var isPinned = false

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

            HStack {
                Spacer()

                HStack(spacing: 16) {
                    Button {
                        isPinned.toggle()
                        NotificationCenter.default.post(name: .scratchpadPinChanged, object: isPinned)
                    } label: {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isPinned ? .primary : .secondary)
                    .help("Pin window")
                    .accessibilityLabel("Pin window")

                    Button {
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    .accessibilityLabel("Settings")
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 32)

            PlainTextView(text: $store.noteText) {
                store.noteDidChange()
            }

            Divider()

            if isShowingClips {
                ClipShelfDrawer(
                    clips: store.clips,
                    onInsert: { store.insertClip($0) },
                    onClear: { store.clearClips() }
                )
                Divider()
            }

            HStack(spacing: 12) {
                ScratchpadMetaBar(text: store.noteText, updatedAt: store.updatedAt)

                Spacer(minLength: 12)

                HStack(spacing: 16) {
                    Button {
                        isShowingClips.toggle()
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "tray.full")
                                .font(.body)
                            if !store.clips.isEmpty {
                                Text("\(min(store.clips.count, 50))")
                                    .font(.system(size: 9, weight: .semibold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color.secondary.opacity(0.18)))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(isShowingClips ? .primary : .secondary)
                    .help("Clips")
                    .accessibilityLabel("Clips")

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
            }
            .padding(.horizontal, 14)
            .frame(height: 32)

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

private struct ClipShelfDrawer: View {
    let clips: [ClipShelfItem]
    let onInsert: (ClipShelfItem) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clips")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Clear") {
                    onClear()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .disabled(clips.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            if clips.isEmpty {
                Text("No clips")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(clips) { clip in
                            ClipShelfRow(clip: clip) {
                                onInsert(clip)
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
    }
}

private struct ClipShelfRow: View {
    let clip: ClipShelfItem
    let onInsert: () -> Void

    var body: some View {
        Button(action: onInsert) {
            VStack(alignment: .leading, spacing: 4) {
                Text(clip.content)
                    .font(.system(size: 12))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(metadata)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var metadata: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let time = formatter.localizedString(for: clip.capturedAt, relativeTo: Date())
        if let sourceAppName = clip.sourceAppName, !sourceAppName.isEmpty {
            return "\(sourceAppName) · \(time)"
        }
        return time
    }
}

private struct ScratchpadMetaBar: View {
    let text: String
    let updatedAt: Date?

    private var metrics: TextMetrics {
        TextMetrics(text: text)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(metrics.summary)
                .lineLimit(1)

            Divider()
                .frame(height: 14)
                .padding(.horizontal, 10)

            Text(relativeUpdatedAt)
                .lineLimit(1)
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(.secondary)
    }

    private var relativeUpdatedAt: String {
        guard let updatedAt else { return "Never" }

        let seconds = Date().timeIntervalSince(updatedAt)
        if seconds < 60 {
            return "Just now"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}

private struct TextMetrics {
    let lineCount: Int
    let wordCount: Int
    let characterCount: Int

    init(text: String) {
        if text.isEmpty {
            lineCount = 0
        } else {
            lineCount = text.components(separatedBy: .newlines).count
        }

        wordCount = text
            .split { character in
                character.isWhitespace || character.isNewline
            }
            .count

        characterCount = text.count
    }

    var summary: String {
        "\(lineCount) \(lineCount == 1 ? "line" : "lines") · \(wordCount) \(wordCount == 1 ? "word" : "words") · \(characterCount) \(characterCount == 1 ? "character" : "characters")"
    }
}
