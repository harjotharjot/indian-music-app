# Indian Music for iPhone

Private native SwiftUI app built with GitHub Actions and installed with SideStore.
Requires **iOS 16+**. Current version: **0.4.3 — sampled harmonium and tanpura**.

## Features

- Recorded harmonium, multitouch chords, continuous C2–C5 keyboard navigation and enlarged black-key touch regions.
- Portrait and landscape layouts; instrument switcher follows the charging-port edge.
- All 12 Sa references, optional sargam and shared one-cent fine tuning.
- User-supplied C-scale Pa/Ma tanpuras, independent speed and volume, saved settings,
  background playback and lock-screen transport.
- Independent instrument volumes in one native audio engine, with separate dry buses
  reserved for future recording. Recording and microphone access are not implemented.

Tap **Enable harmonium** before playing. Piano pitches remain fixed; Sa changes
reference labels and the drone, while cents fine tuning shifts both instruments.

## Build and install

App/source changes on `main` automatically run **Build unsigned iPhone IPA**.
The workflow tests native audio and pitch, builds an unsigned arm64 device IPA,
checks asset hashes, then installs/launches a simulator build and tests both screens
in portrait and both landscape directions. It uses an available
Xcode on `macos-15`; no Apple signing credentials are stored in CI.

1. On iPhone, sign in to GitHub in Safari and open the successful build run.
2. Download **IndianMusic-unsigned-IPA** under Artifacts.
3. Extract the downloaded ZIP in Files; leave `IndianMusic-unsigned.ipa` intact.
4. Connect to Wi-Fi, enable LocalDevVPN, then select the IPA using
   **SideStore → My Apps → +**. Install over the existing app to preserve settings.

See SideStore's current [installation guide](https://docs.sidestore.io/docs/installation/install)
if initial setup is needed; Windows/Linux can do it. Free-account refresh rules
still apply. Artifacts expire after 30 days and can be rebuilt via Run workflow.

[F♯ correction, midpoint hit regions, full screen and iPhone checklist](docs/PHASE43.md) · [Phase 4 architecture and sources](docs/PHASE4.md)

Historical research: [Phase 2](feasibility/RESULTS.md), [Phase 3](docs/PHASE3.md).
Phase 3 passed the user's phone tests. Phase 4 performance and sound quality still
need real-iPhone testing. No tabla, microphone tuner, recording or library features
are included in this phase.
