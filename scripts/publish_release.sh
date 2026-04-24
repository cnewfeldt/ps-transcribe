#!/usr/bin/env bash
set -euo pipefail

# Publish PS Transcribe DMG + auto-update feed.
#
# Usage:
#   ./scripts/publish_release.sh                  # publish release + update appcast
#   ./scripts/publish_release.sh 2.1.1            # explicit version override
#   DRAFT=1 ./scripts/publish_release.sh          # create as draft (skips appcast)
#   PRERELEASE=1 ./scripts/publish_release.sh     # mark as prerelease
#   APPCAST_ONLY=1 ./scripts/publish_release.sh   # update appcast only (use after
#                                                 # flipping a draft to public)
#
# Requirements:
#   - gh CLI authenticated with push access to cnewfeldt/ps-transcribe-releases
#   - dist/PS Transcribe.dmg already built (scripts/build_swift_app.sh + make_dmg.sh)
#   - Sparkle artifacts present at PSTranscribe/.build/artifacts/sparkle/
#     (run `swift build --package-path PSTranscribe` if missing)
#   - EdDSA private key in macOS keychain (run Sparkle's generate_keys once)

cd "$(dirname "$0")/.."
ROOT_DIR="$(pwd)"

DMG_PATH="$ROOT_DIR/dist/PS Transcribe.dmg"
INFO_PLIST="$ROOT_DIR/PSTranscribe/Sources/PSTranscribe/Info.plist"
RELEASE_NOTES_DIR="$ROOT_DIR/release-notes"
RELEASES_REPO="cnewfeldt/ps-transcribe-releases"
SPARKLE_BIN="$ROOT_DIR/PSTranscribe/.build/artifacts/sparkle/Sparkle/bin"

# Temp file cleanup on exit
TMPFILES=()
cleanup() { for f in "${TMPFILES[@]:-}"; do [[ -n "$f" ]] && rm -f "$f"; done; }
trap cleanup EXIT

# --- Preflight ---
if [[ ! -f "$DMG_PATH" ]]; then
  echo "ERROR: $DMG_PATH not found. Run scripts/build_swift_app.sh && scripts/make_dmg.sh first."
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI not found. Install: brew install gh"
  exit 1
fi

if [[ ! -x "$SPARKLE_BIN/sign_update" ]]; then
  echo "ERROR: sign_update not found at $SPARKLE_BIN/sign_update"
  echo "Run 'swift build --package-path PSTranscribe' first to fetch Sparkle artifacts."
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

# --- Sign DMG with EdDSA (Sparkle) ---
echo "=== Signing DMG with EdDSA ==="
SIGN_OUTPUT=$("$SPARKLE_BIN/sign_update" "$DMG_PATH" 2>&1) || {
  echo "ERROR: sign_update failed"
  echo "$SIGN_OUTPUT"
  exit 1
}

SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -n 's/.*edSignature="\([^"]*\)".*/\1/p')
DMG_LENGTH=$(echo "$SIGN_OUTPUT" | sed -n 's/.*length="\([^"]*\)".*/\1/p')

if [[ -z "$SIGNATURE" || -z "$DMG_LENGTH" ]]; then
  echo "ERROR: couldn't parse sign_update output: $SIGN_OUTPUT"
  exit 1
fi

echo "EdDSA signature: $SIGNATURE"
echo "DMG length: $DMG_LENGTH bytes"

# --- Appcast update function ---
update_appcast() {
  echo "=== Updating appcast.xml on $RELEASES_REPO ==="

  local pubdate
  pubdate=$(LC_ALL=C date -u +"%a, %d %b %Y %H:%M:%S +0000")

  local min_system
  min_system=$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "$INFO_PLIST")

  local dmg_url="https://github.com/$RELEASES_REPO/releases/download/$TAG/PS.Transcribe.dmg"
  local release_url="https://github.com/$RELEASES_REPO/releases/tag/$TAG"

  local new_item
  new_item=$(cat <<ITEM
    <item>
      <title>PS Transcribe $VERSION</title>
      <pubDate>$pubdate</pubDate>
      <sparkle:version>$VERSION</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>$min_system</sparkle:minimumSystemVersion>
      <sparkle:releaseNotesLink>$release_url</sparkle:releaseNotesLink>
      <enclosure url="$dmg_url" sparkle:edSignature="$SIGNATURE" length="$DMG_LENGTH" type="application/octet-stream" />
    </item>
ITEM
)

  local current new
  current=$(mktemp -t appcast-cur.XXXXXX)
  new=$(mktemp -t appcast-new.XXXXXX)
  TMPFILES+=("$current" "$new")

  # Fetch existing appcast; create a fresh one if the file doesn't exist
  local existing_sha=""
  if existing_sha=$(gh api "repos/$RELEASES_REPO/contents/appcast.xml" --jq '.sha' 2>/dev/null) && [[ -n "$existing_sha" ]]; then
    gh api "repos/$RELEASES_REPO/contents/appcast.xml" --jq '.content' | base64 -d > "$current"
    echo "Fetched existing appcast.xml (sha ${existing_sha:0:8})"
  else
    existing_sha=""
    cat > "$current" <<XML
