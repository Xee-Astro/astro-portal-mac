#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh
APP="$HOME/Applications/Astro Portal.app"
if [ -e "$APP" ] && [ ! -f "$APP/Contents/Resources/astro-dwarf-test.marker" ]; then
  fail "An unrelated app already exists at $APP. Rename it before retrying."
fi
stage="$(mktemp -d "$ROOT/cache/launcher.XXXXXX")"
/usr/bin/osacompile -l JavaScript -s -o "$stage/Astro Portal.app" Launcher.js
bundle="$stage/Astro Portal.app"
cp common.sh worker.sh AstroPortal.icns "$bundle/Contents/Resources/"
touch "$bundle/Contents/Resources/astro-dwarf-test.marker"
plist="$bundle/Contents/Info.plist"
set_plist() {
  /usr/libexec/PlistBuddy -c "Delete :$1" "$plist" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :$1 $2 $3" "$plist"
}
set_plist CFBundleIdentifier string local.astroportal.mac
set_plist CFBundleName string 'Astro Portal'
set_plist CFBundleDisplayName string 'Astro Portal'
set_plist CFBundleVersion string 1.1.0
set_plist CFBundleShortVersionString string 1.1
set_plist CFBundleIconFile string AstroPortal.icns
set_plist LSMinimumSystemVersion string 12.0
set_plist NSHighResolutionCapable bool true
set_plist NSLocationUsageDescription string 'Astro Portal sends your Mac location to the Android GPS provider for DWARFLAB telescope alignment.'
set_plist NSLocationWhenInUseUsageDescription string 'Astro Portal shares observing coordinates with DWARFLAB while the launcher is open.'
/usr/bin/plutil -lint "$plist"
/usr/bin/codesign --force --deep --sign - "$bundle"
/usr/bin/codesign --verify --deep "$bundle"
mkdir -p "$HOME/Applications"
# Overlay only the known application; the Android profile and settings are separate.
/usr/bin/ditto "$bundle" "$APP"
mkdir -p "$HOME/Desktop"
ln -sfn "$APP" "$HOME/Desktop/Astro Portal.app"
echo "Launcher installed: $APP"
if [ "${ASTRO_NO_REVEAL:-0}" != 1 ]; then open -R "$APP"; fi
