#!/bin/bash
set -euo pipefail
APP="$HOME/Applications/Astro Portal.app"
if [ ! -d "$APP" ]; then
  echo 'Run Install.command (or Upgrade-Launcher.command for an existing installation) first.'
  printf '\nPress Return to close...'; read -r _; exit 1
fi
exec /usr/bin/open "$APP"
