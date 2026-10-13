# Running unsigned SpaceLens builds

SpaceLens does not yet publish signed or notarized releases. The safest way to test it is to build the source in Xcode yourself.

Early testing disk images may be produced by the repository's manual packaging workflow. They are intentionally named `unsigned` and are temporary test artifacts, not stable releases.

## Before opening an unsigned build

Only accept a build from a contributor you trust. Confirm the source commit it was built from and keep backups of important files. macOS cannot verify the developer identity or notarization status of an unsigned application.

## Open a trusted build

If macOS blocks a trusted test build:

1. In Finder, Control-click the SpaceLens app and choose **Open**.
2. Review the warning and choose **Open** again if you trust the source.
3. If that option is unavailable, open **System Settings → Privacy & Security**, find the blocked-app message, and choose **Open Anyway**.

Do not disable Gatekeeper globally. Do not remove quarantine metadata from applications you have not verified.

## Permissions

SpaceLens uses the standard folder picker and requests access only to locations you choose. A Trash action requires read/write access to the selected location. The app does not require Full Disk Access.

## Report a problem

Use the repository's bug-report form for ordinary problems. Remove personal filenames, paths, and contents from screenshots or logs. Report security-sensitive behavior privately according to [SECURITY.md](../SECURITY.md).
