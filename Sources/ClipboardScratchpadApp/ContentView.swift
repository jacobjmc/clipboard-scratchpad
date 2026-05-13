import AppKit
import SwiftUI
import ClipboardScratchpadLib

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
                Button {
                    NotificationCenter.default.post(name: .scratchpadCloseRequested, object: nil)
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.body)
                        .frame(width: 30, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Close")
                .accessibilityLabel("Close window")

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
            .background(VisualEffectBar())

            if isShowingClips {
                VSplitView {
                    PlainTextView(text: $store.noteText) {
                        store.noteDidChange()
                    }
                    .frame(minHeight: 96)

                    ClipShelfDrawer(
                        clips: store.clips,
                        previousAppName: store.previousExternalAppName,
                        previousAppIcon: store.previousExternalAppIcon,
                        canPasteToPreviousApp: store.hasPreviousExternalApplication,
                        feedback: store.clipFeedback,
                        onInsert: { store.insertClip($0) },
                        onPaste: { store.pasteClipToPreviousApp($0) },
                        onCopy: { store.copyClip($0) },
                        onDelete: { store.deleteClip($0) },
                        onClear: { store.clearClips() },
                        onCollapse: { isShowingClips = false }
                    )
                    .frame(minHeight: 104, idealHeight: 220)
                }
                .frame(maxHeight: .infinity)
                Divider()
            } else {
                PlainTextView(text: $store.noteText) {
                    store.noteDidChange()
                }
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
            .background(VisualEffectBar())
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

private struct VisualEffectBar: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .headerView
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
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
    let feedback: (clipID: UUID, message: String)?
    let onInsert: (ClipShelfItem) -> Void
    let onPaste: (ClipShelfItem) -> Void
    let onCopy: (ClipShelfItem) -> Void
    let onDelete: (ClipShelfItem) -> Void
    let onClear: () -> Void
    let onCollapse: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clips")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Button {
                    onCollapse()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .help("Collapse clips")
                .accessibilityLabel("Collapse clips")

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
                ClipShelfTable(
                    clips: clips,
                    previousAppName: previousAppName,
                    previousAppIcon: previousAppIcon,
                    canPasteToPreviousApp: canPasteToPreviousApp,
                    feedback: feedback,
                    onInsert: onInsert,
                    onPaste: onPaste,
                    onCopy: onCopy,
                    onDelete: onDelete
                )
                .frame(maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.55))
    }
}

private struct ClipShelfTable: NSViewRepresentable {
    let clips: [ClipShelfItem]
    let previousAppName: String?
    let previousAppIcon: NSImage?
    let canPasteToPreviousApp: Bool
    let feedback: (clipID: UUID, message: String)?
    let onInsert: (ClipShelfItem) -> Void
    let onPaste: (ClipShelfItem) -> Void
    let onCopy: (ClipShelfItem) -> Void
    let onDelete: (ClipShelfItem) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let tableView = ClipNSTableView()
        tableView.headerView = nil
        tableView.rowHeight = 62
        tableView.intercellSpacing = NSSize(width: 0, height: 0)
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .none
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        tableView.dataSource = context.coordinator
        tableView.delegate = context.coordinator
        tableView.clipCoordinator = context.coordinator

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("clip"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = tableView

        context.coordinator.tableView = tableView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let shouldReload = context.coordinator.shouldReload(for: self)
        context.coordinator.parent = self
        if let tableView = scrollView.documentView as? NSTableView {
            tableView.frame.size.width = scrollView.contentSize.width
            if shouldReload {
                tableView.reloadData()
            }
        }
    }

    final class Coordinator: NSObject, NSTableViewDataSource, NSTableViewDelegate {
        var parent: ClipShelfTable
        weak var tableView: NSTableView?
        private var clipIDs: [UUID]
        private var feedbackID: UUID?
        private var feedbackMessage: String?
        private var previousAppName: String?
        private var canPasteToPreviousApp: Bool

        init(_ parent: ClipShelfTable) {
            self.parent = parent
            self.clipIDs = parent.clips.map(\.id)
            self.feedbackID = parent.feedback?.clipID
            self.feedbackMessage = parent.feedback?.message
            self.previousAppName = parent.previousAppName
            self.canPasteToPreviousApp = parent.canPasteToPreviousApp
        }

        func shouldReload(for nextParent: ClipShelfTable) -> Bool {
            let nextClipIDs = nextParent.clips.map(\.id)
            let changed = clipIDs != nextClipIDs
                || feedbackID != nextParent.feedback?.clipID
                || feedbackMessage != nextParent.feedback?.message
                || previousAppName != nextParent.previousAppName
                || canPasteToPreviousApp != nextParent.canPasteToPreviousApp

            clipIDs = nextClipIDs
            feedbackID = nextParent.feedback?.clipID
            feedbackMessage = nextParent.feedback?.message
            previousAppName = nextParent.previousAppName
            canPasteToPreviousApp = nextParent.canPasteToPreviousApp
            return changed
        }

