# Phase 2: audio feasibility

This directory contains standalone research scripts and measurements. The iPhone
app remains the Phase 1 install proof. No audio engine, instruments, tuner UI or
recording library was added to the application.

## Reproduce

Python 3.11 on macOS (CI) or Python 3.12 on Linux was used. Create a virtualenv;
install NumPy 1.26.4, `setuptools<81` and wheel before installing
`requirements.txt` with `--no-build-isolation`. See the workflow for exact macOS
commands. On GCC 14, use `CC=gcc CXX=g++ CFLAGS=-Wno-error=incompatible-pointer-types`
for the aubio install. On Apple Clang, the corresponding flag is
`-Wno-error=incompatible-function-pointer-types`. These address a const-signature
warning in aubio's old Python/NumPy binding; no DSP source is changed.

The Python aubio build auto-detects optional FFmpeg libraries, and aubio 0.4.9's
file decoder fails against modern FFmpeg. CI isolates pkg-config discovery using
an empty `PKG_CONFIG_LIBDIR` and `PKG_CONFIG_PATH`. Decoding is performed by
SoundFile/FFmpeg outside aubio; the benchmark only uses aubio's pitch API.

From the repository root, in the virtualenv:

```sh
python feasibility/fetch_samples.py
python -m unittest discover -s feasibility -p 'test_*.py' -v
python feasibility/benchmark.py
python feasibility/confidence.py
python feasibility/summarize.py
```

On macOS, with Rubber Band CLI and FFmpeg installed:

```sh
xcrun swiftc -parse-as-library feasibility/swift/NativeShift.swift -o build/native-shift
python feasibility/shifts.py --native "$PWD/build/native-shift"
```

Or run **Actions → Phase 2 audio feasibility → Run workflow**.
Artifacts retain raw results, samples, attribution and WAV audition files for
30 days. Input assets (about 10 MB) are intentionally excluded from git; source
URLs, SHA-256 hashes and a pinned harmonium source revision are committed.
Downloads fail if the retrieved bytes differ from the reviewed manifest.

## What was evaluated

- **24 downloaded source files:** seven harmonium WAVs spanning C2–C5 / A2–A4,
  13 original tabla stroke WAVs, two acoustic tanpura MP3 previews (Pa and Ma),
  and two singing MP3 previews. See [samples.json](samples.json) and
  [attribution](licenses/README.md). Freesound original WAVs require login;
  previews are not substitutes for the production masters.
- **Five established detector configurations:** aubio YIN, YINFFT and YINFAST
  0.4.9; librosa YIN and pYIN 0.10.2.post1. No detector implementation was written.
- **52 synthetic fixtures / 260 comparisons:** eight base pitches from 65.4064
  through 2093.005 Hz, detuned -37/+17 cents, using sine, weak-fundamental reed-like
  harmonics and missing fundamentals; plus vibrato, 20-dB-SNR noise, silence and
  noise-only controls. Harmonic fixtures are test signals, not authentic instruments.
- **48-kHz mono, 4096-frame windows (85.33 ms), 512-frame hops (10.67 ms).**
  Results cover central steady regions, excluding the first 300 ms and final
  150 ms. Startup settling time is not measured. Vibrato is evaluated against
  frame-center instantaneous F0, so finite-window smoothing/lag contributes error.
- **Real audio:** first eight seconds of every harmonium and voice sample,
  analyzed by all detectors. These files have no calibrated frame-level F0 labels.
  Detector agreement and coverage are diagnostics, not absolute pitch accuracy.
- **Confidence policy:** separately evaluate aubio YINFAST's existing confidence
  output with a 0.9 rejection threshold. Rejected estimates count against coverage;
  octave errors are never folded away. This is benchmark policy, not a finished tuner.
- **Shifting:** Apple `AVAudioUnitTimePitch` at rate=1 versus Rubber Band R3 at
  -600/-300/-100/-17/+17/+100/+300/+600 cents. Inputs include known tones,
  recorded harmonium, tanpura, voice, tabla and a mix of recorded excerpts.
  Quantitative F0 gates apply to the known sine; other renders are audition inputs.

## Read the results correctly

