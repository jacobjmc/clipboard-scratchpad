import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: ScratchpadStore
    @State private var showingClearAlert = false
    @State private var isShowingClips = false
    @State private var isShowingSettings = false

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
                        store.isPinned.toggle()
                    } label: {
                        Image(systemName: store.isPinned ? "pin.fill" : "pin")
                            .font(.body)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(store.isPinned ? .primary : .secondary)
                    .help("Pin window")
                    .accessibilityLabel("Pin window")

                    Button {
                        store.refreshAccessibilityStatus()
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.body)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                    .accessibilityLabel("Settings")
                    .popover(isPresented: $isShowingSettings, arrowEdge: .top) {
                        SettingsView()
                            .environmentObject(store)
                    }
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
                    previousAppName: store.previousExternalAppName,
                    previousAppIcon: store.previousExternalAppIcon,
                    canPasteToPreviousApp: store.hasPreviousExternalApplication,
                    onInsert: { store.insertClip($0) },
                    onPaste: { store.pasteClipToPreviousApp($0) },
                    onCopy: { store.copyClip($0) },
                    onDelete: { store.deleteClip($0) },
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
                        .frame(height: 30)
                        .contentShape(Rectangle())
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
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
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
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
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

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: ScratchpadStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Settings")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("Close")
                .accessibilityLabel("Close settings")
            }

            Divider()

            HStack(alignment: .center, spacing: 12) {
                Image(systemName: store.isAccessibilityTrusted ? "checkmark.circle.fill" : "exclamationmark.circle")
                    .foregroundColor(store.isAccessibilityTrusted ? .green : .secondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Accessibility")
                        .font(.system(size: 13, weight: .semibold))
                    Text(store.isAccessibilityTrusted ? "Enabled" : "Required for paste actions")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(store.isAccessibilityTrusted ? "Refresh" : "Enable") {
                    if store.isAccessibilityTrusted {
                        store.refreshAccessibilityStatus()
                    } else {
                        store.requestAccessibilityPermission()
                    }
                }
                .controlSize(.small)
            }
        }
        .padding(18)
        .frame(width: 360)
        .presentationCompactAdaptation(.popover)
        .onAppear {
            store.refreshAccessibilityStatus()
        }
    }
}

private struct ClipShelfDrawer: View {
    let clips: [ClipShelfItem]
    let previousAppName: String?
    let previousAppIcon: NSImage?
    let canPasteToPreviousApp: Bool
    let onInsert: (ClipShelfItem) -> Void
    let onPaste: (ClipShelfItem) -> Void
    let onCopy: (ClipShelfItem) -> Void
    let onDelete: (ClipShelfItem) -> Void
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
                            ClipShelfRow(
                                clip: clip,
                                previousAppName: previousAppName,
                                previousAppIcon: previousAppIcon,
                                canPasteToPreviousApp: canPasteToPreviousApp,
                                onInsert: { onInsert(clip) },
                                onPaste: { onPaste(clip) },
                                onCopy: { onCopy(clip) },
                                onDelete: { onDelete(clip) }
                            )
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
    let previousAppName: String?
    let previousAppIcon: NSImage?
    let canPasteToPreviousApp: Bool
    let onInsert: () -> Void
    let onPaste: () -> Void
    let onCopy: () -> Void
    let onDelete: () -> Void

    var body: some View {
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
        .onTapGesture {
            showActionMenu()
        }
    }

    private func showActionMenu() {
        guard let event = NSApp.currentEvent else { return }

        let menu = NSMenu()
        menu.addActionItem(
            title: pasteTitle,
            image: previousAppIcon,
            isEnabled: canPasteToPreviousApp,
            action: onPaste
        )
        menu.addActionItem(title: "Copy to Clipboard", systemSymbolName: "doc.on.doc", action: onCopy)
        menu.addActionItem(title: "Paste to Note", systemSymbolName: "note.text", action: onInsert)
        menu.addItem(.separator())
        menu.addActionItem(title: "Delete Entry", systemSymbolName: "trash", isDestructive: true, action: onDelete)

        NSMenu.popUpContextMenu(menu, with: event, for: event.window?.contentView ?? NSView())
    }

    private var pasteTitle: String {
        if let previousAppName, !previousAppName.isEmpty {
            return "Paste to \(previousAppName)"
        }
        return "Paste to Previous App"
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

private final class MenuAction: NSObject {
    private let action: () -> Void

    init(_ action: @escaping () -> Void) {
        self.action = action
    }

    @objc func runMenuAction() {
        action()
    }
}

private extension NSMenu {
    func addActionItem(
        title: String,
        image: NSImage? = nil,
        systemSymbolName: String? = nil,
        isEnabled: Bool = true,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) {
        let menuAction = MenuAction(action)
        let item = NSMenuItem(title: title, action: #selector(MenuAction.runMenuAction), keyEquivalent: "")
        item.target = menuAction
        item.representedObject = menuAction
        item.isEnabled = isEnabled
        if let image {
            image.size = NSSize(width: 16, height: 16)
            item.image = image
        } else if let systemSymbolName {
            item.image = NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: title)
        }

        if isDestructive {
            item.attributedTitle = NSAttributedString(
                string: title,
                attributes: [.foregroundColor: NSColor.systemRed]
            )
        }

        addItem(item)
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
