# Security policy

SpaceLens reads filesystem metadata and, only after explicit confirmation, can move a selected item to the macOS Trash. It does not permanently delete files, empty Trash, upload scan data, or perform automatic cleanup.

## Supported versions

Only the latest commit on `main` is currently supported. Tagged public releases do not yet exist.

## Report a vulnerability

Report security-sensitive findings through [GitHub private vulnerability reporting](https://github.com/DTGlov/spacelens-macos/security/advisories/new).

If private reporting is unavailable, contact the maintainer privately through a method listed on the [DTGlov GitHub profile](https://github.com/DTGlov). Do not open a public issue for an unpatched vulnerability.

Include only the information needed to reproduce and assess the issue:

- A clear description and potential impact
- A minimal reproduction using temporary, non-sensitive test data
- The affected commit or version
- Relevant macOS and Swift versions
- Any suggested mitigation

Never include personal filenames, paths, file contents, credentials, or other private data.

## Important areas

Reports are especially valuable when they involve:

- Escaping a user-authorized root or session exclusion
- Unexpected symbolic-link, package, or filesystem-boundary traversal
- Incorrect identity or scope revalidation before a Trash operation
- Duplicate matching that could misidentify different files
- Unsafe handling of security-scoped access
- Exposure of private paths, metadata, or file contents
- Moving a file without explicit, item-specific confirmation
- Crashes or resource exhaustion caused by crafted directory structures

You should receive an acknowledgment within seven days. Please allow time for investigation and a coordinated fix before public disclosure.
