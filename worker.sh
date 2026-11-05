#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh
lock
architecture
SETTINGS="$ROOT/settings.json"
field() { /usr/bin/plutil -extract "$1" raw -o - "$SETTINGS" 2>/dev/null; }
assert_device() {
  [ "$(device emu avd name 2>/dev/null | head -n 1 | tr -d '\r' || true)" = "$AVD" ]
}
sync_clock() {
  local tz epoch actual actual_tz
  tz="$(/usr/bin/osascript -l JavaScript -e 'ObjC.import("Foundation"); ObjC.unwrap($.NSTimeZone.localTimeZone.name)')"
  epoch="$(date +%s)"
  device shell settings put global auto_time 0
  device shell settings put global auto_time_zone 0
  device shell cmd alarm set-time "$((epoch * 1000))"
  device shell cmd alarm set-timezone "$tz"
  actual="$(device shell date +%s | tr -d '\r')"
  actual_tz="$(device shell getprop persist.sys.timezone | tr -d '\r')"
  case "$actual" in ''|*[!0-9]*) fail 'Could not verify Android clock.';; esac
  [ "$actual" -ge "$((epoch - 10))" ] && [ "$actual" -le "$(($(date +%s) + 10))" ] || fail 'Android clock differs from the Mac. See the action log.'
  [ "$actual_tz" = "$tz" ] || fail "Android timezone verification failed ($actual_tz versus $tz)."
  echo "Clock synchronized with Mac: $(date '+%Y-%m-%d %H:%M:%S') [$tz]"
}
sync_location() {
  local mode lat lon alt fix_epoch
  mode="$(field locationMode || echo none)"
  case "$mode" in
    manual|mac)
      if [ "$mode" = mac ]; then
        fix_epoch="$(field fixEpoch || echo 0)"
        case "$fix_epoch" in ''|*[!0-9]*) fix_epoch=0;; esac
        if [ "$fix_epoch" -lt "$(($(date +%s) - 120))" ]; then
          echo 'Mac location is stale: clock synchronized, GPS was not refreshed. Request a new Mac fix or use manual coordinates.'
          return
        fi
      fi
      lat="$(field latitude)"; lon="$(field longitude)"; alt="$(field altitude)"
      awk -v a="$lat" -v o="$lon" -v h="$alt" 'BEGIN {n="^-?[0-9]+([.][0-9]+)?([eE][-+]?[0-9]+)?$"; exit !(a~n && o~n && h~n && a>=-90 && a<=90 && o>=-180 && o<=180 && h>=-1000 && h<=100000)}' || fail 'Invalid saved coordinates.'
      lat="$(LC_ALL=C awk -v x="$lat" 'BEGIN {printf "%.8f",x}')"
      lon="$(LC_ALL=C awk -v x="$lon" 'BEGIN {printf "%.8f",x}')"
      alt="$(LC_ALL=C awk -v x="$alt" 'BEGIN {printf "%.2f",x}')"
      device shell settings put secure location_mode 3
      # Only grant location permissions declared by the installed vendor app.
      device shell pm grant "$PACKAGE" android.permission.ACCESS_COARSE_LOCATION || true
      device shell pm grant "$PACKAGE" android.permission.ACCESS_FINE_LOCATION || true
      device emu geo fix "$lon" "$lat" "$alt"
      echo "Saved $mode coordinates sent to Android GPS provider. DWARFLAB must request location to use them."
      ;;
    none) echo 'No location selected. Use the launcher to set observing coordinates.';;
    *) fail 'Unknown location mode.';;
  esac
}
apply_display() {
  if [ "$(field fullscreen || echo false)" = true ]; then
    device shell settings put global policy_control "immersive.full=$PACKAGE"
  else
    device shell settings delete global policy_control
  fi
}
stop_viewer() {
  local pid command
  if [ -f "$ROOT/viewer.pid" ]; then
    pid="$(cat "$ROOT/viewer.pid")"
    case "$pid" in ''|*[!0-9]*) return;; esac
    command="$(ps -p "$pid" -o command= || true)"
    case "$command" in *"$ROOT/scrcpy/scrcpy"*) kill "$pid" 2>/dev/null || true;; esac
    rm -f "$ROOT/viewer.pid"
  fi
}
show_viewer() {
  [ -x "$ROOT/scrcpy/scrcpy" ] || fail 'Fullscreen display component missing. Rerun Install.command.'
  stop_viewer
  local extra=(--serial "$SERIAL" --no-audio --window-title 'Astro Portal — DWARFLAB')
  if [ "$(field fullscreen || echo false)" = true ]; then extra+=(--fullscreen); fi
  export ADB="$ANDROID_HOME/platform-tools/adb"
  export SCRCPY_SERVER_PATH="$ROOT/scrcpy/scrcpy-server"
  nohup "$ROOT/scrcpy/scrcpy" "${extra[@]}" >"$ROOT/logs/display.log" 2>&1 </dev/null &
  echo "$!" >"$ROOT/viewer.pid"
  sleep 2
  kill -0 "$(cat "$ROOT/viewer.pid")" 2>/dev/null || fail "The display closed unexpectedly. See $ROOT/logs/display.log"
  echo 'DWARFLAB display opened. Option+f toggles fullscreen; use Command+Tab to return to Astro Portal.'
}
case "${1:-}" in
  launch|apply)
    boot; sync_clock; sync_location; apply_display; launch_dwarf; show_viewer;;
  sync)
    if assert_device; then sync_clock; sync_location; apply_display; else echo 'Settings saved. They will be applied next time Android starts.'; fi;;
  update)
    echo 'Downloading DWARFLAB from the official vendor link...'
    download "$APK_URL" "$ROOT/cache/DWARFLAB.apk"
    unzip -tq "$ROOT/cache/DWARFLAB.apk" >/dev/null || fail 'Invalid APK download.'
    unzip -Z1 "$ROOT/cache/DWARFLAB.apk" | grep "^lib/$ABI/" >/dev/null || fail 'APK does not support this Mac architecture.'
    boot
    device shell am force-stop "$PACKAGE"
    device install -r "$ROOT/cache/DWARFLAB.apk"
    rm -f "$ROOT/cache/DWARFLAB.apk"
    sync_clock; sync_location; apply_display; launch_dwarf; show_viewer
    echo 'DWARFLAB update installed. Existing app data was retained.';;
  stop)
    stop_viewer
    if assert_device; then device emu kill; else echo 'Astro Android is not running.'; fi;;
  *) fail 'Unknown launcher operation.';;
esac
