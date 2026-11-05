#!/bin/bash
set -euo pipefail
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
ROOT="$HOME/Library/Application Support/Astro-DWARFLAB-Test"
export ANDROID_HOME="$ROOT/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$ROOT/android"
export ANDROID_AVD_HOME="$ROOT/avd"
export ANDROID_ADB_SERVER_PORT=5047
export ADB_SERVER_SOCKET=tcp:localhost:5047
export JAVA_HOME="$ROOT/java/Contents/Home"
AVD=Astro_DWARFLAB_Test
SERIAL=emulator-5580
PACKAGE=com.convergence.dwarflab
APK_URL=https://tipscope-app-image.oss-cn-hangzhou.aliyuncs.com/apk/dwarf/DWARFLAB.apk
mkdir -p "$ROOT/logs" "$ROOT/cache" "$ANDROID_USER_HOME" "$ANDROID_AVD_HOME"
fail() { echo; echo "ERROR: $*" >&2; exit 1; }
confirm() { local answer; printf '\n%s [y/N]: ' "$*"; read -r answer; case "$answer" in y|Y|yes|YES) ;; *) fail 'Cancelled. You can run this again later.';; esac; }
download() { /usr/bin/curl --fail --location --proto '=https' --proto-redir '=https' --retry 3 --connect-timeout 30 --max-time 3600 "$1" -o "$2.part"; mv "$2.part" "$2"; }
adb() { "$ANDROID_HOME/platform-tools/adb" -P 5047 "$@"; }
device() { adb -s "$SERIAL" "$@"; }
lock() {
  mkdir "$ROOT/operation.lock" 2>/dev/null || fail 'Another Astro operation is running. If a previous run was force-quit, restart your Mac, then remove operation.lock from the Astro support folder.'
  trap 'rmdir "$ROOT/operation.lock" 2>/dev/null || true' EXIT
}
architecture() {
  if [ "$(/usr/sbin/sysctl -in hw.optional.arm64 2>/dev/null || echo 0)" = 1 ]; then
    ABI=arm64-v8a; JARCH=aarch64
  else
    ABI=x86_64; JARCH=x64
  fi
  IMAGE="system-images;android-30;google_apis;$ABI"
}
boot() {
  [ -x "$ANDROID_HOME/emulator/emulator" ] || fail 'Please run Install.command first.'
  "$ANDROID_HOME/emulator/emulator" -accel-check || fail 'Mac hardware acceleration is unavailable. See emulator.log.'
  adb start-server
  local name
  name="$(device emu avd name 2>/dev/null | /usr/bin/head -n 1 | /usr/bin/tr -d '\r' || true)"
  if [ "$name" != "$AVD" ]; then
    if /usr/sbin/lsof -nP -iTCP:5580 -iTCP:5581 -sTCP:LISTEN >/dev/null 2>&1; then
      fail 'Ports 5580/5581 are occupied. Close the other emulator and retry.'
    fi
    /usr/bin/nohup "$ANDROID_HOME/emulator/emulator" -avd "$AVD" -port 5580 -no-window -no-snapshot -gpu auto -no-boot-anim >"$ROOT/logs/emulator.log" 2>&1 </dev/null &
    echo 'Waiting for Android (first boot can take several minutes)...'
  fi
  local i
  i=0
  while [ "$i" -lt 240 ]; do
    if [ "$(device shell getprop sys.boot_completed 2>/dev/null | /usr/bin/tr -d '\r' || true)" = 1 ]; then
      name="$(device emu avd name | /usr/bin/head -n 1 | /usr/bin/tr -d '\r')"
      [ "$name" = "$AVD" ] || fail 'Unexpected Android profile on the reserved port.'
      return
    fi
    sleep 2
    i=$((i + 1))
  done
  fail "Android did not start within 8 minutes. See $ROOT/logs/emulator.log"
}
launch_dwarf() {
  device shell pm path "$PACKAGE" | /usr/bin/grep -q '^package:' || fail 'DWARFLAB is not installed. Run Install.command again.'
  local component
  component="$(device shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "$PACKAGE" | /usr/bin/tr -d '\r' | /usr/bin/tail -n 1)"
  case "$component" in "$PACKAGE/"*) device shell am start -W -n "$component";; *) fail 'DWARFLAB has no launchable activity.';; esac
}
