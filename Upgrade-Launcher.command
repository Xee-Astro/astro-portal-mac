#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh
trap 'status=$?; printf "\nPress Return to close..."; read -r _; exit "$status"' EXIT
[ "$(uname -s)" = Darwin ] || fail 'Run this on your Mac.'
[ -x "$ANDROID_HOME/emulator/emulator" ] || fail 'No existing Astro Android environment. Run Install.command instead.'
echo 'Quit Astro Portal and stop Android before upgrading the launcher.'
confirm 'Install the new Astro Portal interface and fullscreen display? Existing Android data and settings are preserved.'
lock
trap 'status=$?; rmdir "$ROOT/operation.lock" 2>/dev/null || true; printf "\nPress Return to close..."; read -r _; exit "$status"' EXIT
/bin/bash ./install-display.sh
/bin/bash ./build-launcher.sh
echo 'Double-click Astro Portal in your home Applications folder.'