<?xml version="1.0" standalone="yes"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>
    <title>PS Transcribe</title>
    <link>https://raw.githubusercontent.com/$RELEASES_REPO/main/appcast.xml</link>
    <description>PS Transcribe release feed</description>
    <language>en</language>
  </channel>
</rss>
XML
    echo "No existing appcast.xml — creating fresh feed"
  fi

  # Determine insertion point: before first <item>, or before </channel> if no items yet
  local insert_line
  if grep -q "<item>" "$current"; then
    insert_line=$(grep -n "<item>" "$current" | head -1 | cut -d: -f1)
  else
    insert_line=$(grep -n "</channel>" "$current" | head -1 | cut -d: -f1)
  fi

  if [[ -z "$insert_line" ]]; then
    echo "ERROR: could not find insertion point in appcast.xml"
    return 1
  fi

  head -n $((insert_line - 1)) "$current" > "$new"
  printf '%s\n' "$new_item" >> "$new"
  tail -n +"$insert_line" "$current" >> "$new"

  # Push updated appcast.xml back to the public repo
  local api_args=(
    -X PUT
    "repos/$RELEASES_REPO/contents/appcast.xml"
    -f "message=release: appcast $VERSION"
    -f "content=$(base64 -i "$new")"
  )
  if [[ -n "$existing_sha" ]]; then
    api_args+=(-f "sha=$existing_sha")
  fi

  local commit_sha
  commit_sha=$(gh api "${api_args[@]}" --jq '.commit.sha')
  echo "appcast.xml pushed (commit ${commit_sha:0:8})"
  echo "Feed URL: https://raw.githubusercontent.com/$RELEASES_REPO/main/appcast.xml"
}

# --- APPCAST_ONLY mode: update feed only, no release creation ---
if [[ "${APPCAST_ONLY:-0}" == "1" ]]; then
  echo "=== APPCAST_ONLY mode — skipping release creation ==="
  update_appcast
  exit 0
fi

# --- Main publish flow ---
echo "=== Publishing $TAG to $RELEASES_REPO ==="

# Bail if tag already exists (use APPCAST_ONLY=1 if you just want to refresh the feed)
if gh release view "$TAG" -R "$RELEASES_REPO" >/dev/null 2>&1; then
  echo "ERROR: release $TAG already exists on $RELEASES_REPO."
  echo "Delete it first (gh release delete $TAG -R $RELEASES_REPO --yes --cleanup-tag) or bump the version."
  echo "To update just the appcast for an existing release, run with APPCAST_ONLY=1."
  exit 1
fi

# --- Load user-facing release notes from release-notes/v<version>.md ---
NOTES_FILE="$RELEASE_NOTES_DIR/v$VERSION.md"
NOTES_TEMPLATE="$RELEASE_NOTES_DIR/TEMPLATE.md"

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

# --- Create GitHub release ---
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

gh release create "${RELEASE_FLAGS[@]}"
echo "=== Release $TAG created ==="

# --- Update appcast (only for published releases) ---
if [[ "${DRAFT:-0}" == "1" ]]; then
  echo ""
  echo "DRAFT mode — skipped appcast update."
  echo "After flipping the draft public:"
  echo "  gh release edit $TAG -R $RELEASES_REPO --draft=false"
  echo "  APPCAST_ONLY=1 ./scripts/publish_release.sh"
else
  update_appcast
fi

echo ""
echo "=== Done ==="
echo "Release URL: https://github.com/$RELEASES_REPO/releases/tag/$TAG"
