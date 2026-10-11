# Contributing to SpaceLens

Thank you for helping make macOS storage easier to understand. Contributions of code, tests, documentation, design feedback, and reproducible bug reports are welcome.

## Before you start

- Search existing issues and pull requests before opening a duplicate.
- For a substantial feature or architectural change, open a proposal first so the direction can be discussed before significant work begins.
- Never test destructive filesystem behavior against personal files. Use temporary fixture directories.
- Do not include private paths, filenames, screenshots, or other personal data in issues, logs, or test fixtures.

## Development setup

SpaceLens requires macOS 14 or later and Xcode 26 or a compatible Swift 6.2 toolchain.

```sh
git clone https://github.com/DTGlov/spacelens-macos.git
cd spacelens-macos
swift test
xcodebuild test -project SpaceLens/SpaceLens.xcodeproj -scheme SpaceLens -destination 'platform=macOS'
open SpaceLens/SpaceLens.xcodeproj
```

The native application is defined by the Xcode project. A Swift package remains available for fast scanner tests and command-line development. The project has no third-party dependencies.

## Branches

Create each change from the latest `main` branch. Use a short, descriptive branch name:

- `feature/storage-treemap`
- `fix/scan-cancellation`
- `docs/scanner-architecture`
- `chore/ci-maintenance`

Keep a branch focused on one coherent change. Do not bundle unrelated formatting or refactoring into a feature pull request.

## Engineering expectations

- Investigate existing behavior before editing.
- Prefer the smallest safe change that solves the problem.
- Keep filesystem access and safety decisions outside SwiftUI views.
- Preserve the rule that symbolic links are not followed during recursive scans.
- Treat inaccessible entries as scan results rather than failing the entire scan.
- Do not introduce automatic cleanup, permanent deletion, or unsupported “safe to delete” claims.
- Prefer Apple frameworks before adding a third-party dependency.
- Add focused regression coverage for behavior changes.
- Support native macOS conventions, keyboard use, VoiceOver, increased contrast, and Reduce Motion.

Read [AGENTS.md](AGENTS.md) for the complete project engineering rules.

## Before opening a pull request

Run:

```sh
swift test
xcodebuild test -project SpaceLens/SpaceLens.xcodeproj -scheme SpaceLens -destination 'platform=macOS'
git diff --check
```

Then review the complete diff for unrelated changes, generated files, private data, and unsafe filesystem behavior.

## Pull requests

In the pull request description:

- Explain the user-visible outcome.
- Describe important implementation or safety decisions.
- List the validation performed.
- Include screenshots or a short recording for visible interface changes.
- Call out risks, limitations, and unverified behavior.

By contributing, you agree that your contribution is licensed under the project's MIT License.
