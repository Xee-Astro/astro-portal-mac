# Validation status — version 1.1

## Recorded checks

- Bash grammar checks for all shell and `.command` files.
- JavaScript syntax check for the launcher.
- Mocked macOS API tests for settings persistence and owner-only file mode.
- Coordinate bounds/format validation, valid zero coordinates and denial handling.
- Rejection of stale operating-system location fixes and forwarding of fresh fixes.
- Decoding of the supplied `.icns` asset.
- ZIP integrity and executable permission metadata.
- Official scrcpy release archive layout and SHA-256 metadata inspected for both Mac CPU families.
- Official vendor APK ZIP index inspected on 2026-11-02: ARM64, ARMv7, x86 and x86-64 native libraries were present at that time.

`Verification.json` records these checks. They were run on Windows and are not a macOS runtime certification.

## Still to verify on a Mac

1. Fresh installation on Apple silicon and Intel, including SDK licenses and native bundle compilation.
2. Launcher layout, double-click/Dock activation and persistent settings after quitting.
3. Real macOS permission grant/denial, approximate/absent location and timeout behavior.
4. Observing coordinates as actually read by Android and DWARFLAB.
5. Clock/timezone updates, daylight-saving behavior and Mac sleep/resume.
6. Fullscreen/windowed display, mouse/keyboard input and stopping/reopening Android.
7. Vendor app update, signature rejection, data retention and download failures.
8. Telescope pairing/discovery, live view, capture, guiding, movement and firmware behavior.

No physical equipment or phone GPS validation is claimed. Renaming the release to 1.1 does not change those limits.

## Reporting results

Use the repository's issue tracker. Include Mac model/chip, macOS version, telescope model/firmware, failed operation and error text. Review/redact coordinates, personal paths and other private data before attaching logs. Do not publish passwords or app-account data.
