# PRD: Clipboard Scratchpad

> Note: this PRD is an early planning document and is no longer fully aligned with the current app. For current product and implementation context, read `CONTEXT.md` first.

## 1. Product overview

### 1.1 Document title and version

- PRD: Clipboard Scratchpad
- Version: 0.1

### 1.2 Product summary

This project is a small macOS menu bar app that collects copied text into one editable scratchpad. The user can start a capture session, copy text from other apps, and see each copied item appear as a visually distinct block inside the note.

The app also works as a normal scratchpad. Users can type around captured blocks, edit captured text, delete items, copy the full note, and clear the workspace when done.

The v1 product should stay local-first, lightweight, and single-purpose. It should not become a full clipboard manager, notes system, research database, or AI writing tool.

## 2. Goals

### 2.1 Business goals

- Validate demand for a focused macOS utility that solves temporary text collection.
- Ship a small paid or freemium utility with a clear, demo-friendly workflow.
- Build a product surface that can later support export, formatting cleanup, and privacy-focused paid features.
- Keep the v1 scope small enough to build, test, and launch quickly.

### 2.2 User goals

- Collect copied text from multiple apps without switching constantly to a notes app.
- Keep copied snippets and manual notes in one temporary workspace.
- Pause clipboard capture when it is not needed.
- Remove sensitive, duplicate, or irrelevant copied text quickly.
- Copy or export the final scratchpad as clean text.

### 2.3 Non-goals

- Do not build a full clipboard history app.
- Do not store clipboard history forever.
- Do not add folders, tags, accounts, teams, or cloud sync in v1.
- Do not add AI summarization in v1.
- Do not require a browser extension.
- Do not capture images, files, or rich media in v1.
- Do not create a complex document editor.

## 3. User personas

### 3.1 Key user types

- Writers and researchers collecting snippets from web pages and documents.
- Founders, operators, and marketers gathering copy, links, and notes for small work tasks.
- Developers collecting temporary commands, logs, error text, and documentation snippets.
- Students collecting quotes and notes from PDFs, web pages, and lecture materials.

### 3.2 Basic persona details

- **Research-heavy worker**: Collects useful text from browsers, PDFs, documents, and chat apps while preparing a deliverable.
- **Fast-moving operator**: Needs a temporary workspace for client notes, sales copy, support replies, and admin details.
- **Developer**: Copies commands, stack traces, snippets, and documentation while debugging or planning work.
- **Student**: Collects source text and rough notes before turning them into an assignment or study summary.

### 3.3 Role-based access

- **Local user**: Can start and pause capture, view the scratchpad, type notes, edit blocks, delete blocks, copy content, clear content, and change local preferences.
- **No authenticated user**: Authentication is not required in v1 because all data stays local.
- **No admin role**: Admin permissions are not needed in v1.

## 4. Functional requirements

- **Menu bar app shell** (Priority: High)
  - Show a persistent menu bar icon while the app is running.
  - Open the scratchpad popover or window when the user clicks the icon.
  - Provide menu actions for start capture, pause capture, copy all, clear all, settings, and quit.
  - Support launch at login as an optional setting.

- **Global hotkey** (Priority: High)
  - Let the user open or hide the scratchpad with a configurable global hotkey.
  - Provide a default hotkey that avoids common macOS conflicts where possible.
  - Show an error if the selected hotkey cannot be registered.

- **Capture session control** (Priority: High)
  - Default to capture paused on first launch.
  - Let the user start and pause capture from the scratchpad and menu bar menu.
  - Show capture state clearly without adding explanatory in-app copy.
  - Stop capture when the app quits.

- **Text clipboard capture** (Priority: High)
  - Detect copied plain text while capture is active.
  - Append each new copied text item as a captured block.
  - Store source app name and capture time when macOS makes them available.
  - Ignore non-text clipboard content in v1.
  - Avoid adding the same copied text twice in a row.

- **Editable scratchpad** (Priority: High)
  - Let users type manual notes in the same workspace as captured blocks.
  - Keep captured blocks visually distinct from manual text.
  - Let users edit captured block text after insertion.
  - Preserve scratchpad content between app launches unless the user clears it.

- **Block actions** (Priority: High)
  - Let users delete individual captured blocks.
  - Let users copy one captured block.
  - Let users convert a captured block into normal manual text.
  - Confirm destructive clear-all actions if content exists.

- **Copy and export** (Priority: Medium)
  - Let users copy the full scratchpad as clean plain text.
  - Let users export the scratchpad as a Markdown file.
  - Preserve captured block order in copied and exported output.
  - Include source app and timestamp in Markdown export when available.

- **Privacy controls** (Priority: High)
  - Keep all scratchpad content local by default.
  - Provide an excluded apps list so capture can ignore sensitive apps.
  - Include default exclusions for common password managers where app detection is reliable.
  - Provide a setting to clear content on quit.

