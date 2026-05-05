# AGENTS.md — Clipboard Scratchpad

## Principles

- Prefer simple, maintainable, production-friendly solutions. Low complexity, easy to read, debug, and modify.
- No heavy abstractions, extra layers, or large dependencies for small features.
- Keep APIs small, behavior explicit, and naming clear. Avoid cleverness.
- Do not add explanatory copy or meta commentary within the app UI.

## Project Conventions

- **Build system:** Swift Package Manager only. No Xcode project files. Run with `swift run`, build with `swift build`.
- **Platform:** macOS 14+. No iOS or cross-platform code.
- **UI:** AppKit shell (menu bar, popover) + SwiftUI content views. No pure AppKit UI unless necessary.
- **Data model:** Use the `ScratchBlock` enum. No protocol existentials, no separate stored/serialization types.
- **Dependencies:** None. Do not add external packages without explicit user approval.
- **Persistence:** JSON via `Codable` to `~/Library/Application Support/ClipboardScratchpad/`. No Core Data, no UserDefaults for block data.
- **Clipboard:** Poll `NSPasteboard.changeCount` on main thread. Never background-thread pasteboard access.
- **Testing:** No unit test target yet. Manual testing via `swift run`.
- **Git:** Commit frequently. Keep `.build/` out of the repo (already in `.gitignore`).

## Code Style

- Swift standard style. Explicit types over inference at module boundaries.
- `private`/`fileprivate` by default, expand access only when needed.
- Prefer value types (structs, enums) over classes where possible.

## Agent skills

### Issue tracker

Issues are tracked as local markdown under `.scratch/<feature-slug>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Triage labels use the default five-role vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

This repo uses a single-context domain-doc layout. See `docs/agents/domain.md`.
