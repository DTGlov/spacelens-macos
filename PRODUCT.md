# SpaceLens product guide

SpaceLens is a native macOS storage explorer that helps people understand what consumes disk space and make deliberate cleanup decisions.

## Product promise

SpaceLens answers three questions:

1. What is consuming my storage?
2. Where is it located?
3. What should I review before reclaiming space?

The app prioritizes clarity and trust over aggressive cleanup. It never describes an unknown file as junk, never cleans automatically, and moves files to Trash rather than permanently deleting them.

## Current workflow

1. Choose a folder with the native macOS folder picker.
2. Optionally exclude subfolders for this scan session.
3. Review progress and cancel if needed.
4. Explore an interactive treemap and sortable table.
5. Navigate folders, search names, or filter by size, kind, and insight.
6. Inspect an item's size, type, location, date, and deletion guidance.
7. Preview it, reveal it in Finder, or request moving it to Trash.
8. Confirm the item-specific operation after SpaceLens revalidates it.

Duplicate detection is an optional second pass over the same authorized scope and exclusions. It groups by size before hashing content, then presents every matching copy for individual review.

## Interaction model

- Single-click selects an item.
- Double-click opens a folder.
- Space opens Quick Look for a supported file.
- Command-Delete requests moving the selected item to Trash.
- Command-Up navigates to the enclosing folder.
- Command-Down opens the selected folder.
- Every essential action remains available without using the treemap.

## Safety policy

Each item receives one of three assessments:

- **Known reproducible**: generated data with a specific regeneration path
- **Review carefully**: user data, downloads, archives, applications, duplicates, and older files
- **Protected or unknown**: system locations, credentials, configuration, source-control metadata, links, incomplete scans, or unknown locations

Rules:

- No automatic cleanup or bulk preselection.
- No permanent deletion or emptying Trash.
- No decision based only on a filename, extension, age, or duplicate status.
- Never follow symbolic links or cross the authorized root or filesystem boundary.
- Never read inside a selected exclusion.
- Revalidate identity and scope immediately before moving an item.
- Describe duplicate savings as potential, not guaranteed.

## Visual direction

- Native macOS behavior, controls, typography, and keyboard conventions
- Calm neutral surfaces with consistent category colors
- Size communicated through both area and text
- Color never used as the only signal
- Dark mode, increased contrast, Reduce Motion, VoiceOver, and keyboard access treated as requirements

## Out of scope for the first tagged release

- Background or scheduled scanning
- Automatic cleanup recommendations
- Full Disk Access onboarding
- Cloud-storage optimization
- Emptying Trash
- Persistent scan history
- Windows support
- Rust integration without measured need

## Success criteria

- Users can identify unusually large items inside an authorized folder within seconds.
- The interface remains responsive during scans.
- Cancellation works promptly.
- Inaccessible files do not abort the entire scan.
- Excluded folders remain unread and absent from both result types.
- No item moves without explicit, item-specific confirmation.
- The app distinguishes potential savings, space moved to Trash, and space actually reclaimed.

