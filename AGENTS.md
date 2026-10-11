# SpaceLens engineering guide

## Product boundaries

- SpaceLens is a native macOS storage explorer built with Swift and SwiftUI.
- Preserve user trust: no automatic cleanup, permanent deletion, or unsubstantiated “safe” labels.
- The first release scans only locations the user explicitly authorizes.
- Windows support and Rust integration are out of scope until product evidence changes that decision.

## Architecture

- Keep filesystem access, classification, safety assessment, and Trash operations outside SwiftUI views.
- Use feature-oriented folders and create abstractions only when required by implemented behavior.
- Keep classification separate from deletion-safety assessment.
- Treat scan snapshots as session data; do not add persistence without a concrete need.
- Prefer Apple frameworks before third-party dependencies.

## Filesystem safety

- Do not follow symbolic links during recursive scans.
- Keep scans within the explicitly authorized root and filesystem boundary.
- Handle inaccessible entries as data; do not fail the entire scan.
- Support cooperative cancellation.
- Revalidate an item's identity, path, and authorized scope immediately before a Trash operation.
- Move to Trash through supported macOS APIs; never permanently delete.

## UI quality

- Use native macOS interaction conventions and keyboard shortcuts.
- Support dark mode, VoiceOver, increased contrast, and Reduce Motion.
- Never rely on color alone to convey file category or safety.
- Keep the interface responsive and throttle scan-driven view updates.

## Validation

- Add focused tests for size aggregation, cancellation, symlink behavior, permission failures, classification, and safety rules.
- Use temporary fixture directories in tests; never test deletion against personal files.
- Run targeted tests and build the macOS target after relevant changes.
- Review project changes before finishing and avoid generated-file churn.