- **Settings** (Priority: Medium)
  - Let users configure hotkey, launch at login, default capture mode, excluded apps, and clear-on-quit.
  - Keep settings small and explicit.
  - Avoid onboarding flows beyond a first-run permissions and hotkey setup.

- **Error states and permissions** (Priority: High)
  - Explain when clipboard monitoring or accessibility-related capabilities are unavailable.
  - Provide a direct path to the required macOS settings if permissions are needed.
  - Keep the app usable as a manual scratchpad if capture is unavailable.

## 5. User experience

### 5.1. Entry points & first-time user flow

- The user launches the app and sees a menu bar icon.
- The user clicks the icon and sees an empty scratchpad.
- The app asks only for permissions required to support capture and hotkeys.
- The user can set or accept the default hotkey.
- Capture starts only after the user clicks start capture.
- The first copied text item appears as a captured block in the scratchpad.

### 5.2. Core experience

- **Open the scratchpad**: The user clicks the menu bar icon or presses the global hotkey.
  - The scratchpad opens quickly and shows current content without a loading state.

- **Start collecting**: The user turns capture on for the current work session.
  - The capture state is visible through a compact control and icon state.

- **Copy text from other apps**: The user copies useful text from Safari, Preview, Notes, Slack, Terminal, or other apps.
  - Each text item appears as a distinct block with source and time when available.

- **Type around captured text**: The user adds manual notes before, between, or after captured blocks.
  - Manual text and captured blocks feel like one document, not two separate tools.

- **Clean up the workspace**: The user edits, deletes, or copies individual blocks.
  - Common actions are available without opening settings.

- **Use the final note**: The user copies all content or exports it as Markdown.
  - Output is readable, ordered, and free of hidden formatting.

- **Reset when done**: The user clears the scratchpad or leaves it for later.
  - Clear all requires confirmation when content exists.

### 5.3. Advanced features & edge cases

- If the user copies the same text twice in a row, the app does not add a duplicate.
- If capture is paused, clipboard changes do not appear in the scratchpad.
- If copied text is very large, the app stores it but collapses the block preview.
- If source app detection fails, the block shows time without a source app.
- If permissions are missing, the app still supports manual typing.
- If a password manager or excluded app is active, copied text from that app is ignored where app detection allows it.
- If the app crashes or quits, existing scratchpad content is restored on next launch unless clear-on-quit is enabled.

### 5.4. UI/UX highlights

- One compact scratchpad surface, not a multi-panel clipboard manager.
- Captured blocks have subtle metadata and controls.
- Manual notes stay plain and editable.
- Capture state is always visible.
- Destructive actions are hard to trigger by accident.
- The app avoids instructional copy inside the main UI.
- The app feels native, fast, and quiet.

## 6. Narrative

Maya is a freelance marketer preparing copy for a client landing page. She finds useful phrases in the client site, competitor pages, old notes, and Slack messages, but she does not want to keep switching into a full notes app. She opens this tool from the menu bar, starts collecting, copies useful text as she works, and adds her own notes between captured blocks. When she has enough material, she pauses capture, deletes the noise, copies the full scratchpad, and pastes a clean draft into her writing app.

## 7. Success metrics

### 7.1. User-centric metrics

- At least 60% of first-run users complete one capture session within 10 minutes of launch.
- At least 40% of active users use both auto-capture and manual typing in the same session.
- Median time from menu bar click to scratchpad visible is under 300 ms on supported devices.
- Fewer than 5% of sessions include an accidental clear-all event, measured by clear confirmation cancellation and undo usage if implemented.
- At least 30% of weekly active users use copy all or export.

### 7.2. Business metrics

- Validate willingness to pay through a landing page, waitlist, or beta purchase test before a larger build.
- Target a 20% or higher trial-to-repeat-use rate during beta, measured as users with sessions on at least 3 separate days.
- Target a 5% or higher visitor-to-download conversion rate on the initial landing page.
- UNVERIFIED: Pricing should be tested. How to verify: run a landing page or small beta with one-time purchase and freemium variants.

### 7.3. Technical metrics

- Clipboard polling or observation does not raise idle CPU usage above 2% on a typical supported Mac.
- App memory usage remains under 150 MB during normal text-only use.
- App restores scratchpad state after relaunch with no data loss in standard quit and restart flows.
- Capture latency from copy action to displayed block is under 500 ms for normal text snippets.
- Crash-free session rate is at least 99% during beta.

## 8. Technical considerations

### 8.1. Integration points

- macOS menu bar APIs for persistent status item behavior.
- macOS pasteboard APIs for text clipboard changes.
- Global hotkey registration.
- Local app storage for scratchpad content and preferences.
- macOS login item support for launch at login.
- Optional macOS accessibility or automation APIs if needed for source app detection.