[Linux tables](results/linux/SUMMARY.md) and raw JSON record actual measurements.
Coverage, gross errors, octave errors and cents error are separate. Error statistics
exclude rejected/unvoiced estimates; a low cents error with low coverage is not a
pass. Summaries aggregate clip-level statistics, not pooled frame errors. Compute
ratios exclude JIT/import warmup and are desktop throughput, not phone CPU, memory,
thermal behavior or microphone latency.

Sample audit records duration, source format, peak/RMS level, clipping and a raw
end-to-start discontinuity. It does not establish a seamless loop or sound quality.
There was no human listening panel or musician approval. Authenticity is supported
by the recording provenance; final timbre, reed realism and tabla phrasing remain
subjective acceptance tasks.

Apple renders intentionally include one second of trailing output to reveal DSP
tails. Do not interpret that extra container duration as changed playback tempo.
Active-span differences are coarse 10-ms envelope diagnostics. A V1 export/transport
must handle latency and output length explicitly; this harness is not that feature.

## Provisional component decisions

- **Tuner:** aubio **YINFAST** is the leading live candidate, with confidence-based
  rejection, range limits and later device validation. It matched YIN's steady
  synthetic accuracy with substantially lower Linux compute cost. Default YINFFT
  failed low notes and disagreed by about an octave on much of the C2 harmonium
  excerpt. Do not select it solely because it is aubio's default.
- **Offline comparison:** keep pYIN as an independent configuration for diagnostics,
  not ground truth. Its 10-cent bin setting here cannot substantiate a sub-cent
  tuner claim. It is a Python research dependency; no iOS pYIN port was tested.
- **Harmonium:** prefer the CC0 donyaquick recording family. Seven distributed WAVs
  decoded successfully without clipping; their nominal labels are not calibration.
  Need original-master verification, tuning offsets, sustain-loop editing, attacks,
  releases and chord listening. No sampler patch was constructed.
- **Tanpura:** prefer Sankalp Gulati's acoustic Pa/Ma recordings for continued
  audition. They preserve actual jawari but contain overlapping strings. Independent
  speed control and clean loops are unproven, and MP3 previews are inadequate as a
  final master decision. No custom physical-model synthesis is justified yet.
- **Tabla:** the Deolekar dataset is an attributed, downloadable prototype candidate.
  Selected clips are only 0.10–0.50 seconds, with peaks differing by about 16.6 dB.
  Tail completeness, perceived balance, bol mapping and theka phrasing need review.
  Keep original stroke names; do not guess that abbreviations are standard bols.
- **Pitch shifting:** choose the native Apple node provisionally for integration
  simplicity, subject to the measured render checks and later blind listening.
  Rubber Band remains the comparison/fallback. Final quality cannot be selected
  from a sine-wave pitch score; voice formants, transients and polyphonic artifacts
  need listening. SoundTouch was reviewed, not executed. SoundpipeAudioKit PitchTap
  was researched, not benchmarked; its ptrack algorithm is not YIN.

## iOS and remaining gates

The workflow cross-builds unmodified upstream aubio at
`ad5cf975aed08cc4562dd008cf9f83b12b82ffb8` as an arm64 iOS static library, checking
its object platform. That upstream build defaults to iOS **16.4**. Desktop
benchmarks use released **0.4.9**, so this is a separate compatibility probe,
not a claim of identical builds or an app-linked runtime test. Keep the app's
minimum at iOS 16.0 for now; deciding the detector's shipping build is future work.

The Apple harness also type-checks against the arm64 iOS 16 SDK; actual rendering
runs on macOS. No iPhone audio, microphone, background playback, route changes,
latency, battery or thermal behavior was tested. There is no tested iOS Rubber Band
integration. GPL/LGPL and sample attribution obligations remain relevant to any
future distributed build; see the dependency notices.

The two singing recordings do not cover Indian-classical ornamentation, multiple
singers, breathy low-register singing or live accompaniment leakage. Calibrated
real harmonium/voice F0 annotations and listening on the user's actual iPhone are
still required before claiming the original accuracy and realism requirements.

**Stop after Phase 2. Further app development requires approval.**
