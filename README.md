# Indian Music for iPhone

Private native SwiftUI app, built with GitHub Actions and installed using SideStore.
Requires **iOS 16 or later**. Current version: **0.3.1 — tanpura prototype**.

## Current features

Acoustic Pa/Ma tanpura, all 12 Sa keys in two registers, one-cent fine tuning,
independent speed and volume, saved settings, background playback and lock-screen
play/pause controls. No accounts or backend. The samples are bundled for offline use.

Harmonium, tabla, microphone tuner and the recording library are planned later.

## Build and install

Push app changes to `main`, or open **Actions → Build unsigned iPhone IPA → Run
workflow**. The workflow runs native audio/settings checks, builds and validates an
unsigned arm64 iPhoneOS app, and tests installation/launch in an iPhone simulator.
It uses the `macos-15` runner's available Xcode and logs the exact version.
No Apple signing credentials are required in GitHub.

1. On iPhone, sign in to GitHub in Safari and open the latest successful build run.
2. Under **Artifacts**, download **IndianMusic-unsigned-IPA**. Request the desktop
   website if needed to see artifacts.
3. Open **Files → Downloads**, tap the downloaded ZIP and locate
   `IndianMusic-unsigned.ipa` in the extracted folder. Do not unzip the IPA itself.
4. Connect to Wi-Fi, enable LocalDevVPN and open **SideStore → My Apps → +**.
5. Select the IPA and wait for signing/installation. Install over the existing app
   to preserve settings. Open **Indian Music**, then tap **Play tanpura**.

If SideStore is not installed, follow its current [prerequisites](https://docs.sidestore.io/docs/installation/prerequisites)
and [installation guide](https://docs.sidestore.io/docs/installation/install).
Initial setup supports Windows/Linux. Enable Developer Mode and trust the developer
profile if requested. Free Apple accounts normally require refreshing within seven
days and allow three active apps including SideStore. Build artifacts expire in
30 days; rebuild if necessary.

## Documentation and validation

- [Phase 3 implementation, sources, tests and phone checklist](docs/PHASE3.md)
- [Phase 2 measured findings and limitations](feasibility/RESULTS.md)
- [Bundled sample provenance](IndianMusic/Sounds/tanpura-sources.json)

CI tests do not replace listening or background playback checks on the physical
phone. Tanpura previews are CC BY 4.0 recordings by Sankalp Gulati; attribution and
license links appear in the app's Sound credits. The Pa loop excludes the speech
reported at the end of its original recording.