        func numberOfRows(in tableView: NSTableView) -> Int {
            parent.clips.count
        }

        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            62
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard parent.clips.indices.contains(row) else { return nil }
            let clip = parent.clips[row]
            let view = ClipTableCellView()
            view.configure(clip: clip, feedback: parent.feedback?.clipID == clip.id ? parent.feedback?.message : nil)
            view.onActions = { [weak self] in
                self?.showMenu(for: clip)
            }
            return view
        }

        func showMenu(for clip: ClipShelfItem) {
            guard let event = NSApp.currentEvent,
                  let view = event.window?.contentView else { return }
            NSMenu.popUpContextMenu(menu(for: clip), with: event, for: view)
        }

        private func menu(for clip: ClipShelfItem) -> NSMenu {
            let menu = NSMenu()
            menu.addActionItem(
                title: pasteTitle,
                image: parent.previousAppIcon,
                isEnabled: parent.canPasteToPreviousApp,
                action: { [parent] in parent.onPaste(clip) }
            )
            menu.addActionItem(title: "Copy to Clipboard", systemSymbolName: "doc.on.doc") { [parent] in
                parent.onCopy(clip)
            }
            menu.addActionItem(title: "Paste to Note", systemSymbolName: "note.text") { [parent] in
                parent.onInsert(clip)
            }
            menu.addItem(.separator())
            menu.addActionItem(title: "Delete Entry", systemSymbolName: "trash", isDestructive: true) { [parent] in
                parent.onDelete(clip)
            }
            return menu
        }

        private var pasteTitle: String {
            if let previousAppName = parent.previousAppName, !previousAppName.isEmpty {
                return "Paste to \(previousAppName)"
            }
            return "Paste to Previous App"
        }
    }
}

private final class ClipNSTableView: NSTableView {
    weak var clipCoordinator: ClipShelfTable.Coordinator?

    override func mouseDown(with event: NSEvent) {
        showMenu(for: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        showMenu(for: event)
    }

    private func showMenu(for event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let rowIndex = row(at: point)
        guard rowIndex >= 0,
              let coordinator = clipCoordinator,
              coordinator.parent.clips.indices.contains(rowIndex) else { return }
        coordinator.showMenu(for: coordinator.parent.clips[rowIndex])
    }
}

private final class ClipTableCellView: NSTableCellView {
    var onActions: (() -> Void)?

    private let titleField = NSTextField(labelWithString: "")
    private let metadataField = NSTextField(labelWithString: "")
    private let actionsButton = NSButton()
    private var trackingArea: NSTrackingArea?
    private var isHovered = false {
        didSet {
            needsDisplay = true
        }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true

        titleField.font = .systemFont(ofSize: 12)
        titleField.textColor = .labelColor
        titleField.lineBreakMode = .byTruncatingTail
        titleField.maximumNumberOfLines = 2

        metadataField.font = .systemFont(ofSize: 10, weight: .medium)
        metadataField.textColor = .secondaryLabelColor
        metadataField.lineBreakMode = .byTruncatingTail

        actionsButton.image = NSImage(systemSymbolName: "ellipsis", accessibilityDescription: "Clip actions")
        actionsButton.bezelStyle = .regularSquare
        actionsButton.isBordered = false
        actionsButton.target = self
        actionsButton.action = #selector(actionsClicked)
        actionsButton.contentTintColor = .secondaryLabelColor

        addSubview(titleField)
        addSubview(metadataField)
        addSubview(actionsButton)
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(clip: ClipShelfItem, feedback: String?) {
        titleField.stringValue = clip.content
        metadataField.stringValue = feedback ?? metadata(for: clip)
        metadataField.textColor = feedback == nil ? .secondaryLabelColor : .controlAccentColor
    }

    override func layout() {
        super.layout()
        actionsButton.frame = NSRect(x: bounds.width - 44, y: 16, width: 30, height: 30)
        titleField.frame = NSRect(x: 14, y: 31, width: max(0, bounds.width - 62), height: 18)
        metadataField.frame = NSRect(x: 14, y: 13, width: max(0, bounds.width - 62), height: 15)
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
        guard isHovered else { return }
        NSColor.selectedContentBackgroundColor.withAlphaComponent(0.16).setFill()
        let rect = bounds.insetBy(dx: 6, dy: 4)
        NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7).fill()
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }

    @objc private func actionsClicked() {
        onActions?()
    }

    private func metadata(for clip: ClipShelfItem) -> String {
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
