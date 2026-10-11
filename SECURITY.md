# Security policy

SpaceLens is an early prototype that reads filesystem metadata from folders the user selects. It does not currently delete, move, upload, or modify files.

## Supported versions

Only the latest commit on `main` is currently supported. Tagged public releases do not yet exist.

## Report a vulnerability

Please report security-sensitive findings through [GitHub's private vulnerability reporting](https://github.com/DTGlov/spacelens-macos/security/advisories/new).

If private reporting is unavailable, contact the maintainer privately through a method listed on the [DTGlov GitHub profile](https://github.com/DTGlov). Do not open a public issue for an unpatched vulnerability.

Include only the information needed to reproduce and assess the issue:

- A clear description and potential impact
- A minimal reproduction using non-sensitive test data
- Affected commit or version
- Relevant macOS and Swift versions
- Any suggested mitigation

Never include personal filenames, paths, file contents, credentials, or other private data in a report.

## Important areas

Reports are especially valuable when they involve:

- Escaping the user-authorized scan root
- Unexpected symbolic-link traversal
- Crossing filesystem boundaries
- Unsafe handling of security-scoped access
- Incorrect file identity before a future Trash operation
- Exposure of private paths or metadata
- Crashes or resource exhaustion caused by crafted directory structures

You should receive an acknowledgment within seven days. Please allow time for investigation and a coordinated fix before public disclosure.
