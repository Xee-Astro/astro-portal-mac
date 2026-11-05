# Third-party notices and official references

Astro Portal is an independent launcher. The installer downloads third-party components directly on the recipient's Mac; those executables, APKs and system images are not redistributed in this repository or release ZIPs. Existing upstream notices and license files in downloaded archives are retained.

| Component | Owner/project and terms | Official source |
| --- | --- | --- |
| DWARFLAB Android app | DWARFLAB; proprietary vendor application, subject to its own terms | [Vendor download page](https://www.dwarflab.com/pages/dwarflab-app-firmware-download), [Google Play listing](https://play.google.com/store/apps/details?id=com.convergence.dwarflab) |
| Android tools, emulator and Google APIs image | Google and Android contributors; Google SDK license and applicable component open-source notices | [SDK agreement/downloads](https://developer.android.com/studio/terms), [installation requirements](https://developer.android.com/studio/install), [official repository metadata](https://dl.google.com/android/repository/repository2-1.xml) |
| Eclipse Temurin Java 21 | Eclipse Adoptium/OpenJDK contributors; GPL v2 with Classpath Exception and included notices | [Adoptium licensing FAQ](https://adoptium.net/docs/faq), [Temurin 21 source/build project](https://github.com/adoptium/temurin21-binaries) |
| scrcpy 5.0.1 | Genymobile and contributors; Apache License 2.0 for scrcpy, with separate upstream dependency terms | [Pinned release](https://github.com/Genymobile/scrcpy/releases/tag/v5.0.1), [source license](https://github.com/Genymobile/scrcpy/blob/v5.0.1/LICENSE), [Mac install/checksums](https://github.com/Genymobile/scrcpy/blob/v5.0.1/doc/macos.md) |
| macOS Cocoa, Core Location, scripting and signing tools | Apple platform frameworks supplied with macOS; not redistributed by Astro Portal | [Core Location](https://developer.apple.com/documentation/corelocation), [Mac app opening guidance](https://support.apple.com/102445) |

The installer uses the vendor APK URL linked by DWARFLAB's site:
`https://tipscope-app-image.oss-cn-hangzhou.aliyuncs.com/apk/dwarf/DWARFLAB.apk`.
This identifies a download source and does not grant rights to modify or redistribute the vendor app.

scrcpy archives retain their `LICENSE` and other included files. Dependencies in upstream static builds have their own terms; the release/source links above are authoritative for that distribution. Astro Portal does not claim to relicense them. Java's included legal notices and the SDK license files remain in the local installation. Users review the SDK agreement themselves; the installer does not auto-accept it.

## Documentation references

- [Android emulator console and GPS injection](https://developer.android.com/studio/run/emulator-console)
- [Android emulator command-line options](https://developer.android.com/studio/run/emulator-commandline)
- [Android 11 alarm/time command implementation](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/android11-release/services/core/java/com/android/server/AlarmManagerService.java)
- [scrcpy fullscreen/window controls](https://github.com/Genymobile/scrcpy/blob/v5.0.1/doc/window.md)
- [scrcpy keyboard shortcuts](https://github.com/Genymobile/scrcpy/blob/v5.0.1/doc/shortcuts.md)

## Names and artwork

DWARFLAB, Android, Eclipse Temurin and scrcpy identify their respective products/projects. Mac and macOS are trademarks of Apple Inc. Their names are used to describe compatibility or dependencies; no sponsorship or endorsement is claimed.

The Astro Portal icon is supplied by the project owner and used at the owner's request. It includes a design whose resemblance to Apple's logo was raised before publication. The owner elected to retain it. No Apple trademark licence has been supplied or is claimed. See [Apple's trademark/copyright guidelines](https://www.apple.com/legal/intellectual-property/guidelinesfor3rdparties.html).

This source/notice review identifies dependencies and an unresolved artwork trademark concern. It is not a comprehensive legal clearance, title search, or guarantee against copyright/trademark claims. Attribution alone does not create permission to use someone else's protected work.
