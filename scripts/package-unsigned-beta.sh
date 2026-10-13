#!/bin/bash

set -euo pipefail

RELEASE_LABEL="${1:-0.1.0-beta.1}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

if [[ ! "$RELEASE_LABEL" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  echo "Release label must look like 0.1.0-beta.1" >&2
  exit 2
fi

if [[ ! "$BUILD_NUMBER" =~ ^[1-9][0-9]*$ ]]; then
  echo "BUILD_NUMBER must be a positive integer" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MARKETING_VERSION="${RELEASE_LABEL%%-*}"
RELEASE_DIR="$REPO_ROOT/.build/release"
DERIVED_DATA="$RELEASE_DIR/DerivedData"
STAGING_DIR="$RELEASE_DIR/dmg-root"
APP_PATH="$DERIVED_DATA/Build/Products/Release/SpaceLens.app"
DMG_NAME="SpaceLens-$RELEASE_LABEL-unsigned.dmg"
DMG_PATH="$RELEASE_DIR/$DMG_NAME"
CHECKSUM_PATH="$DMG_PATH.sha256"

if [[ "$RELEASE_DIR" != "$REPO_ROOT/.build/release" ]]; then
  echo "Refusing to clean an unexpected release directory" >&2
  exit 3
fi

rm -rf -- "$DERIVED_DATA" "$STAGING_DIR"
rm -f -- "$DMG_PATH" "$CHECKSUM_PATH"
mkdir -p "$RELEASE_DIR" "$STAGING_DIR"

xcodebuild build \
  -quiet \
  -project "$REPO_ROOT/SpaceLens/SpaceLens.xcodeproj" \
  -scheme SpaceLens \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  MARKETING_VERSION="$MARKETING_VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER"

if [[ ! -d "$APP_PATH" ]]; then
  echo "SpaceLens.app was not produced at the expected path" >&2
  exit 4
fi

if codesign --verify "$APP_PATH" >/dev/null 2>&1; then
  echo "Expected an unsigned app, but the build has a valid signature" >&2
  exit 5
fi

/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Contents/Info.plist"

ditto "$APP_PATH" "$STAGING_DIR/SpaceLens.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "SpaceLens $RELEASE_LABEL" \
  -srcfolder "$STAGING_DIR" \
  -fs HFS+ \
  -format UDZO \
  "$DMG_PATH"

shasum -a 256 "$DMG_PATH" | sed "s#  .*/#  #" > "$CHECKSUM_PATH"

echo "Created: $DMG_PATH"
echo "Checksum: $CHECKSUM_PATH"
