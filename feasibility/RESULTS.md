# Phase 2 findings

Measured on Linux and GitHub's macOS 15 arm64 runner (Xcode 16.4, SDK 18.5).
The iPhone app has not changed. The user confirmed Phase 1 installation and launch;
no phone audio test is claimed here.

## Passed

- Downloaded and decoded 24 attributed files, about 10 MB: seven harmonium WAVs,
  13 tabla WAVs, two acoustic tanpura previews and two singing previews.
  No decoded sample reached the audit's 0.999-full-scale clipping threshold.
  This is not a guarantee of no earlier source clipping or compression artifacts.
- Six Linux automated tests passed: checksum integrity, decoding, known-frequency
  YIN accuracy, silence rejection, octave-metric behavior and YINFAST confidence
  rejection. CI repeats these tests on macOS.
- Five detector configurations were run against 52 synthetic cases and nine real
  harmonium/voice excerpts. For the 48 steady synthetic cases, YIN and YINFAST
  had 100% coverage, no octave errors, and worst clip p95 error below 1.43 cents
  on both platforms. This result does not establish real-singing accuracy.
- A separate upstream aubio revision cross-compiled successfully to an arm64 iOS
  static library (upstream minimum 16.4). Apple harness APIs type-checked for iOS 16.
- 112 offline pitch-shift renders completed: seven inputs × eight shifts × two
  engines, using Apple TimePitch and Rubber Band **4.0.0 R3**. All outputs were
  finite and non-silent. On the 220-Hz sine fixture, both engines had 100% voiced
  coverage and worst median pitch error below 0.04 cents across tested shifts.
  Shifted reed-like fixtures also stayed below 0.04 cents median error.
- Rubber Band output duration matched input within the 30-ms acceptance bound.
  Apple was run at rate=1 with an intentional extra second of rendering to inspect
  tails. The coarse active-span duration changed by at most 20 ms for either engine.
  Do not infer sample-exact preservation or phone latency from this diagnostic.

## Failures and tradeoffs found

- Default aubio YINFFT was unreliable at the low end with this 4096-frame setup.
  On the real C2 excerpt, its median estimate was about 130.85 Hz versus YIN's
  65.42 Hz. Other configurations and window lengths were not exhaustively tuned.
- YIN/YINFAST reported false pitches in **37.3%** of measured noise-only frames.
  Using aubio's existing confidence >=0.9 reduced this to **0%** in the seeded
  noise test, preserving steady-fixture coverage. Male reverberant-voice coverage
  fell from **95.2% to 83.8%**; the threshold needs real-device validation.
- Vibrato is harder: YIN/YINFAST median instantaneous-F0 error was about **8.9
  cents**, including window/response lag. Steady-tone results cannot be generalized
  to meend or vibrato.
- pYIN rejected the tested noise but uses 10-cent quantization here. It is an
  offline comparison, not a proven iOS or sub-cent solution.
- Legacy aubio Python bindings needed a narrowly scoped compiler-warning flag;
  optional FFmpeg decoder detection had to be disabled for modern FFmpeg builds.
  The DSP source is unchanged. These are concrete integration costs.
- Original Freesound WAVs were login-gated. Tanpura and voice evaluations therefore
  used explicitly labeled HQ MP3 previews. The seven harmonium WAVs are a pinned
  distribution copy, not a bit-for-bit verification of the original long recording.
- Harmonium A3 had a median estimate near **221.21 Hz** in multiple detectors,
  about **9.5 cents above nominal A3=220 Hz**. This is evidence to calibrate sampler
  roots, not proof of absolute source tuning without manual reference labels.
- Tabla clips last only **0.10–0.50 seconds** and peak levels span about **16.6 dB**.
  Bol identity, tails and perceived balance need musician review. No loop, sampler
  patch or theka has been accepted for production.

## Recommendation for V1

1. Use native AVAudioEngine and AVAudioUnitTimePitch provisionally. Keep Rubber
   Band as the measured fallback if blind listening reveals unacceptable artifacts.
2. Start the tuner integration with aubio YINFAST and explicit confidence rejection.
   Keep pYIN for desktop comparisons; avoid default YINFFT for low harmonium notes
   with the tested settings. Resolve source-version parity and deployment minimum
   before choosing the shipping library build.
3. Continue with donyaquick's CC0 harmonium family, Sankalp Gulati's acoustic Pa/Ma
   tanpuras (CC BY), and the Deolekar tabla dataset (CC BY) as prototype sources.
   Obtain lossless originals and musician acceptance before treating these as final.

No listening panel, calibrated real-audio F0 annotation, iPhone microphone test,
background playback test, multi-instrument live mixer, real-time shifting, battery
or thermal measurement was performed. No iOS Rubber Band integration was compiled.
SoundpipeAudioKit/PitchTap and SoundTouch were investigated but not executed.

[Method and reproduction](README.md) · [Linux tables](results/linux/SUMMARY.md) ·
[macOS tables](results/macos/SUMMARY.md) · [Sources and notices](licenses/README.md)

Audition WAVs and source corpus (GitHub sign-in required, about 82 MB ZIP):
https://github.com/harjotharjot/indian-music-app/actions/runs/42524719592/artifacts/13634777893

A `nan` shift-table error means no calibrated reference F0 was assigned to that
real recording, not that its rendered audio was nonfinite.

Initial successful full run:
https://github.com/harjotharjot/indian-music-app/actions/runs/42524402941

The later verification run adds the confidence policy and six-test suite:
https://github.com/harjotharjot/indian-music-app/actions/runs/42524719592

**Phase 2 only. Wait for approval before further app development.**
