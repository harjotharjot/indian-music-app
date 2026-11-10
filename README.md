# Indian Music for iPhone

Private native SwiftUI app built with GitHub Actions and installed with SideStore.
Requires **iOS 16+**. Current iPhone audition build: **0.5.1 (11) — harmonium, tanpura and tabla**.
[Download the unsigned IPA; changes, audio comparisons, screenshots and validation status](docs/PHASE51.md).

## Features

- Recorded harmonium, multitouch chords, continuous C2–C5 keyboard navigation and enlarged black-key touch regions.
- Six recorded tabla thekas: Dadra, Rupak, Keherwa, Teentaal, Ektaal and Jhaptal;
  independent Start/Pause/Resume/Stop, BPM, volume, matra and sam.
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

[Phase 5 samples, thekas, audio demos and iPhone checklist](docs/PHASE5.md) · [Accepted portrait/rotation correction](docs/PHASE44.md) · [F♯ correction and midpoint hit regions](docs/PHASE43.md) · [Phase 4 architecture and sources](docs/PHASE4.md)

Historical research: [Phase 2](feasibility/RESULTS.md), [Phase 3](docs/PHASE3.md).
Phase 4 v0.4.4 (9) passed the user's real-iPhone tests. Phase 5 tabla is an
audition build pending device and musical approval. No microphone tuner,
recording library, pitch shifter or multitrack recording is implemented.
