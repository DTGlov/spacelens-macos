# SpaceLens

SpaceLens is a native macOS storage explorer that helps people understand what is using disk space and safely reclaim it.

## Product promise

SpaceLens answers three questions clearly:

1. What is consuming my storage?
2. Where is it located?
3. What can I safely remove?

The app prioritizes clarity and trust over aggressive cleanup. It never describes an unknown file as junk, never deletes silently, and moves files to Trash rather than permanently deleting them.

## First release

The first release supports one complete workflow:

1. The user chooses a folder with the standard macOS folder picker.
2. SpaceLens scans only the location the user authorized.
3. Scan progress and the currently scanned location are visible.
4. Results appear as an interactive treemap and a sortable list.
5. Selecting an item opens an inspector with its size, path, type, modification date, and contents summary.
6. The user can reveal the item in Finder, preview it with Quick Look, or move it to Trash.
7. SpaceLens reports the amount of space moved to Trash.

## Primary screens

### Welcome

- Brief explanation of what SpaceLens does.
- Primary action: **Choose a folder to scan**.
- Recent locations appear only after the user has completed a scan.
- No request for Full Disk Access during onboarding.

### Scan

- Shows the authorized root location.
- Displays discovered size, item count, elapsed time, and current path.
- Results stream into the interface while the scan continues.
- The user can cancel without losing already collected results.
- Permission failures are shown as skipped locations, not treated as fatal errors.

### Results

- Treemap is the main visualization: area represents size and color represents category.
- A synchronized list supports precise sorting and keyboard navigation.
- Breadcrumbs allow navigation back through the scanned hierarchy.
- Filters include folders, applications, video, audio, images, archives, documents, and developer files.
- Search filters the current scan without rescanning the disk.

### Inspector

- Name, icon, exact path, allocated size, logical size, kind, and modification date.
- Folder breakdown for containers.
- A plain-language safety assessment with supporting reasons.
- Actions: Quick Look, Reveal in Finder, and Move to Trash.
- Destructive actions are visually distinct and never the default focused action.

### Cleanup summary

- Items moved to Trash.
- Estimated space reclaimable after Trash is emptied.
- Any failed operations and their reasons.
- SpaceLens does not empty Trash itself in the first release.

## Interaction model

- Single click selects an item and opens its inspector.
- Double click on a folder zooms into it.
- Space opens Quick Look.
- Command-Delete requests moving the selected item to Trash and presents confirmation.
- Command-Up navigates to the parent folder.
- Escape cancels a scan or closes transient UI.
- Every essential action must remain available without using the treemap.

## Visual direction

- Native macOS window, toolbar, sidebar, materials, typography, and controls.
- Calm neutral surfaces so storage categories carry the visual emphasis.
- Category colors remain consistent across the treemap, list, and inspector.
- Size is communicated through both area and text; color is never the only signal.
- Animations explain hierarchy changes but respect Reduce Motion.
- Dark mode, increased contrast, keyboard use, and VoiceOver are first-class requirements.

## Safety policy

Each item receives one of three assessments:

- **Known reproducible**: generated data with a specific, explainable regeneration path. This label is informational and still requires confirmation.
- **Review carefully**: user data, downloads, archives, duplicates, old files, or application-owned content.
- **Protected or unknown**: system locations, credentials, configuration, source trees, or anything SpaceLens cannot confidently classify.

Rules:

- No automatic cleanup.
- No permanent deletion.
- No bulk preselection of files.
- No deletion based only on a filename or extension.
- Never follow symbolic links while calculating a directory tree.
- Never cross filesystem or authorized-root boundaries without explicit user action.
- Revalidate identity and location immediately before moving an item to Trash.
- Git repositories and package contents receive prominent context before any removal action.
- Cleanup history records metadata, not copies of private file contents.

## Out of scope for version one

- Duplicate detection
- Background or scheduled scanning
- Automatic cleanup recommendations
- Full Disk Access onboarding
- Cloud-storage optimization
- Emptying Trash
- Windows support
- Rust integration

## Success criteria

- A user can identify the largest items inside an authorized folder within seconds of results becoming available.
- The interface stays responsive throughout a scan.
- Cancelling a scan works promptly.
- Inaccessible files do not abort a scan.
- SpaceLens never moves an item without an explicit, item-specific confirmation.
- The app clearly distinguishes space moved to Trash from space actually reclaimed.

