# Domain Docs

How engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- `CONTEXT.md` at the repo root
- `docs/adr/` for architectural decisions that touch the area being changed

If these files do not exist, proceed silently. Do not flag their absence or suggest creating them upfront.

## Layout

This repo uses a single-context layout:

```text
/
├── CONTEXT.md
├── docs/adr/
└── Sources/
```

## Use project vocabulary

When output names a domain concept in an issue title, refactor proposal, hypothesis, or test name, use terms from `CONTEXT.md` when available.

If the needed concept is missing from `CONTEXT.md`, note the gap only when it affects the work.

## Flag ADR conflicts

If output contradicts an existing ADR, surface it explicitly rather than silently overriding it.
