# User guide

## Observing location

Enter decimal **latitude**, **longitude** and **altitude in metres**, then choose **Save & use manual coordinates**. Negative latitude means south; negative longitude means west. Latitude accepts −90 to 90 and longitude −180 to 180, including zero. Saved coordinates persist across launcher and Android restarts.

**Use Mac location** requests permission through macOS Location Services. The launcher shows the last fix and reported accuracy. Mac location may be approximate, unavailable offline, or affected by Wi-Fi availability. On denial or timeout, enter manual coordinates or allow Astro Portal in macOS Location Services.

Settings are saved as `settings.json` in the private support directory with owner-only file permissions. If Android is running, coordinates are applied immediately; otherwise they are applied at launch. In Mac mode, the launcher requests a fresh fix before launch/update and once per minute during an active session. Fixes older than two minutes are not resent. Phone GPS forwarding is not included.

Coordinates go to the **Android emulator GPS provider**. The vendor app must request Android location to consume them. This does not directly edit DWARFLAB's private configuration or establish the telescope's eventual use of the coordinates. Confirm the displayed observing site before telescope operation.

## Date, time and timezone

The launcher displays the Mac's clock and IANA timezone. At startup and synchronization it copies Unix time and the Mac timezone into Android, disables competing Android network time/timezone, and checks the result. A live session refreshes once per minute while the launcher remains open. If Mac location fails, clock refresh can continue independently.

After quitting the launcher, Android's clock keeps ticking, but no new location or timezone updates are forwarded until the launcher opens again.

## Fullscreen

**Open DWARFLAB fullscreen** is enabled by default. The choice persists. A dedicated scrcpy display opens with Android system bars hidden for the vendor app. **Option+f** toggles display fullscreen; **Command+Tab** returns to the launcher. Uncheck the option for a normal resizable window. The app's aspect ratio is preserved, so some screens may have margins.

Closing the display window does not stop Android. Use **Stop Android** to shut down the environment. An emulator window left by an older installation closes after that environment is stopped/restarted.

## Updating the Android app

Finish any capture before selecting **Update DWARFLAB app**. The launcher asks for confirmation, downloads the vendor APK, checks archive/CPU compatibility, closes the app and runs a normal Android update. Android validates signatures and rejects incompatible updates or downgrades. No reset or forced downgrade is used. Existing app data is retained by the normal update process.

This updates DWARFLAB only, not Astro Portal, Android or telescope firmware.

## Connecting equipment

Initial pairing/provisioning may require the official app on a phone. If supported by the telescope model, configure it on a shared local network, connect the Mac to that network and try the telescope's manual IP address if the app offers it. Connecting the Mac to the telescope's Wi-Fi can also be tried after setup downloads finish.

Bluetooth passthrough, Wi-Fi provisioning, broadcast discovery, live capture, guiding, motion and firmware operations remain unverified. Start with connection and live-view checks; do not use firmware updates or unattended movement as initial validation.
