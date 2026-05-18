# Clipboard Scratchpad Context

## Product

Clipboard Scratchpad is a lightweight macOS menu bar utility for temporary text collection and drafting.

The app gives the user one editable plain-text scratchpad plus a recent clip shelf. Copied text is captured into the shelf, and the user can insert useful clips into the scratchpad when needed.

The product should stay local-first, fast, and single-purpose. It should not become a full clipboard manager, notes database, research system, or AI writing tool.

## Current App Shape

- macOS 14+ menu bar app.
- AppKit app shell with a status bar item and popover.
- SwiftUI content inside the popover.
- Plain text editor backed by `NSTextView`.
- Clipboard polling via `NSPasteboard.changeCount`.
- Recent clip shelf with captured text, source app metadata, capture time, and a cap of 50 clips.
- Clip Shelf rows should use a native AppKit list implementation, such as `NSTableView`, embedded in the SwiftUI drawer.
- Clicking a clip opens a clip action menu.
- The clip action menu includes paste to the previously focused external app, copy to clipboard, paste to note, and delete entry. The note action is labeled `Paste to Note`.
- Copy-all writes the scratchpad text to the clipboard.
- Clear removes the scratchpad after confirmation.
- The scratchpad opens as a menu bar popover by default.
- Dragging the anchored popover away from the menu bar creates a detached window. Detached window mode does not turn on pinned mode.
- Pinning promotes the scratchpad into a real floating window or panel that can be moved around the screen.
- Unpinning returns the scratchpad to the normal anchored popover behavior. The last floating position is retained for the next pinned session.
- The last detached or pinned window frame persists across app launches and should be restored only when the saved frame is still visible on an available display. If the saved frame is no longer visible, the window should fall back to the default position below the menu bar item.
- Pin state does not persist across launches; the app starts in normal menu bar popover mode.
- While the pinned floating window is open, clicking the menu bar item hides or shows that same window. It does not unpin the scratchpad or replace it with the popover.
- A configured global hotkey should toggle the scratchpad surface while the Clipboard Scratchpad app process is already running. It should show the anchored popover when no scratchpad surface is visible, bring an existing detached window to the front if one exists, show or bring forward the pinned floating window when pinned mode is active, and hide the anchored popover when it is visible. It should not launch the app if Clipboard Scratchpad is not already running.
- Global hotkey behavior is toggle-like for anchored popover and pinned floating window states, but detached windows are treated as window-like: if a detached window exists, the hotkey should bring it forward rather than hide it.
- Global hotkey registration should not depend on Accessibility permission. Accessibility permission remains specific to paste-to-previous-app behavior.
- The global hotkey should start unassigned. The app should register a global hotkey only after the user records one in Settings, and Settings should provide a clear `None` state plus a way to clear the shortcut.
- A recorded global hotkey must include at least one non-Shift modifier plus a normal key. Single-key shortcuts, Shift-only shortcuts, modifier-only shortcuts, Escape, Return, and arrow-key shortcuts are invalid for the global hotkey.
- The recorder should reject obvious reserved shortcuts locally before attempting registration, including common Command shortcuts for copy, paste, cut, select all, undo, save, quit, close, new, open, and print. System registration should still be the source of truth for real global conflicts.
- If the user records a shortcut that cannot be registered, such as because another app already owns it, Settings should show that registration failed. The app should keep the previous working shortcut active and should not save the new shortcut unless registration succeeds.
- The chosen global hotkey should persist in the local JSON app state and register on launch. If launch-time registration fails, Settings should still show the saved shortcut with a failed or unavailable status so the user can replace or clear it.
- Settings should describe the global hotkey as opening or showing Clipboard Scratchpad while the app is running. The UI should make clear that the app must already be open for the shortcut to work.
- In Settings, the global hotkey row should be labeled `Global Shortcut` with the description `Show Clipboard Scratchpad while the app is open.` The value control should show `None` or the current shortcut. Clicking it enters recording mode with `Press shortcut`. Escape cancels recording. Delete or Backspace clears the shortcut. Error or status copy should appear only when needed, such as `Shortcut unavailable`.
- The pinned floating surface should feel like a borderless utility panel and keep the app's in-content header controls instead of adding a standard macOS title bar.
- The pinned floating window is moved by dragging the top header area, excluding interactive controls.
- The anchored popover uses a fixed content size. Detached and pinned windows can be resized.
- Detached and pinned windows share one saved window frame, including size and position. The saved frame does not affect the anchored popover size.
- Detached and pinned windows have a minimum size of 360 by 320 points. They do not have an app-defined maximum size.
- Detached and pinned windows use native macOS edge and corner resizing. The app should not add a custom resize handle or explanatory resize UI.
- When detached or pinned windows are resized, extra height should primarily go to the scratchpad editor. The Clip Shelf keeps its capped height and scroll behavior.
- Unpinning returns to the fixed-size anchored popover. Saved detached or pinned window size is not applied to the anchored popover.
- The menu bar recovery action should be named `Reset Window Size and Location` and should restore the saved detached or pinned window frame to the default size and position below the menu bar item.
- The reset action is available whenever a saved window frame exists or a detached or pinned window is currently open.
- Resizing or moving a detached window immediately updates the shared saved window frame, even before the user pins it.
- The persisted frame field should be named `windowFrame`, not `floatingFrame`, because it belongs to both detached and pinned windows. Do not preserve or migrate the old `floatingFrame` key.
- While visible, the pinned floating window stays above normal application windows.
- The pinned floating window does not dismiss when the user clicks outside it or presses Escape.
- Closing the pinned floating window hides it while keeping pinned mode active. Only the pin control changes pinned/unpinned mode.
- The footer shows line, word, character, and last-updated metadata.
- Scratchpad text and clips persist as JSON in Application Support.

