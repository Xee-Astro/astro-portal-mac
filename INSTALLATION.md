# Installation

## Fresh installation

Download [Astro-Portal-1.1-macOS.zip](https://github.com/Xee-Astro/astro-portal-mac/releases/download/v1.1/Astro-Portal-1.1-macOS.zip), extract it, and run `Install.command`. Do not move individual files out of the extracted folder before setup finishes.

Setup asks before downloading a private Java runtime, Android tools and image, scrcpy display, and the original DWARFLAB APK. Review Google's SDK license prompts yourself. Downloads come from official project/vendor sources listed in [THIRD-PARTY.md](THIRD-PARTY.md). No existing Windows data is transferred.

Allow several GB of downloads and up to eight minutes for Android's first boot. Setup checks for 12 GB free, creates a fresh 4 GB Android app-data partition, and removes temporary download archives after successful use. Actual disk usage has not been measured on a Mac.

Open `~/Applications/Astro Portal.app` after setup; drag it to the Dock if desired. The main launcher provides location and display controls. Daily use does not open Terminal.

## Earlier Astro installation

Stop Android and quit the old launcher. Extract the new package and run `Upgrade-Launcher.command`. It installs the graphical launcher and display component without wiping the existing Android profile. Existing data partitions retain their old size. Use the new **Astro Portal.app** afterward; the old **Astro - DWARFLAB.app** is obsolete.

This upgrade path targets the earlier package from this project. It is not a general importer for unrelated Android installations.

## macOS first-open checks

The generated app is locally ad-hoc signed and checked with `codesign`; it has no Developer ID signature or notarization. If macOS blocks a file, review its source and use Apple's **Open Anyway** option under **System Settings → Privacy & Security** if you trust it. Do not disable Gatekeeper.

If a `.command` file lost executable permission, open Terminal, type `/bin/bash` followed by a space, drag the command file into Terminal, and press Return. See [Apple's guidance on opening Mac apps](https://support.apple.com/102445).

## Data and ports

- App: `~/Applications/Astro Portal.app`
- Settings, Android profile and downloads: `~/Library/Application Support/Astro-DWARFLAB-Test`
- Private local ADB server: port `5047`
- Emulator: ports `5580/5581`

The legacy support-directory/profile names intentionally remain unchanged so upgrades retain data. One instance is supported. If the reserved emulator ports are occupied, setup stops instead of attaching to an unrelated Android profile.

## Troubleshooting

Use **View logs** in the launcher. `last-action.log` covers the most recent operation; `emulator.log` and `display.log` cover startup/display. `Diagnostics.command` saves a report on the Desktop. Review logs before sharing because they may include observing coordinates and personal filesystem paths.

If a force-quit leaves a stale lock, quit the launcher, restart the Mac, then remove only the empty `operation.lock` directory inside the support folder above. Retry afterward.

## Uninstall

Use **Stop Android**, quit Astro Portal, and move its app to Trash. To delete this project's Android apps, observing coordinates and saved data, also move its support folder to Trash. Emptying Trash permanently erases those data. Other Android profiles are not removed.
