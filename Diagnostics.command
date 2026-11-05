#!/bin/bash
cd "$(dirname "$0")"
source ./common.sh
OUT="$HOME/Desktop/Astro-DWARFLAB-Diagnostics-$(date +%Y%m%d-%H%M%S).txt"
{
  echo 'Astro Portal Mac 1.1'; date; sw_vers; uname -m
  architecture; echo "Selected image: $IMAGE"
  "$ANDROID_HOME/emulator/emulator" -version || true
  "$ANDROID_HOME/emulator/emulator" -accel-check || true
  adb devices -l || true
  device shell getprop ro.product.cpu.abi || true
  device shell dumpsys package "$PACKAGE" | grep -E 'versionName|versionCode|primaryCpuAbi' || true
  echo '--- Emulator log (last 100 lines) ---'
  tail -n 100 "$ROOT/logs/emulator.log" || true
} >"$OUT" 2>&1
echo "Saved $OUT"
open -R "$OUT"
printf '\nReview the report before sharing. Press Return to close...'; read -r _
