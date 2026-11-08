# Indian Music — Phase 1

Minimal native SwiftUI iPhone app for verifying compilation, SideStore installation,
and launch. Requires **iOS 16.0 or later**. No dependencies or audio features.

## Build

Push to `main`, or open **Actions → Build unsigned iPhone IPA → Run workflow**.
The workflow uses `macos-15` and its installed default Xcode, recording the exact
Xcode and SDK versions. No signing secrets are needed.

It builds Release for arm64 with the device iPhoneOS SDK and signing disabled.
It checks application metadata, executable architecture and Mach-O iOS platform
(not simulator), then packages `Payload/IndianMusic.app` into an IPA.
The artifact includes the IPA, a SHA-256 checksum and a validation report.
SideStore supplies signing/provisioning. Tapping the unsigned IPA directly cannot
install it. The physical-device launch check remains a manual acceptance step.

## Download on iPhone

1. In Safari, sign in to GitHub and open this repository's **Actions** tab.
2. Open the latest successful **Build unsigned iPhone IPA** run for `main`.
3. Under **Artifacts**, tap **IndianMusic-unsigned-IPA** to download the ZIP.
   Use Safari's **Request Desktop Website** if the artifacts section is hidden.
4. Open **Files → Browse → Downloads** under iCloud Drive or On My iPhone,
   depending on Safari's download setting. Tap the ZIP to extract it.
5. Locate `IndianMusic-unsigned.ipa` inside the extracted folder. Do not unzip
   or rename the IPA itself. Artifacts expire after 30 days; rebuild if needed.

## Install with SideStore

If needed, first follow the official [prerequisites](https://docs.sidestore.io/docs/installation/prerequisites)
and [installation guide](https://docs.sidestore.io/docs/installation/install).
Initial setup supports Windows/Linux using a USB cable and iloader; no Mac is
needed. Use the VPN named in the current guide (currently LocalDevVPN).
Enable **Settings → Privacy & Security → Developer Mode** if required and trust
your profile under **Settings → General → VPN & Device Management**.

With SideStore already working:

1. Connect to Wi-Fi and turn on LocalDevVPN.
2. Open **SideStore → My Apps → +**.
3. Select `IndianMusic-unsigned.ipa` from the extracted folder in Files.
4. Wait for SideStore to sign and install it; a free active-app slot is required.
5. Open **Indian Music** from the Home Screen or App Library.
6. Confirm the green checkmark, **The app installed and opened successfully.**,
   and **Phase 1 · Version 0.1.0**.
7. Tap **Test button: 0** and check that the number increases. Close and reopen
   the app. The counter intentionally resets when the app process restarts.

Free Apple accounts normally require refreshing within seven days and allow three
active apps including SideStore. Signing/refresh need connectivity; this app runs
offline after installation. Keep the bundle identifier stable for future updates.
Report installation errors exactly as displayed.

**Wait for confirmation of successful installation and launch before Phase 2.**
