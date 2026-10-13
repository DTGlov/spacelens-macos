# SpaceLens

[![CI](https://github.com/DTGlov/spacelens-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/DTGlov/spacelens-macos/actions/workflows/ci.yml)
![Status](https://img.shields.io/badge/status-pre--release-orange)
![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

SpaceLens is a native macOS storage explorer that turns crowded folders into a clear visual map, highlights unusually large or older files, and finds exact duplicates without uploading file data.

> [!IMPORTANT]
> SpaceLens is pre-release software. There is no signed public download yet. Build it from source for testing and keep backups of important data.

## Why SpaceLens?

macOS can report that storage is full without making it easy to understand which folders are responsible. SpaceLens is designed around three questions:

1. What is consuming my storage?
2. Where is it located?
3. What should I review before reclaiming space?

SpaceLens gives context rather than declaring unfamiliar files to be junk.

## Features

- Scan a folder selected through the native macOS folder picker.
- Exclude chosen subfolders for the current scan session.
- Explore allocated space through an interactive treemap and sortable table.
- Navigate folders with breadcrumbs, search, and size/type filters.
- Highlight files of at least 1 GB and files not modified within one year.
- Find exact duplicates by grouping on size and confirming content with SHA-256.
- Preview supported files with Quick Look or reveal them in Finder.
- Show conservative, explainable deletion guidance.
- Move one explicitly selected item to Trash after identity and scope revalidation.
- Cancel active storage and duplicate scans.
- Continue past individual unreadable entries without aborting the entire scan.

## Safety and privacy

- Scans remain on the Mac; SpaceLens has no networking or analytics dependency.
- Only explicitly selected locations are scanned.
- Symbolic links are not followed and scans do not cross filesystem boundaries.
- Excluded folders are not traversed or checked for duplicates.
- Duplicate scanning ignores package contents, empty files, and hard links.
- Unknown files are never labeled as junk or automatically selected.
- SpaceLens never cleans automatically or permanently deletes files.
- Files move through the supported macOS Trash API only after explicit confirmation.
- Identity and authorized scope are revalidated immediately before a Trash operation.

Read [PRODUCT.md](PRODUCT.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [SECURITY.md](SECURITY.md) for the complete policies.

## Project status

SpaceLens is under active development and has not reached its first tagged release. Source builds are intended for contributors and early testers. Signing, notarization, and a downloadable disk image are planned after an Apple Developer account is available.

## Requirements

- macOS 14 or later
- Xcode 26 or a compatible Swift 6.2 toolchain

## Build from source

Clone the repository, open `SpaceLens/SpaceLens.xcodeproj`, select the `SpaceLens` scheme and `My Mac` destination, then press Run.

Run package tests with `swift test`.

Build the native application without signing with:

    xcodebuild build \
      -project SpaceLens/SpaceLens.xcodeproj \
      -scheme SpaceLens \
      -destination 'platform=macOS' \
      CODE_SIGNING_ALLOWED=NO

If you receive an unsigned build from a trusted contributor, read [Running unsigned builds](docs/UNSIGNED_BUILDS.md) before opening it.

## Roadmap

- [x] Native sandboxed macOS application
- [x] Interactive storage map, navigation, search, and filters
- [x] Quick Look and explainable safety classifications
- [x] Confirmed Move to Trash workflow
- [x] Large/older file insights and exact duplicate detection
- [x] Per-session scan exclusions
- [x] Accessibility and scanner performance refinement
- [x] Open-source community and contribution documentation
- [ ] Signed, notarized release builds and downloadable disk image

The roadmap is directional rather than a promise of dates. Proposed changes must preserve SpaceLens's conservative safety model.

## Contributing

Contributions, reproducible bug reports, design feedback, accessibility improvements, and documentation fixes are welcome.

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md) in project spaces.
- Use GitHub's issue forms for bugs and feature proposals.
- Report security-sensitive issues privately as described in [SECURITY.md](SECURITY.md).

## License

SpaceLens is available under the [MIT License](LICENSE).
