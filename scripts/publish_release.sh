#!/usr/bin/env bash
set -euo pipefail

# Publish PS Transcribe DMG to the public releases repo as a GitHub Release.
#
# Usage:
#   ./scripts/publish_release.sh              # reads version from Info.plist
#   ./scripts/publish_release.sh 2.1.1        # explicit version
#   DRAFT=1 ./scripts/publish_release.sh      # create as draft
#   PRERELEASE=1 ./scripts/publish_release.sh # mark as prerelease
#
# Requirements:
#   - gh CLI authenticated (gh auth status)
#   - dist/PS Transcribe.dmg already built (scripts/build_swift_app.sh + make_dmg.sh)
#   - Push access to cnewfeldt/ps-transcribe-releases

cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"

DMG_PATH="$ROOT_DIR/dist/PS Transcribe.dmg"
INFO_PLIST="$ROOT_DIR/PSTranscribe/Sources/PSTranscribe/Info.plist"
RELEASE_NOTES_DIR="$ROOT_DIR/release-notes"
RELEASES_REPO="cnewfeldt/ps-transcribe-releases"

# --- Preflight ---
if [[ ! -f "$DMG_PATH" ]]; then
  echo "ERROR: $DMG_PATH not found. Run scripts/build_swift_app.sh && scripts/make_dmg.sh first."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found. Install: brew install gh"
  exit 1
fi

# --- Resolve version ---
if [[ $# -ge 1 ]]; then
  VERSION="$1"
else
  VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
fi

if [[ -z "${VERSION:-}" ]]; then
  echo "ERROR: could not resolve version"
  exit 1
fi

TAG="v$VERSION"
echo "=== Publishing $TAG to $RELEASES_REPO ==="

# Bail if tag already exists on the public repo — releases are immutable
if gh release view "$TAG" -R "$RELEASES_REPO" >/dev/null 2>&1; then
  echo "ERROR: release $TAG already exists on $RELEASES_REPO."
  echo "Delete it first (gh release delete $TAG -R $RELEASES_REPO) or bump the version."
  exit 1
fi

# --- Load user-facing release notes from release-notes/v<version>.md ---
# Release notes are hand-written for end users: plain language, no code
# identifiers, no framework names. CHANGELOG.md stays internal.
NOTES_FILE="$RELEASE_NOTES_DIR/v$VERSION.md"
NOTES_TEMPLATE="$RELEASE_NOTES_DIR/TEMPLATE.md"

# If the notes file doesn't exist, scaffold it from the template and halt.
# This lets the user run publish_release.sh blindly after bumping the version
# without remembering to create the notes file first.
if [[ ! -f "$NOTES_FILE" ]]; then
  if [[ ! -f "$NOTES_TEMPLATE" ]]; then
    echo "ERROR: release notes not found at $NOTES_FILE and no template at $NOTES_TEMPLATE"
    exit 1
  fi
  sed "s/{{VERSION}}/$VERSION/g" "$NOTES_TEMPLATE" > "$NOTES_FILE"
  echo "Scaffolded $NOTES_FILE from template."
  echo "Edit the file with the user-facing release notes, then rerun this script."
  exit 1
fi

# Refuse to publish a file that still contains the template's TODO marker.
if grep -q "TODO: fill in user-facing release notes" "$NOTES_FILE"; then
  echo "ERROR: $NOTES_FILE still contains the TODO placeholder."
  echo "Fill in the release notes before publishing."
  exit 1
fi

if [[ ! -s "$NOTES_FILE" ]]; then
  echo "ERROR: $NOTES_FILE is empty"
  exit 1
fi

echo "--- Release notes preview ---"
cat "$NOTES_FILE"
echo "-----------------------------"

# --- Build release flags ---
RELEASE_FLAGS=(
  "$TAG"
  "$DMG_PATH"
  --repo "$RELEASES_REPO"
  --title "PS Transcribe $VERSION"
  --notes-file "$NOTES_FILE"
)

if [[ "${DRAFT:-0}" == "1" ]]; then
  RELEASE_FLAGS+=(--draft)
fi

if [[ "${PRERELEASE:-0}" == "1" ]]; then
  RELEASE_FLAGS+=(--prerelease)
fi

# --- Create release ---
gh release create "${RELEASE_FLAGS[@]}"

echo "=== Release $TAG published ==="
echo "URL: https://github.com/$RELEASES_REPO/releases/tag/$TAG"
