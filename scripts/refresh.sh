#!/usr/bin/env bash
set -euo pipefail

# Refresh PS Transcribe for testing
# Usage:
#   ./scripts/refresh.sh          # Rebuild and relaunch
#   ./scripts/refresh.sh --reset  # Wipe all data (first-launch experience)

cd "$(dirname "$0")/.."

echo "=== Stopping PS Transcribe ==="
killall "PS Transcribe" 2>/dev/null || true
killall PSTranscribe 2>/dev/null || true
sleep 1

if [[ "${1:-}" == "--reset" ]]; then
  echo "=== Wiping app data (first-launch reset) ==="
  defaults delete com.pstranscribe.app 2>/dev/null || true
  rm -f ~/Library/Application\ Support/PSTranscribe/library.json
  rm -rf ~/Library/Application\ Support/PSTranscribe/.checkpoints
  rm -rf ~/Library/Application\ Support/FluidAudio/Models
  echo "UserDefaults, library, checkpoints, and speech models cleared"
fi

echo "=== Building app bundle ==="
./scripts/build_swift_app.sh

echo "=== Refreshing launch services ==="
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user 2>/dev/null || true
sleep 2

echo "=== Launching PS Transcribe ==="
open "/Applications/PS Transcribe.app" 2>/dev/null || {
  echo "open failed, launching binary directly..."
  "/Applications/PS Transcribe.app/Contents/MacOS/PSTranscribe" &
}
