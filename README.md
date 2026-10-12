# SpaceLens

SpaceLens is a native macOS storage explorer that helps you understand what is using disk space and where it lives.

The project is currently an early, non-destructive prototype. It can scan a folder you explicitly choose, rank its largest immediate contents, inspect an item, and reveal it in Finder. It does **not** delete, move, upload, or modify your files.

## Why SpaceLens?

macOS can tell you that storage is full without making it easy to understand which folders are responsible. SpaceLens aims to make storage usage visual, understandable, and safe to act on.

The product is guided by three questions:

1. What is consuming my storage?
2. Where is it located?
3. What can I safely remove?

## Current capabilities

- Choose a folder with the native macOS folder picker.
- Scan nested files and folders asynchronously.
- See live discovered size and item-count progress.
- Cancel an active scan.
- Browse the 100 largest immediate items in a sortable table.
- Inspect allocated size, logical size, modification date, and location.
- Reveal a selected item in Finder.
- Continue when individual locations cannot be read.
- Avoid traversing symbolic links or crossing filesystem boundaries.

## Safety principles

Storage tools operate close to irreplaceable personal data, so safety is part of the architecture rather than a finishing touch.

- SpaceLens scans only locations the user explicitly chooses.
- It never follows symbolic links during recursive scans.
- It does not call an unknown file “junk.”
- Automatic cleanup and permanent deletion are out of scope.
- Future removal features will move explicitly selected items to Trash only after confirmation.
- Filesystem behavior is covered by focused tests using temporary fixtures, never personal files.

For the complete product and engineering decisions, see [PRODUCT.md](PRODUCT.md) and [ARCHITECTURE.md](ARCHITECTURE.md).

## Requirements

- macOS 14 or later
- Xcode 26 or a compatible Swift 6.2 toolchain

## Run locally

Clone the repository and enter its directory:

```sh
git clone https://github.com/DTGlov/spacelens-macos.git
cd spacelens-macos
```

Open the native Xcode project:

```sh
open SpaceLens/SpaceLens.xcodeproj
```

Select the `SpaceLens` scheme and the `My Mac` destination, then press Run.

Build and run the complete Xcode test suite from the command line:

```sh
xcodebuild test -project SpaceLens/SpaceLens.xcodeproj -scheme SpaceLens -destination 'platform=macOS'
```

The Swift package remains available for quick scanner tests and command-line development:

```sh
swift test
swift run SpaceLens
```

## Roadmap

- [x] Standard sandboxed macOS `.app` target
- [x] Interactive storage treemap
- [x] Folder navigation, filtering, and search
- [x] Quick Look previews
- [x] Conservative, explainable safety classifications
- [x] Confirmed Move to Trash workflow
- [x] Accessibility and performance refinement
- [x] Large and older file insights
- [ ] Signed release builds

The roadmap is directional rather than a promise of specific release dates. Proposed changes should preserve SpaceLens's conservative safety model.

## Contributing

Contributions, bug reports, design feedback, accessibility improvements, and documentation fixes are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request and follow the [Code of Conduct](CODE_OF_CONDUCT.md) in project spaces.

Security-sensitive filesystem or deletion issues should be reported privately as described in [SECURITY.md](SECURITY.md).

## License

SpaceLens is available under the [MIT License](LICENSE).
