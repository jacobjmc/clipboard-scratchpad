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
        HStack(spacing: 10) {
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

            Button {
                showActionMenu()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
            .help("Clip actions")
            .accessibilityLabel("Clip actions")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay(
            ClipRightClickView {
                showActionMenu()
            }
        )
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

private struct ClipRightClickView: NSViewRepresentable {
    let onRightClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = RightClickView()
        view.onRightClick = onRightClick
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        guard let view = nsView as? RightClickView else { return }
        view.onRightClick = onRightClick
    }

    private final class RightClickView: NSView {
        var onRightClick: (() -> Void)?

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = window?.currentEvent,
                  event.type == .rightMouseDown || event.type == .rightMouseUp else {
                return nil
            }
            return self
        }

        override func rightMouseDown(with event: NSEvent) {
            onRightClick?()
        }
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

private final class ClipMenuItemView: NSView {
    private static let itemSize = NSSize(width: 216, height: 40)
    private static let iconSize = NSSize(width: 16, height: 16)

    private let action: () -> Void
    private let isEnabled: Bool
    private var trackingArea: NSTrackingArea?
    private var isHovered = false {
        didSet {
            needsDisplay = true
        }
    }

    init(title: String, image: NSImage?, isEnabled: Bool, isDestructive: Bool, action: @escaping () -> Void) {
        self.action = action
        self.isEnabled = isEnabled
        super.init(frame: NSRect(origin: .zero, size: Self.itemSize))
        wantsLayer = true

        let imageView = NSImageView(frame: NSRect(x: 15, y: 12, width: Self.iconSize.width, height: Self.iconSize.height))
        imageView.image = image
        imageView.contentTintColor = isDestructive ? .systemRed : .secondaryLabelColor
        imageView.alphaValue = isEnabled ? 1 : 0.45
        addSubview(imageView)

        let label = NSTextField(labelWithString: title)
        label.frame = NSRect(x: 42, y: 10, width: 158, height: 20)
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = isDestructive ? .systemRed : .labelColor
        label.alphaValue = isEnabled ? 1 : 0.45
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard isEnabled, isHovered else { return }
        NSColor.selectedContentBackgroundColor.withAlphaComponent(0.25).setFill()
        let rect = bounds.insetBy(dx: 6, dy: 4)
        NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7).fill()
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        enclosingMenuItem?.menu?.cancelTracking()
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
        item.view = ClipMenuItemView(
            title: title,
            image: menuImage(image: image, systemSymbolName: systemSymbolName, title: title),
            isEnabled: isEnabled,
            isDestructive: isDestructive,
            action: action
        )

        addItem(item)
    }

    private func menuImage(image: NSImage?, systemSymbolName: String?, title: String) -> NSImage? {
        if let image {
            image.size = NSSize(width: 16, height: 16)
            return image
        }
        if let systemSymbolName {
            return NSImage(systemSymbolName: systemSymbolName, accessibilityDescription: title)
        }
        return nil
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
