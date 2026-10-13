# SpaceLens architecture

## Overview

SpaceLens is a native macOS application built with Swift, SwiftUI, AppKit, Foundation, CryptoKit, and Quick Look. Rust is deferred until measurement identifies a meaningful bottleneck or a cross-platform engine becomes a real requirement.

The distributable application is defined by `SpaceLens/SpaceLens.xcodeproj`. `Package.swift` covers the same source and test directories for fast command-line validation. The project has no third-party runtime dependencies.

## Boundaries

The source is feature-oriented with a small shared core:

- `App/` owns scene setup and high-level session state.
- `Core/FileSystem/` owns authorized scans and Trash operations.
- `Core/Duplicates/` owns exact duplicate discovery and hashing.
- `Core/Classification/` owns file categories and deletion guidance.
- `Core/Models/`, `Preview/`, and `Visualization/` contain shared behavior.
- `Features/` contains SwiftUI presentation for scanning, results, and duplicates.

Filesystem access, classification, safety assessment, duplicate hashing, and Trash operations remain outside views so they can be tested independently.

## State flow

    Folder picker → scan setup → authorized scope + session exclusions
                                      ↓
                         scanner / duplicate finder
                                      ↓
                             asynchronous events
                                      ↓
                             AppModel → views
                                      ↓
                        selection → confirmed Trash request

`AppModel` owns navigation and session state. Scan snapshots, duplicate groups, exclusions, and caches are not persisted.

## Storage scanning

`DirectoryScanner` is actor-isolated and exposes an `AsyncThrowingStream`. It recursively aggregates logical and allocated sizes into each immediate child of the displayed folder. It supports cancellation, skips session exclusions before traversal, avoids symbolic links and other filesystems, records inaccessible entries, and throttles progress updates.

## Duplicate detection

`DuplicateFinder` performs a separate read-only pass over the authorized root:

1. Skip hidden entries, packages, symbolic links, exclusions, and other filesystems.
2. Ignore empty files and collapse hard links sharing one filesystem identity.
3. Group regular files by logical size.
4. Stream candidate contents through CryptoKit SHA-256 in bounded chunks.
5. Revalidate size and modification date before accepting a digest.
6. Report groups with at least two matching hashes.

Savings are described as potential because compression and APFS clones can affect the actual reclaimed space.

## Classification and safety

Classification describes what an item appears to be. `SafetyAssessment` separately controls what SpaceLens may say about removal. A category never automatically makes a file safe.

Guidance is conservative:

- **Known reproducible** for specifically recognized caches or build output
- **Review carefully** for user content, downloads, archives, applications, and duplicates
- **Protected or unknown** for system locations, sensitive configuration, links, incomplete scans, and unknown locations

## Trash operations

`TrashService` wraps the supported macOS Trash API. Immediately before moving an item it verifies the authorized scope, filesystem identity, scan completeness, and safety policy. SpaceLens never permanently deletes files or empties Trash.

## Persistence and permissions

- The app uses the App Sandbox with user-selected file read/write access.
- It does not request Full Disk Access.
- Security-scoped bookmark persistence is not implemented.
- No scan data, paths, analytics, or file contents are sent over a network.

## Validation

Tests use temporary fixtures rather than personal data. Coverage includes aggregation, cancellation, links, filesystem boundaries, exclusions, duplicate hashes, hard links, classification, identity revalidation, and Trash behavior.
