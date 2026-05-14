# Generate Deterministic Light And Dark Paper Textures

Status: needs-triage

## Parent

.scratch/paper-finish/PRD.md

## What to build

Add the deterministic fractal texture generation used by Paper Finish, with fixed-seed light and dark paper variants cached as fixed-size tiled bitmaps.

## Acceptance criteria

- [ ] Paper texture is generated in-process using deterministic fractal noise.
- [ ] Texture output uses a fixed seed and is stable across launches.
- [ ] Light appearance uses a warm off-white paper surface with subtle grain.
- [ ] Dark appearance uses restrained warm charcoal paper with lower-contrast grain and no bright speckles.
- [ ] One fixed pixel-size tile is cached for light appearance and one for dark appearance.
- [ ] Texture generation is not repeated for window size, resize events, scroll events, or display scale.
- [ ] The implementation adds no bundled image assets and no external dependencies.
- [ ] Focused tests cover determinism, light/dark distinction, and bounded contrast where practical.

## Blocked by

- .scratch/paper-finish/issues/03-render-paper-finish-in-the-editor-surface.md
