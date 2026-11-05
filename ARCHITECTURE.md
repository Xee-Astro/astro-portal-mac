# Architecture and source map

Astro Portal is a macOS launcher around a dedicated Android emulator profile. It is not a modified DWARFLAB app, a native telescope driver, or a Docker container.

| File | Responsibility |
| --- | --- |
| `Launcher.js` | Cocoa/JXA main interface, Core Location permission/delegate flow, settings persistence, operation status and minute timer |
| `worker.sh` | Serialized launch/update/sync/stop operations, Android clock/GPS injection, immersive display and scrcpy management |
| `common.sh` | Private SDK paths, processor detection, locks, boot and vendor activity resolution |
| `Install.command` | Guided first installation |
| `Upgrade-Launcher.command` | Existing-profile launcher upgrade |
| `build-launcher.sh` | Creates a stay-open macOS application using built-in `osacompile`, purpose strings, icon and local code signature |
| `install-display.sh` | Downloads/checks official static scrcpy for the Mac architecture |
| `Diagnostics.command` | User-requested diagnostic report |
| `Launch.command`, `Stop.command` | Optional command-file shortcuts |
| `AstroPortal.png`, `AstroPortal.icns` | User-provided artwork and its converted Mac icon |
| `launcher.test.js` | Mocked settings/location logic tests; no claims of native UI coverage |
| `package.py` | Portable verification and installer/source ZIP packaging |

The launcher starts shell operations asynchronously and disables overlapping operation buttons. Workers use a filesystem lock and verify the emulator profile before acting. Runtime files are outside the application bundle, preserving settings during launcher upgrades.

Android 11 Google APIs images are selected as `arm64-v8a` on Apple silicon and `x86_64` on Intel. Android runs headlessly; scrcpy provides display/input. Google Play is not bundled. Location is injected through the emulator's `geo fix` console command in **longitude, latitude, altitude** order. Time and timezone use Android 11's alarm shell interface.

No Android APK, emulator image, Java runtime, scrcpy executable, account, password, saved observing site, or user log is shipped in this repository or release ZIP. Downloads occur on the recipient's Mac.
