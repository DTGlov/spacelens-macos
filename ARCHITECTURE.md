# SpaceLens architecture

## Decision

Version one is a native macOS application built with Swift and SwiftUI. Filesystem scanning uses Foundation APIs with bounded concurrency. Rust is intentionally deferred until measurement demonstrates a meaningful bottleneck or a reusable cross-platform engine becomes a product requirement.

The distributable application is defined by `SpaceLens/SpaceLens.xcodeproj`. The repository also keeps a Swift package manifest over the same source and unit-test directories for fast command-line validation; it is not a second implementation.

The application uses a feature-oriented structure with a small shared core. It separates filesystem operations from presentation so scanning and safety decisions can be tested without launching the interface.

## Proposed structure

```text
SpaceLens/
├── App/
│   ├── SpaceLensApp.swift
│   └── AppModel.swift
├── Core/
│   ├── FileSystem/
│   ├── Models/
│   └── Utilities/
├── Features/
│   ├── Welcome/
│   ├── Scanning/
│   ├── Results/
│   ├── Inspector/
│   └── Cleanup/
├── Resources/
└── Tests/
    ├── ScannerTests/
    ├── ClassificationTests/
    └── SafetyTests/
```

Files should be added only when the vertical slice needs them; this tree is a boundary map, not a request to create empty placeholders.

## State flow

```text
Folder authorization
        ↓
Scan coordinator ─────→ progress events
        ↓                       ↓
Immutable scan snapshot → app model → SwiftUI views
        ↓
Selection → inspector → explicit Trash request
```

### App model

The app model owns navigation and high-level session state: selected root, scan status, current snapshot, selection, filters, and presented dialogs. It does not enumerate files or make safety decisions.

### Scan coordinator

The coordinator starts and cancels scan tasks, limits filesystem concurrency, aggregates partial results, and publishes throttled snapshots. Throttling prevents filesystem events from causing excessive UI redraws.

### Filesystem scanner

The scanner is an `actor`-isolated service with an asynchronous event stream. It reads resource keys in batches, avoids symbolic-link traversal, records inaccessible entries, and supports cooperative cancellation.

Each node records at least:

- Stable scan-session identifier
- URL relative to the authorized root
- Display name and kind
- Logical and allocated size when available
- Modification date
- Child aggregate information
- Scan completeness and access errors

The scanner must not retain file contents.

### Classification and safety

Classification describes what an item appears to be. Safety assessment separately determines what SpaceLens may say about removal. Keeping them separate prevents a category such as “cache” from automatically becoming “safe.”

Safety explanations are rule-based and testable. The first release should use a conservative allowlist for known reproducible items and label everything else for review or as unknown.

### Trash service

Deletion is represented by a dedicated service wrapping the macOS trash API. Before acting, it verifies that the URL still refers to the item inspected by the user and remains within the authorized scope. It returns an auditable result for every requested item.

## Persistence

Version one needs little persistence:

- Security-scoped bookmarks for explicitly authorized recent locations
- Lightweight preferences such as view mode and category visibility
- Cleanup-history metadata

Scan trees are session data and are not persisted initially. SwiftData or a database is unnecessary for the first vertical slice.

## Dependencies

No third-party dependencies are proposed initially.

- SwiftUI and AppKit: application interface and macOS integrations
- Foundation: enumeration, resource metadata, concurrency, and bookmarks
- QuickLookUI: previews
- XCTest: focused scanner, classification, and safety tests

A custom treemap can be drawn with SwiftUI `Canvas` after the list-based slice works. This avoids committing to a chart package before interaction and accessibility requirements are understood.

## macOS configuration

- Target the oldest macOS version that supports the chosen SwiftUI APIs; decide this when creating the Xcode project against the installed toolchain.
- Enable App Sandbox.
- Grant user-selected file read/write access.
- Use security-scoped bookmarks for authorized recent locations.
- Do not request Full Disk Access for the first release.
- Add clear usage copy wherever protected-folder access may be requested.

## First vertical slice

The first implementation milestone is intentionally narrow:

1. Create the SwiftUI macOS application target.
2. Choose one folder through the native picker.
3. Scan it asynchronously with cancellation and permission-error reporting.
4. Display the 100 largest immediate descendants in a sortable native table.
5. Select an item and reveal it in Finder.
6. Cover aggregation, cancellation, symlink handling, and inaccessible-item behavior with focused tests.

Moving to Trash and the treemap follow only after this slice is reliable. That keeps destructive behavior out of the earliest prototype and gives real scan data for designing the visualization.
