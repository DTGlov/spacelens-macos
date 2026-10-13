# Packaging an unsigned beta

Unsigned packages are for trusted early testing, not stable public distribution.

## Local package

From the repository root, run:

```sh
./scripts/package-unsigned-beta.sh 0.1.0-beta.1
```

The script creates these ignored build artifacts:

- `.build/release/SpaceLens-0.1.0-beta.1-unsigned.dmg`
- `.build/release/SpaceLens-0.1.0-beta.1-unsigned.dmg.sha256`

It performs a clean universal Release build for Apple-silicon and Intel Macs, disables code signing, verifies that the app is unsigned, creates a disk image with an Applications shortcut, and generates a SHA-256 checksum.

## GitHub artifact

The **Unsigned beta package** workflow is manual-only:

1. Open the repository's **Actions** tab.
2. Select **Unsigned beta package**.
3. Choose **Run workflow** and enter a release label.
4. Download the retained artifact after the job succeeds.

The workflow does not create a tag, GitHub Release, or permanent public download. Artifacts expire after 14 days.

## Tester handoff

Share all of the following with a trusted tester:

- The disk image
- Its `.sha256` file
- The exact source commit
- [Running unsigned builds](UNSIGNED_BUILDS.md)

Never describe an unsigned build as verified by Apple. Signed and notarized distribution remains blocked until an Apple Developer account is available.
