# Changelog

All notable changes to Frame Smith appear in this file.
The version scheme is Semantic Versioning.

## 0.2.0 - 2026-08-02

### Added

- Undo and redo for filter chain edits.
- Press Ctrl+Z to undo the last edit.
- Press Ctrl+Shift+Z to redo the undone edit.
- The header bar shows Undo and Redo buttons.
- The undo history stores chain snapshots.
- A deterministic test suite covers the undo history.

### Changed

- The project version is now 0.2.0.

### Fixed

- None in this release.

## 0.1.0 - 2026-08-02

### Added

- Initial release.
- Open common image formats through GdkPixbuf.
- Blur, sharpen, edge detect, threshold, and levels filters.
- Filter chain editing and reordering.
- A per-channel histogram view.
- Save the result as PNG, JPEG, BMP, or TIFF.
- A deterministic sample image and its generator script.