## Language

**Paper finish**:
A subtle matte texture applied to the editable scratchpad editor surface and top bar, controlled by a Settings toggle.
_Avoid_: applying paper texture to the footer, settings, clip shelf, or other app chrome.

**Paper Finish setting**:
A persisted Settings preference that defaults on and controls whether the editable scratchpad editor surface and top bar use the paper finish. In Settings, it appears directly under Appearance, titled `Paper Finish`, with the description `Add a subtle matte texture to the note.`
When off, the editor uses the native text view background.
_Avoid_: temporary per-window state, intensity controls, texture style choices, or a second custom flat editor theme.

**Custom Note Background**:
A user-selected image applied only as an aesthetic background for the editable scratchpad surface.
_Avoid_: treating the image as note content, copying it with Copy All, exporting it, capturing it from the clipboard, or making it part of the text model.

**Custom Note Background import**:
Choosing a custom note background imports a local copy into Clipboard Scratchpad's Application Support data.
_Avoid_: linking to the original selected file, depending on Downloads or external folders, cloud-only references, or storing raw image data inside the main scratchpad JSON.

**Custom Note Background display**:
A custom note background fills the editable scratchpad surface with centered aspect-fill cropping as the note resizes.
_Avoid_: stretching, tiling, letterboxing, or adding fit-mode controls before there is a clear user need.

**Custom Note Background readability**:
A custom note background always has an automatic fixed readability overlay between the image and note text.
_Avoid_: relying on users to choose quiet images, adding opacity sliders, or adding image-editing controls in v1.

**Custom Note Background and Paper Finish**:
Custom Note Background and Paper Finish are mutually exclusive note surface treatments.
When Paper Finish is enabled, it visually takes precedence without removing the selected custom note background from Settings.
_Avoid_: layering paper grain over the custom image, duplicating the image in the top bar, deleting the selected image when Paper Finish is enabled, or showing both treatments as active at the same time.

**Custom Note Background scope**:
Custom note background applies to the editable scratchpad surface and top bar, matching the paper finish scope.
_Avoid_: extending the custom image into the footer, Settings, Clip Shelf, split divider, or other app chrome.

**Custom Note Background setting**:
The custom note background is managed from Settings under Paper Finish with choose, change, and remove controls.
_Avoid_: putting background controls in the main note toolbar or adding frequent-action affordances for a rarely changed personalization setting.

**Custom Note Background media**:
Custom note backgrounds accept common static image files only, such as PNG, JPEG, HEIC, and TIFF.
_Avoid_: animated backgrounds, PDFs, SVGs, videos, folders, or live wallpaper behavior.

**Custom Note Background asset**:
Imported custom note backgrounds are normalized into a reasonably sized app-owned static image asset for display.
_Avoid_: storing full-resolution originals, preserving animation, repeatedly decoding very large source images, or placing image data in the scratchpad text state.

**Dark paper finish**:
The dark-mode version of paper finish, using a warm charcoal editor surface with very low-contrast grain.
_Avoid_: beige paper in dark mode, bright speckles, or a texture so strong that it reads as visual noise.

