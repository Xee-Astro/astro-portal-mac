# Development and packaging

All launcher/installer source is in this repository root. It can be inspected without proprietary build tools.

## Checks and release ZIPs

For development use Python 3.10+ and Node.js 18+:

```sh
python -m pip install -r requirements-dev.txt
python package.py
```

The command validates Bash grammar, JavaScript syntax, mocked settings/location tests, the icon and expected bundle settings. It writes `dist/Astro-Portal-1.1-macOS.zip`, `dist/Astro-Portal-Source-1.1.zip`, a verification report and SHA-256 checksums. Unix executable permissions are included in ZIP metadata.

These checks do not execute Cocoa or Android. On a Mac, also run:

```sh
ASTRO_NO_REVEAL=1 /bin/bash build-launcher.sh
```

This compiles and checks the local app bundle without downloading or launching Android. Actual UI, permissions and equipment checks are listed in [VALIDATION.md](VALIDATION.md).

## Versions and compatibility

`VERSION` identifies the public release. The bundle short version is `1.1` and numeric bundle version `1.1.0`. Preserve the legacy profile, support directory and marker names unless a real data migration is implemented.

The DWARFLAB APK URL and Google stable emulator are rolling upstream dependencies. Installer checksum pins cover Android command-line tools 19.0 and scrcpy 5.0.1. Adoptium publishes the current Java archive checksum. A future vendor download can change compatibility independently of this release.

Do not commit runtime profiles, downloaded APKs/images, settings or logs. Project licensing status is described in [RIGHTS.md](RIGHTS.md); third-party sources and notices are listed separately.
