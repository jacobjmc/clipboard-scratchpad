# Clip Shelf Design

## Summary

Clipboard Scratchpad will stop auto-inserting copied text into the note. Instead, copied text will be captured into a persisted Clip Shelf while the app is running. The sticky note remains a user-controlled editable document, and the user explicitly inserts clips when they want them in the note.

## Goals

- Keep the sticky note from getting clogged by every copied item.
- Preserve useful copied text in an easy-to-access shelf.
- Make insertion explicit and fast.
- Keep the app small, native, and focused.
- Avoid turning v1 into a full clipboard manager.

## Product Behavior

Clipboard capture is always on while the app is running. There is no capture toggle.

When the user copies plain text from another app:

1. The copied text is captured into Clip Shelf.
2. The sticky note does not change.
3. The Clips badge updates.

When the user wants a clip in the note, they open Clips and click a clip. The clip inserts at the current cursor or replaces the current selection. If there is no active cursor, insertion appends to the end of the note.

The shelf keeps the 50 most recent clips and persists across app launches. A Clear Clips action removes shelf items without touching the note.

## UI Design

The main view remains the sticky note.

The bottom toolbar contains:

- Clips button with badge count.
- Existing note metadata.
- Copy All button.
- Clear note button.

The previous capture toggle is removed.

When Clips is closed:

- The Clips button appears in the bottom toolbar.
- The badge shows the number of saved clips.
- Note metadata stays visually blended into the bottom bar.

When Clips is open:

- The Clips button is highlighted.
- An inline drawer appears directly above the bottom toolbar.
- Clips are shown newest-first.
- Each row shows a short preview plus source/time metadata.
- Clicking a clip inserts it into the note.
- Inserted clips remain in the shelf.
- The drawer includes a Clear Clips control.

When the shelf is empty, the drawer shows a compact empty state with no explanatory instructions.

Drag-and-drop and double-click insertion are out of scope for the first implementation.

## Data Model

Add a persisted clip item:

```swift
struct ClipShelfItem: Codable, Identifiable, Equatable {
    let id: UUID
    let content: String
    let capturedAt: Date
    let sourceAppName: String?
    let sourceBundleID: String?
}
```

Store state persists both the note and shelf:

```swift
struct StoreState: Codable {
    var noteText: String
    var updatedAt: Date?
    var clips: [ClipShelfItem]
}
```

Old saved JSON without `clips` must continue to load with an empty shelf.

`ScratchpadStore` should expose small explicit methods:

```swift
func captureClipboardText(_ content: String, sourceAppName: String?, sourceBundleID: String?)
func insertClip(_ clip: ClipShelfItem)
func clearClips()
```

## Data Flow

`ClipboardMonitor` continues to poll `NSPasteboard.changeCount` on the main thread.

Because the capture toggle is removed, the store starts clipboard monitoring during app startup and stops it when the app quits.

On external copy:

1. Monitor detects a pasteboard change.
2. Monitor reads plain text.
3. Monitor reads `NSWorkspace.shared.frontmostApplication` for source app metadata.
4. Monitor passes content, `localizedName`, and `bundleIdentifier` to `ScratchpadStore.captureClipboardText`.
5. If source app metadata is unavailable, store `nil` for the missing fields.
6. Store trims whitespace for validation and duplicate comparison.
7. Store ignores empty text.
8. Store ignores consecutive duplicate normalized text.
9. Store creates a `ClipShelfItem` with the original untrimmed content.
10. Store inserts the item at the front of `clips`.
11. Store trims `clips` to 50 items.
12. Store saves note and clips together.

Clip row metadata should display:

- source app name and relative capture time when `sourceAppName` is available.
- relative capture time only when source app name is unavailable.

On app-owned pasteboard writes:

1. Store writes to `NSPasteboard`.
2. Store immediately calls `clipboardMonitor.noteExternalPasteboardWrite()`.
3. `ClipboardMonitor` records `NSPasteboard.general.changeCount`.
4. Later polling ignores that already-recorded change count.

This is the same contract currently used by Copy All and should remain the mechanism for preventing app writes from being captured.

On clip insertion:

1. User clicks a clip row.
2. Store calls `insertClip(_:)`.
3. Store posts `Notification.Name.scratchpadInsertText`.
4. Notification payload is `userInfo["content"] as String`.
5. `PlainTextView.Coordinator` owns the observer, inserts the content at the current selection, and removes the observer in `deinit`.
6. If no insertion point is active, `PlainTextView` appends to the end.
7. The normal note text-change path updates `noteText`, `updatedAt`, and persistence.

The text editor remains responsible for cursor-sensitive insertion.

## Insertion Contract

`PlainTextView` should support one notification for clip insertion:

```swift
extension Notification.Name {
    static let scratchpadInsertText = Notification.Name("scratchpadInsertText")
}
```

Payload:

```swift
["content": clip.content]
```

Insertion behavior:

- If the text view has a selected range, replace it.
- If the text view has an insertion point, insert there.
- If the text view is not first responder or has no valid selection, append to the end.
- Insertion should participate in the note's undo stack.
- Insertion should not remove the clip from the shelf.

## Edge Cases

- Empty or whitespace-only clipboard text is ignored.
- Consecutive duplicate clipboard text is ignored after trimming leading and trailing whitespace.
- Clipboard writes made by this app are ignored, so Copy All does not create a new clip.
- Clip insertion replaces selected text.
- Clip insertion appends if no cursor exists.
- Clear note does not clear clips.
- Clear clips does not clear the note.
- Inserted clips remain in the shelf.
- Existing saved state without clips loads successfully.
- Non-text clipboard content is ignored.

## Implementation Notes

Keep the implementation small:

- Extend the existing store instead of adding a separate persistence layer.
- Keep JSON persistence in `~/Library/Application Support/ClipboardScratchpad/`.
- Keep clipboard access on the main thread.
- Do not add dependencies.
- Do not add a test target for this change.

## Manual Verification

Run with `swift run` and verify:

- Copied text appears in Clip Shelf, not the note.
- Clips badge updates as clips are captured.
- Clips drawer opens inline above the bottom toolbar.
- Clips button highlights while drawer is open.
- Clicking a clip inserts it at the current cursor.
- Selecting text then clicking a clip replaces the selection.
- Copy All does not create a new clip.
- Clear note leaves clips intact.
- Clear Clips leaves the note intact.
- Clips persist after relaunch.
- Old saved state loads with an empty clip shelf.
