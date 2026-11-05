#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
source ./common.sh
architecture
if [ -x "$ROOT/scrcpy/scrcpy" ] && [ -f "$ROOT/scrcpy/version-5.0.1" ]; then exit 0; fi
if [ "$ABI" = arm64-v8a ]; then
  asset=scrcpy-macos-aarch64-v5.0.1
  checksum=33611e51977a8289e2e124b220f727895181ef2eb9060e0987a4dc2db9cf0d6b
else
  asset=scrcpy-macos-x86_64-v5.0.1
  checksum=31a5467a9e907f162b093267cbbab1276b15c6e709c2ea8159566a8d165beb50
fi
download "https://github.com/Genymobile/scrcpy/releases/download/v5.0.1/$asset.tar.gz" "$ROOT/cache/display.tar.gz"
actual="$(shasum -a 256 "$ROOT/cache/display.tar.gz" | awk '{print $1}')"
[ "$actual" = "$checksum" ] || fail 'Display component checksum mismatch.'
mkdir -p "$ROOT/scrcpy"
tar -xzf "$ROOT/cache/display.tar.gz" --strip-components 1 -C "$ROOT/scrcpy"
[ -x "$ROOT/scrcpy/scrcpy" ] && [ -f "$ROOT/scrcpy/scrcpy-server" ] || fail 'Incomplete display component archive.'
touch "$ROOT/scrcpy/version-5.0.1"
rm -f "$ROOT/cache/display.tar.gz"