### 8.2. Data storage & privacy

- Store scratchpad content locally on the user's Mac.
- Do not sync content to cloud services in v1.
- Do not require user accounts in v1.
- Do not collect captured clipboard content in analytics.
- Store preferences separately from note content.
- Make clear-on-quit available for users who handle sensitive text.
- Maintain an excluded apps list for sensitive apps.
- UNVERIFIED: Exact technical limits of detecting copied content source per app. How to verify: prototype source app detection across Safari, Chrome, Preview, Notes, Terminal, Slack, 1Password, and Keychain Access.

### 8.3. Scalability & performance

- Optimize for local text storage, not multi-device scale.
- Set practical limits for very large captured text blocks to keep the UI responsive.
- Use incremental updates so new clipboard items do not re-render the full note unnecessarily.
- Keep the app lightweight enough to run all day from the menu bar.
- Avoid heavy dependencies unless they directly reduce implementation risk.

### 8.4. Potential challenges

- macOS permission prompts may make first-run setup feel heavier than the product promise.
- Clipboard capture can feel invasive if capture state and privacy controls are unclear.
- Source app detection may be unreliable across all apps.
- Users may expect rich formatting if copied content originally includes links or styles.
- Capturing sensitive text accidentally is the main trust risk.
- The product could drift into a full clipboard manager if scope is not controlled.
- App Store review may scrutinize clipboard monitoring behavior. UNVERIFIED: review risk should be checked against current Apple App Review Guidelines before submission.

### 8.5 Tech stack

**Language:** Swift

**UI framework:** SwiftUI, with AppKit integrations where needed.

**Native APIs:** AppKit for clipboard (`NSPasteboard`), menu bar (`MenuBarExtra`), window (`NSWindow`), and file storage (`FileManager`).

**Storage:** Codable JSON in the Application Support directory for scratchpad content. `UserDefaults` for settings.

**Menu bar:** `SwiftUI.MenuBarExtra` for the status item.

**Hotkeys:** `KeyboardShortcuts` Swift package or a Carbon event hotkey wrapper.

**Updates:** App Store auto-updates. No direct distribution.

**Payments / licensing:**

- **Mac App Store + StoreKit 2 only.** No direct sales or third-party payment processors.

**Analytics / crash reporting:**

- Optional Sentry for crash reporting.
- Optional TelemetryDeck or Plausible-style privacy analytics.
- Keep minimal; avoid invasive analytics because the app watches the clipboard.

**Explicitly avoid for v1:**

- Electron, Tauri, React Native macOS.
- Core Data, iCloud sync.
- Browser extensions.
- AI summaries.
- Complex rich text editing.

---

## 9. Milestones & sequencing

### 9.1. Project estimate

- Small: 2-4 weeks for a native macOS v1 prototype and beta-ready build.

### 9.2. Team size & composition

- Small team: 1-2 total people
  - 1 macOS engineer.
  - 1 product/design owner.
  - Optional QA support for permissions, edge cases, and App Store readiness.

### 9.3. Suggested phases

- **Phase 1**: Prototype capture and scratchpad model (3-5 days)
  - Key deliverables: Menu bar shell, scratchpad window, start/pause capture, append copied text blocks, manual typing.

- **Phase 2**: Build v1 product controls (4-7 days)
  - Key deliverables: Hotkey, block actions, copy all, clear all, local persistence, duplicate prevention.

- **Phase 3**: Add privacy and settings (3-5 days)
  - Key deliverables: Excluded apps, clear-on-quit, launch at login, first-run permission handling, basic settings.

- **Phase 4**: Polish and beta validation (4-8 days)
  - Key deliverables: Markdown export, error states, performance checks, crash testing, beta build, landing page validation plan.

## 10. User stories

### 10.1 Start a capture session

As a research-heavy worker, I want to start clipboard capture only when I need it, so that copied text is collected during focused work sessions without recording everything all day.

Acceptance criteria:

- The user can start capture from the scratchpad.
- The user can start capture from the menu bar menu.
- Capture is paused by default on first launch.
- The UI shows whether capture is active or paused.
- Clipboard text copied before capture starts is not added automatically.

### 10.2 Pause capture

As a local user handling mixed work, I want to pause capture quickly, so that private or irrelevant clipboard changes are not added to my scratchpad.

Acceptance criteria:

- The user can pause capture from the scratchpad.
- The user can pause capture from the menu bar menu.
- New clipboard text is not added while capture is paused.
- Existing scratchpad content remains visible and editable while capture is paused.

### 10.3 Capture copied text as blocks

As a marketer collecting source material, I want copied text to appear as separate blocks, so that I can understand where each snippet starts and ends.

Acceptance criteria:

- Copied plain text appears as a new captured block while capture is active.
- Each captured block includes capture time.
- Each captured block includes source app when available.
- Captured blocks appear in the order they were copied.
- Non-text clipboard content is ignored in v1.

### 10.4 Type manual notes in the same scratchpad

As a student collecting references, I want to type my own notes in the same workspace, so that I can connect copied text with my own thoughts.

Acceptance criteria:

- The user can type manual text before captured blocks.
- The user can type manual text after captured blocks.
- The user can type manual text between captured blocks.
- Manual text remains editable after the app is closed and reopened.
- Manual text is visually distinct from captured block metadata.

### 10.5 Edit captured text

As a developer collecting temporary commands and logs, I want to edit captured blocks, so that I can clean up snippets without moving them to another app.

Acceptance criteria:

- The user can edit the text inside a captured block.
- Editing a captured block does not remove its timestamp metadata.
- Edited block content persists after app relaunch.
- The user can undo normal text edits within the current editing session where platform support allows it.

### 10.6 Delete a captured block

As a local user cleaning up collected material, I want to delete individual captured blocks, so that irrelevant snippets do not clutter the scratchpad.

Acceptance criteria:

- Each captured block has a delete action.
- Deleting one block does not delete manual text or other blocks.
- The block disappears from the scratchpad after deletion.
- Deleted blocks do not appear in copy-all or export output.

### 10.7 Copy one captured block

As a fast-moving operator, I want to copy one captured block, so that I can reuse a snippet without selecting text manually.

Acceptance criteria:

- Each captured block has a copy action.
- Copying a block places that block's text on the clipboard.
- Copying a block does not create a duplicate captured block in the scratchpad.
- The app gives compact feedback that the block was copied.

### 10.8 Copy the full scratchpad

As a writer preparing a draft, I want to copy the full scratchpad as clean text, so that I can paste my collected material into another app.

Acceptance criteria:

- The user can copy all scratchpad content with one action.
- Copied output preserves manual text and captured block order.
- Copied output does not include UI-only labels or buttons.
- Copied output includes captured block text.
- Copy-all works when capture is active and when capture is paused.

### 10.9 Clear the scratchpad

As a local user finishing a task, I want to clear the scratchpad, so that I can start fresh for the next session.

Acceptance criteria:

- The user can clear all scratchpad content.
- The app asks for confirmation before clearing non-empty content.
- Confirming clear removes manual text and captured blocks.
- Cancelling clear leaves all content unchanged.

### 10.10 Restore content after relaunch

As a user who works across several sessions, I want my scratchpad to remain available after relaunch, so that I do not lose temporary work by quitting the app.

Acceptance criteria:

- Manual text persists after the app quits and relaunches.
- Captured blocks persist after the app quits and relaunches.
- Capture state returns to the user's configured default after relaunch.
- If clear-on-quit is enabled, content is removed when the app quits.

### 10.11 Exclude sensitive apps

As a privacy-conscious user, I want to exclude apps from capture, so that copied text from sensitive apps is ignored.

Acceptance criteria:

- The user can add apps to an excluded apps list.
- The user can remove apps from the excluded apps list.
- Clipboard text copied from excluded apps is not added when app detection is available.
- The app includes sensible default exclusions for common password managers where reliable detection is possible.
- The UI does not claim perfect exclusion when source app detection is unavailable.

### 10.12 Configure a global hotkey

As a frequent user, I want to open the scratchpad with a keyboard shortcut, so that I can use it without reaching for the menu bar.

Acceptance criteria:

- The app provides a default global hotkey.
- The user can change the hotkey in settings.
- The app warns the user if the selected hotkey cannot be registered.
- Pressing the active hotkey opens the scratchpad when hidden.
- Pressing the active hotkey hides the scratchpad when visible.

### 10.13 Export as Markdown

As a researcher, I want to export the scratchpad as Markdown, so that I can save or share collected material in a portable format.

Acceptance criteria:

- The user can export current content as a Markdown file.
- Exported content preserves manual text and captured block order.
- Captured block metadata is included when available.
- Export succeeds without requiring an account or network connection.

### 10.14 Use the app without capture permissions

As a user who has not granted permissions, I want to keep using the scratchpad manually, so that the app still provides value if capture is unavailable.

Acceptance criteria:

- The user can type manual notes without granting capture-related permissions.
- The user can copy all manual content without granting capture-related permissions.
- The app shows a clear capture-unavailable state when capture cannot run.
- The app provides a direct path to relevant macOS settings when permission changes are needed.

### 10.15 Launch at login

As a daily user, I want the app to launch when I sign in, so that the scratchpad is always available from the menu bar.

Acceptance criteria:

- The user can enable launch at login in settings.
- The user can disable launch at login in settings.
- The app respects the saved launch-at-login preference after restart.
- Launching at login does not automatically start capture unless the user has configured that behavior.
