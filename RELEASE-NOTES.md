# Astro Portal 1.1 — for macOS

Run the original DWARFLAB Android app through a dedicated Android environment with a graphical Astro Portal launcher.

## Downloads

- **Astro-Portal-1.1-macOS.zip** — online installer and upgrade files; extract and run `Install.command`.
- **Astro-Portal-Source-1.1.zip** — complete launcher, installer, tests, packaging source and documentation.
- **SHA256SUMS.txt** — download checksums.
- **Verification.json** — recorded source/package checks and validation limits.

Existing users: stop Android, quit the launcher and run `Upgrade-Launcher.command` from the extracted package. Then double-click **Astro Portal.app** in your home Applications folder.

## Included features

Saved manual coordinates and Mac location forwarding; date/time/timezone sync; fullscreen preference; vendor DWARFLAB update button; original vendor APK; Apple silicon/Intel detection.

## Prerequisites and status

macOS 12+ launcher target (Google emulator may require newer), hardware virtualization, 16 GB RAM recommended, 12 GB free for initial setup and internet access for downloads/updates. No Xcode, Homebrew or Android Studio required. The generated application is locally ad-hoc signed and is not Apple-notarized.

Windows source/package checks and mocked location tests passed. Native Mac execution, real permission flows, Android provisioning/display and physical telescope control remain unverified. **Version 1.1 is a release identifier, not a claim of hardware validation.**

Independent project; no vendor affiliation or endorsement. Third-party binaries are downloaded upstream rather than bundled. See the repository's [README](https://github.com/Xee-Astro/astro-portal-mac#readme), [installation guide](https://github.com/Xee-Astro/astro-portal-mac/blob/main/INSTALLATION.md), [validation status](https://github.com/Xee-Astro/astro-portal-mac/blob/main/VALIDATION.md), and [third-party notices](https://github.com/Xee-Astro/astro-portal-mac/blob/main/THIRD-PARTY.md).