**Paper finish scope**:
Paper finish changes the editor background surface and top bar background, including when the editor appears above the Clip Shelf drawer, not text styling or editing behavior.
_Avoid_: extending paper finish into the footer, Clip Shelf, split divider, custom fonts, custom selection colors, cursor changes, line-spacing changes, or undo/text-input changes for the paper finish.

## Current Non-Goals

- No iOS or cross-platform version.
- No cloud sync or accounts.
- No folders, tags, or long-term clipboard history.
- No image, file, or rich media capture.
- No AI features.
- No external dependencies unless explicitly approved.
- No Core Data.

## Important Product Decisions

- Current v1 is not a block-based document editor. Captured clips live in a shelf and become plain text when inserted.
- Because a pinned note can make the clip destination ambiguous, plain clip clicks open an explicit action menu instead of inserting directly.
- Left-clicking anywhere on a clip row opens the clip action menu. Right-clicking anywhere on a clip row opens the same menu. The trailing actions button is a discoverability affordance for the same menu.
- Clip Shelf rows do not have persistent selection. Hover and click states are transient action affordances only.
- The paste-to-previous-app action is available whenever clips are shown, not only when the popover is pinned. If no previous external app is known, the action should fall back to copying the clip.
- If no previous external app is known, the paste-to-previous-app action is disabled in the clip action menu.
- If Accessibility permission is unavailable, paste-to-previous-app should copy the clip and show `Copied` until permission is granted.
- If the previous external app is gone or cannot be activated, paste-to-previous-app should copy the clip and show `Copied`.
- Delete entry removes a single clip immediately without confirmation and persists the shelf.
- Paste-to-previous-app uses the system pasteboard as transport, marks the write as app-owned so it is not recaptured, focuses the previous external app, and sends Cmd+V. The clip remains on the system clipboard afterward.
- The scratchpad itself is plain text. Preserve normal text editing behavior and undo expectations.
- The Clip Shelf drawer/header/footer can stay SwiftUI, but the row area should use native AppKit list behavior for stable rows, full-row context menus, trailing actions, and predictable hit testing.
- Captured clipboard data should remain local.
- Capture behavior should feel obvious and controllable before the app is treated as launch-ready.

## Known Gaps And Open Decisions

- Capture currently starts automatically on launch. Decide whether v1 should add explicit start/pause control before shipping.
- Settings button opens a small settings surface.
- Accessibility permission should be requested during onboarding, with a later in-app path to allow or repair it if the user skips onboarding or denies permission.
- The settings surface is the recovery path for Accessibility permission after onboarding, including permission status and an action to enable or repair access.
- Global hotkey is not implemented.
- Launch at login is not implemented.
- Excluded apps and clear-on-quit privacy controls are not implemented.
- Markdown export is not implemented.
- Per-clip actions such as delete one clip or copy one clip are not implemented.
- Decide whether `PRD.md` should be archived, trimmed, or rewritten now that the app has evolved.

## Architecture Notes

- Build system is Swift Package Manager only.
- Main source lives in `Sources/ClipboardScratchpad/`.
- `AppDelegate` owns app lifecycle and the shared `ScratchpadStore`.
- `StatusBarController` owns the menu bar item and popover.
- `ContentView` owns the main SwiftUI layout.
- `PlainTextView` bridges SwiftUI to `NSTextView`.
- `ScratchpadStore` owns scratchpad state, clip state, persistence, and clipboard monitor wiring.
- `ClipboardMonitor` polls `NSPasteboard` on the main thread.
- `StoreState` is the current persisted Codable shape.
- Paper finish should use a small deterministic in-process texture generator with a fixed seed. Cache one fixed pixel-size tiled bitmap per light/dark appearance; do not regenerate texture for window size or display scale. Do not add bundled texture assets or external dependencies for it.

## Persistence

Persist app data as JSON under:

```text
~/Library/Application Support/ClipboardScratchpad/store.json
```

The current stored state includes:

- `noteText`
- `updatedAt`
- `clips`

Legacy block-shaped state can be migrated into plain text and backed up to:

```text
~/Library/Application Support/ClipboardScratchpad/store.blocks.backup.json
```

## Working Rules

- Prefer small, direct changes over abstractions.
- Keep UI copy minimal and avoid meta commentary inside the app.
- Preserve local-first behavior.
- Avoid background-thread pasteboard access.
- Use `swift build` for build verification and `swift run` for manual testing.
