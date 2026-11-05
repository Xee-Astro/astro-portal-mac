#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh
trap 'status=$?; if [ "$status" != 0 ]; then echo "Setup stopped. See the message above. No Android data was erased."; fi; printf "\nPress Return to close..."; read -r _; exit "$status"' EXIT
[ "$(uname -s)" = Darwin ] || fail 'This installer runs on macOS only.'
architecture
echo "Astro Portal Mac | version 1.1 | $ABI"
echo 'Requires macOS 12+, 16 GB RAM recommended, and 12 GB free.'
echo 'Downloads a private Java runtime, Android SDK/emulator, Android 11 and the vendor APK.'
echo 'No administrator password is required. Internet is required during setup.'
echo 'Telescope discovery, pairing, live view and capture are unverified.'
major="$(sw_vers -productVersion | cut -d. -f1)"
[ "$major" -ge 12 ] || fail 'macOS 12 or later is required.'
free_kb="$(df -Pk "$HOME" | awk 'END {print $4}')"
[ "$free_kb" -ge 12582912 ] || fail 'Please free at least 12 GB on your home volume.'
confirm 'Install Astro Portal in your Mac user profile?'
lock
# Keep the lock cleanup together with the interactive exit handler.
trap 'status=$?; rmdir "$ROOT/operation.lock" 2>/dev/null || true; if [ "$status" != 0 ]; then echo "Setup stopped. See the message above."; fi; printf "\nPress Return to close..."; read -r _; exit "$status"' EXIT
if [ ! -x "$JAVA_HOME/bin/java" ]; then
  confirm 'Download Eclipse Temurin Java 21 from Adoptium?'
  url="https://api.adoptium.net/v3/binary/latest/21/ga/mac/$JARCH/jdk/hotspot/normal/eclipse"
  download "$url" "$ROOT/cache/java.tar.gz"
  checksum_url="https://api.adoptium.net/v3/checksum/latest/21/ga/mac/$JARCH/jdk/hotspot/normal/eclipse"
  if curl -fsSL "$checksum_url" -o "$ROOT/cache/java.sha256"; then
    expected="$(awk 'NR==1 {print $1}' "$ROOT/cache/java.sha256")"
    actual="$(shasum -a 256 "$ROOT/cache/java.tar.gz" | awk '{print $1}')"
    [ "$actual" = "$expected" ] || fail 'Java checksum mismatch.'
  else
    echo 'Adoptium checksum endpoint unavailable; continuing with the signed HTTPS download.'
  fi
  mkdir -p "$ROOT/java"
  tar -xzf "$ROOT/cache/java.tar.gz" --strip-components 1 -C "$ROOT/java"
  rm -f "$ROOT/cache/java.tar.gz" "$ROOT/cache/java.sha256"
fi
export PATH="$JAVA_HOME/bin:$PATH"
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  confirm 'Download Google Android command-line tools?'
  download https://dl.google.com/android/repository/commandlinetools-mac-13114758_latest.zip "$ROOT/cache/tools.zip"
  actual="$(shasum -a 1 "$ROOT/cache/tools.zip" | awk '{print $1}')"
  [ "$actual" = c3e06a1959762e89167d1cbaa988605f6f7c1d24 ] || fail 'Android tools checksum mismatch.'
  stage="$(mktemp -d "$ROOT/cache/tools.XXXXXX")"
  unzip -q "$ROOT/cache/tools.zip" -d "$stage"
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  mv "$stage/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rmdir "$stage"
  rm -f "$ROOT/cache/tools.zip"
fi
SDK="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
confirm 'Download Android components? You will review Google SDK licenses next; type y only for licenses you accept.'
"$SDK" --sdk_root="$ANDROID_HOME" --licenses
"$SDK" --sdk_root="$ANDROID_HOME" --channel=0 'platform-tools' 'emulator' "$IMAGE"
"$ANDROID_HOME/emulator/emulator" -accel-check || fail 'Hardware acceleration unavailable on this Mac.'
if [ ! -f "$ANDROID_AVD_HOME/$AVD.avd/config.ini" ]; then
  printf 'no\n' | "$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd --name "$AVD" --package "$IMAGE" --path "$ANDROID_AVD_HOME/$AVD.avd"
  cat >>"$ANDROID_AVD_HOME/$AVD.avd/config.ini" <<'CONFIG'
hw.lcd.width=2560
hw.lcd.height=1600
hw.lcd.density=240
hw.ramSize=3072
disk.dataPartition.size=4G
hw.keyboard=yes
hw.gpu.enabled=yes
hw.gpu.mode=auto
showDeviceFrame=no
CONFIG
fi
confirm 'Download the fullscreen display component (scrcpy) from its official release?'
/bin/bash ./install-display.sh
confirm 'Download and install the original DWARFLAB Android app from the official vendor link?'
download "$APK_URL" "$ROOT/cache/DWARFLAB.apk"
unzip -tq "$ROOT/cache/DWARFLAB.apk" >/dev/null || fail 'DWARFLAB download is not a valid APK.'
unzip -Z1 "$ROOT/cache/DWARFLAB.apk" | grep "^lib/$ABI/" >/dev/null || fail "Vendor APK does not contain $ABI native libraries."
boot
device install -r "$ROOT/cache/DWARFLAB.apk"
rm -f "$ROOT/cache/DWARFLAB.apk"
/bin/bash ./build-launcher.sh
echo 'Setup complete. Double-click Astro Portal in your home Applications folder.'
echo 'Select observing coordinates in the launcher, then choose Open DWARFLAB.'
