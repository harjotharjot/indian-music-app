# Phase 3 — shared audio engine and tanpura

Version **0.3.1 (4)**. Native SwiftUI, iOS 16+, no third-party runtime dependencies.
The existing bundle identifier is unchanged, so SideStore can install this as an
update. Harmonium, tabla, microphone tuning and the recording library are not
implemented in this phase.

## Implemented

- One AVAudioEngine owned by the audio coordinator through `TanpuraGraph`, with a
  dedicated tanpura mixer bus feeding the main mixer. Future sources can connect
  to separate buses within this engine rather than creating competing sessions.
- Two bundled acoustic recordings, played by native AVAudioPlayerNode looping
  buffers through individual AVAudioUnitTimePitch nodes. Switching Pa/Ma crossfades
  gains over 120 ms; both patterns remain scheduled. No UI timer schedules audio.
- All 12 chromatic Sa keys in registers 2 and 3, ±100 cents in individual-cent
  steps, speed 0.75–1.25× independent of target pitch, and tanpura volume.
- Saved settings, short start/stop gain ramps, `.playback` audio session,
  `UIBackgroundModes = audio`, and lock-screen play/pause commands.
- Interruption handling, engine-configuration/media-service recovery, and stopping
  on headphone disconnection. Actual route/interruption behavior needs phone tests.

Both native TimePitch nodes process audio while playing, including the muted
pattern. This makes pattern switches continuous, but phone CPU/battery cost is
not yet measured. The coordinator serializes graph changes on the main actor;
no file IO, SwiftUI work or analysis runs in an audio render callback.

## Sample preparation and limits

[Bundled provenance and measurements](../IndianMusic/Sounds/tanpura-sources.json)
record creators, CC BY 4.0 source links, hashes and modifications. In-app Sound
credits include attribution, license and source links. Bundled WAVs are derived
from the Phase 2 MP3 previews; decoding them does not restore lossless quality.

- Pa uses the previously trimmed recording, with the user-reported speech removed.
  Only source seconds 2–26 are used, well before the reported speech region.
- Ma uses source seconds **16–40**, excluding user-reported speech at seconds
  **5–13**, with a three-second margin after that interval. Each excerpt is rotated after its first two
  seconds and the tail is crossfaded with the head using FFmpeg's `acrossfade`.
  Resulting buffers are **22 seconds**, stereo 48-kHz PCM16, peak normalized to
  -6 dBFS for mixing headroom. They remain acoustic recordings with overlapping
  strings; speed adjusts the complete recorded cycle, not isolated string gestures.
- Source Sa is approximately calibrated with the existing aubio YINFAST detector,
  confidence >=0.9, around the creator's documented 138-Hz reference. Octaves are
  folded only for this offline source-calibration task; candidates farther than
  100 cents from that reference are excluded. This is not the live tuner.
- Estimated Sa: Pa **138.7726 Hz**, Ma **138.9065 Hz**. The metadata retains the
  supporting frame count and 10th–90th-percentile spread. These are mixed-string
  estimates, not calibrated ground truth. Individual strings beat and drift.
- The displayed target Hz and one-cent controls are mathematically precise; this
  does not establish one-cent absolute tuning of every recorded string. Large
  transpositions can alter timbre. Final authenticity and loop joins need listening.

Reproduce sample preparation with the Phase 2 Python environment and FFmpeg:

```sh
python feasibility/fetch_samples.py
# The committed trimmed Pa WAV is the Pa input.
python scripts/prepare-tanpura.py
```

## Automated validation

The IPA workflow runs `scripts/test-phase3.sh` before building:

1. Native Swift settings tests verify reference frequencies, the one-cent ratio,
   all 12 keys in two registers, pitch-shift bounds, Codable persistence and clamping.
2. The same `TanpuraGraph` used by the app is rendered offline for **60 seconds per
   pattern**, at 0.75× / 1.25× speed with +37 cents. Checks require finite,
   non-clipping, non-silent blocks across repeated joins and audio after restart.
   These tests do not certify perceived smoothness or precise live tuning.
3. Asset preparation checks duration, hashes and boundary step relative to ordinary
   adjacent-sample steps. No speech classifier or human listening panel was used.
4. Packaging checks the arm64 iPhoneOS executable, app metadata, both bundled sounds,
   background-audio declaration and IPA layout.
5. The app builds for an available iPhone simulator, installs, launches and produces
   a screenshot. This is a launch check, not a simulator audio interaction test.

`Phase3-tests` contains native render reports, simulator metadata/build log and a
launch screenshot. The IPA remains the separate `IndianMusic-unsigned-IPA` artifact.

## Try on the iPhone

Download the successful build's IPA artifact in Safari while signed in to GitHub.
Unzip it in Files, then use **SideStore → My Apps → +** to select the IPA. Install
as an update; do not uninstall the old app first. SideStore's normal signing and
refresh rules still apply.

- Open Indian Music and tap **Play tanpura**. Listen to Pa and Ma for at least a
  minute each, covering multiple joins. Check for speech, clicks, obvious changes
  in ambience or an unnatural recurring swell.
- Change key/register and fine tuning. Compare against a physical reference if
  available. Change speed and check whether the note remains stable.
- Pause, replay and rapidly switch patterns. Relaunch and confirm saved settings.
- Lock the screen for two minutes and test lock-screen pause/play. A longer
  30-minute playback check is still required for background reliability.
- If convenient, test headphone disconnection and a phone-call interruption.
  Unplugging headphones should stop playback rather than resume through the speaker.

No iPhone sound-quality, route-change, latency, battery or thermal result is claimed
from CI. Report any speech or bad joins with the pattern and approximate time.
Further instruments should follow evaluation of this tanpura build.

## Recorded validation

[v0.3.0 baseline test measurements](phase3-validation.txt) and
[simulator launch screenshot](phase3-iphone.png) are saved with the source.
A top-level `Resources` directory interfered with iOS's bundle lookup during
simulator testing; samples now live in `Sounds`, and packaging checks reject the
reserved top-level name. Device output stays unsigned; simulator builds use an
ad-hoc signature. No Apple signing credentials were added to CI.

Historical v0.3.0 source verification run:
https://github.com/harjotharjot/indian-music-app/actions/runs/42527095445

The v0.3.0 IPA is superseded because its Ma loop includes the reported speech.

## v0.3.1 Ma speech correction

The user identified speech at seconds 5–13 in the original Ma preview. v0.3.0's
2–26-second excerpt included it. The Ma loop and its reference pitch are now
regenerated from seconds 16–40. The Pa WAV is byte-for-byte unchanged. Source
metadata records exclusion intervals; packaging verifies hashes and rejects
excerpts that overlap known speech. This excludes the reported speech, but does
not constitute independent listening approval of the new section.

The v0.3.1 [verification run passed](https://github.com/harjotharjot/indian-music-app/actions/runs/42528690224):
native tuning tests, both 60-second loop renders and restart checks, sample hash
and source-exclusion checks, unsigned arm64 IPA packaging, and simulator install/launch.
Ma's minimum rendered block RMS was 0.02843 and peak 0.38155 at 1.25× / +37 cents;
no silent blocks, nonfinite samples or clipping were found. These are numerical
checks, not a listening confirmation.

[Download the corrected v0.3.1 IPA](https://github.com/harjotharjot/indian-music-app/actions/runs/42528690224/artifacts/13636398069)
(GitHub sign-in required). Install as an update using SideStore.
