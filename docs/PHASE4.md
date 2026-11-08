# Phase 4 — sampled harmonium and replacement tanpuras

Version **0.4.0 (5)**. The user confirmed that Phase 3 passed their real-iPhone
checks. Phase 4 changes require new phone testing; CI results are not device results.

## Implemented

- Apple's `AVAudioUnitSampler`, loading a prepared SoundFont 2 bank of recorded
  harmonium reeds. No oscillator-based harmonium or third-party runtime DSP.
- UIKit multitouch keyboard, one or two visible octaves, with navigation over
  C2–C5. Black-key hit testing takes priority. Finger identity is tracked through
  slides, lift-off and cancellation; two fingers sharing a key keep one voice
  sounding until the final finger releases it.
- Optional sargam labels for every Sa key. Piano pitches stay fixed, as on a
  physical harmonium; selecting Sa changes the reference labels and tanpura.
  Shared one-cent fine tuning adjusts both instruments. Sa is not a scale-changer
  that makes a white C key sound a different semitone.
- Separate harmonium and tanpura monitor volumes, playing together in one engine.
  Tanpura transport, settings, cents, speed and background playback remain available
  in the Tanpura tab. Existing settings keys are retained across the update.
- Portrait and landscape layouts for both instruments. The switcher is anchored
  to the charging-port edge: bottom in portrait, the corresponding side in landscape.
  It stays outside scrolling content.
- Explicit keyboard enable preloads/starts the already constructed engine before
  playing. The session requests a 5.333-ms IO buffer; the actual route may differ.
- Notes are released when the app becomes inactive, the keyboard disappears,
  register/span changes, audio is interrupted, a route disconnects, or the user
  presses Release all keys. Old cancelled fingers cannot retrigger by moving.
  Tanpura may continue in the background; held keyboard notes do not latch there.

## Sound sources and preparation

### User-supplied tanpuras

The uploaded C-scale MP3s replace the earlier Freesound tanpuras completely.
Their durations are about **1800 seconds (Pa)** and **602 seconds (Ma)**.
Original creator/license were not supplied. They are used at the user's request
in this private app; no public redistribution license is assumed.

Each bundled loop uses source seconds **30–90**, with a three-second linear
crossfade made by FFmpeg and a -9 dBFS peak. Resulting loops last **57 seconds**,
stereo PCM16 at 48 kHz. This avoids decoding entire long MP3s into hundreds of MB
of memory on the phone. The buffers for both loops consume about 44 MB as floats.
Sources, original hashes, selected intervals and seam measurements are in
[the tanpura manifest](../IndianMusic/Sounds/tanpura-sources.json).

Sa was estimated near C3 with existing aubio YINFAST: approximately **130.6566 Hz
(Pa)** and **131.0004 Hz (Ma)**. Playback accounts for those estimates. Mixed
strings/beat frequencies and compressed source audio limit absolute calibration.
The loop boundaries pass a numerical discontinuity check relative to normal
waveform steps. That does not establish that room ambience or musical phrasing
loops convincingly; listening on the phone remains necessary.

### Harmonium

[donyaquick's harmonium recordings](https://freesound.org/people/donyaquick/sounds/330410/)
were recorded at Euterpea Studio, Yale, and released under CC0. Distributed WAVs
come from `nbrosowsky/tonejs-instruments` pinned to
`622c2f1c32c8cfce4158ddc3eb26e518ddef37e5`.

38 source recordings were evaluated. Four low-register candidates (C♯2, D2, E2,
F♯2) yielded octave-ambiguous native-render results and were excluded. **34 recorded
zones** remain. Those keys, and the missing F♯4 sample, use their nearest retained
neighbor, never more than one semitone away within the playable C2–C5 range.

Preparation trims leading silence, estimates/retunes each source against A440
using established aubio and FFmpeg, retains the attack, and makes a 50-ms sustain
crossfade with Pydub. Samples peak at -12 dBFS. Apple's sampler handles looping,
polyphony and an approximately 80-ms release envelope. One reed registration is
included; no bellows-pressure model or additional stops are claimed.

The bank is written using [SF2cute](https://github.com/gocha/sf2cute), pinned to
`3c5fc83b6ba3d1feb377f9c86021fd77499eb7c0` (zlib/libpng license). SF2cute, FFmpeg,
Pydub and analysis libraries are **build-time tools only**, not linked into the app.
The [harmonium manifest](../IndianMusic/Sounds/harmonium-sources.json) contains each
source URL, hash, correction, inclusion/exclusion and the bank checksum. In-app
Sound credits identify the sources and modifications.

## Audio architecture for later recording — not implemented

```text
Pa player → TimePitch ─┐
                      ├→ tanpura dry bus → tanpura monitor fader ─┐
Ma player → TimePitch ─┘                                        ├→ main mixer → output
Harmonium sampler ───────→ harmonium dry bus → monitor fader ────┘
```

`PracticeAudioGraph` exposes separate dry mixer buses. There are no capture taps,
recording buttons, microphone session, microphone permission or recording/library
code in the app. Future instruments should attach their own dry and monitor buses
in this same engine.

A future recording coordinator can tap selected dry buses independently and write
separate float PCM stems, then mix/export the selected tracks. Monitor faders can
remain independent of capture levels. Every captured buffer must carry its
`AVAudioTime`/host-time anchor on the shared render clock; tracks must not be
aligned using wall-clock/UI timers. Input, output and effect latency differences
will need measured alignment/compensation, gap handling and format conversion.
Common engine ownership alone does not prove sample-exact alignment.

Future microphone capture should use a dedicated input bus under `playAndRecord`
and stay disconnected from the output by default to prevent feedback. Headphones
will be the dependable choice for clean microphone stems while accompaniment
plays. Taps must hand off bounded copied buffers to non-realtime file writers;
file IO and export/mixing belong off the audio thread. These are architecture
constraints, not an implemented recorder.

## Automated checks and their limits

- Phase 3 tuning/settings regression tests and 160-second offline renders of each
  new tanpura at 0.75× / 1.25× and +37 cents, covering repeated loop boundaries.
- Chord ledger, duplicate-finger release, sliding off/back, cancelled-touch rejection,
  black-key geometry, all 12 Sa label mappings, octave bounds and saved settings.
- Actual Apple sampler renders of all **37 playable keys × -37/0/+37 cents**.
  Range-constrained `librosa.yin` measures absolute error without octave folding.
  Raw aubio estimates were insufficiently stable on some low reed recordings;
  those diagnostic failures are not silently counted as tuning passes.
- Six non-octave chord fundamentals checked against isolated-note spectra using
  SciPy's periodogram; eight-second sustain RMS checked across sampler joins.
- Note-off tails, panic/all-notes-off, rapid note cycling, simultaneous tanpura,
  pattern/tuning changes and independent monitor faders checked in offline renders.
- Render-only onset is measured at a -80 dBFS sample threshold. It can include
  recording noise and excludes finger dispatch, hardware buffers, converters,
  speaker/headphone transport and Bluetooth. It is not touch-to-sound latency.
- Device IPA validation, asset hashes, simulator install/launch, and UI tests of both
  instruments in portrait and both landscape directions, asserting the switcher
  follows the charging-port edge and remains tappable.

No physical-iPhone latency, touch polyphony, CPU/thermal/battery, background regression
or perceived reed/loop quality is claimed until the user tests this version.

## Reproduce assets

Use the Phase 2 Python environment plus `pydub==0.25.1`, FFmpeg and a C++14 compiler.
Clone SF2cute at the pinned revision above (no runtime dependency), then compile:

```sh
mkdir -p build/phase4
g++ -std=c++14 -O2 -I /path/to/sf2cute/include -I /path/to/sf2cute/src \
  scripts/phase4/build_soundfont.cpp /path/to/sf2cute/src/sf2cute/*.cpp \
  -o build/phase4/build-sf2
python scripts/phase4/prepare_assets.py --pa '/path/to/c tanpura sa pa.mp3' \
  --ma '/path/to/c tanpura sa ma clipped.mp3'
```

Use `--harmonium-only` to rebuild just the bank. The original user uploads are not
committed; their prepared loops and hashes are. CI builds from committed assets,
without downloading or regenerating sounds.

## iPhone checklist

1. Install the new IPA over the existing app through SideStore; keep your settings.
2. Tap **Enable harmonium**. Try single notes and three-finger chords, slides between
   white/black keys, overlapping fingers on one key, and fast repeated notes.
3. Hold a note for ten seconds, then release it. Check for repeated clicks or a stuck
   reed. Test Release all keys, changing registers and switching tabs while holding.
4. Try one/two octaves, C2/C3/C4 navigation, all Sa keys, optional sargam and ±1/±37 cents.
5. Start tanpura while playing. Independently mute each volume; check that the other
   instrument continues. Listen to both replacement tanpuras across a minute-long join.
6. Rotate both screens in both landscape directions. The switcher should remain
   on the charging-port side; portrait should put it at the bottom. Check that
   rotation/tab changes release held notes.
7. Background/lock the app: keyboard notes should stop; a playing tanpura should
   continue. Check lock-screen controls, headphone disconnection and interruptions.
8. Report perceived delay, missed releases, pitch mismatch, harsh loops or distortion,
   along with phone model and audio route (speaker/wired/Bluetooth).

Stop after Phase 4 and wait for these real-iPhone results before adding other features.

## Final measured results

[Audio measurement run](https://github.com/harjotharjot/indian-music-app/actions/runs/42533659863)
for source commit `87a7ccc` passed the mandatory pitch gate. The final orientation
verification run, linked below, repeats these audio checks with the same assets.

- **111/111 rendered key/tuning cases passed the median-error criterion**; worst clip median absolute pitch
  error was **0.8893 cents**. This is offline audio analysis, not a claim of one-cent
  accuracy on every instantaneous sample or physical-iPhone verification.
- Instantaneous estimator ambiguity remains: reanalysis found octave-sized outliers
  in approximately **1.55% of voiced frames**, and the worst clip p95 error was
  approximately **1201 cents**. The sub-cent median does not erase those outliers.
  These results do not prove sample-by-sample F0 accuracy; reeds/overtones and the
  detector need further evaluation before any live tuner accuracy claim.
- All six chord fundamentals were present. Power relative to corresponding isolated
  notes ranged from approximately **0.997 to 1.004**.
- Eight-second held-note minimum 100-ms RMS was **0.00375**, with no silent loop
  blocks. Note-off tails and panic tests passed without held voices.
- Render-only first-sample threshold onset was **0.688 ms median / 5.313 ms max**.
  The -80 dBFS threshold may include noise; **this is not measured audible attack
  latency or physical touch-to-sound latency**.
- Both replacement tanpuras passed 160-second renders, restarts and loop-gap checks.
  The shared engine passed simultaneous instrument, fader and rapid-note stress checks.
- Device arm64 IPA validation, simulator installation and launch passed. Both
  instrument screens pass automated rotation and switcher-placement checks.
  Simulator touch playing was not automated.

[Raw pitch results](phase4/harmonium-pitch-results.json) ·
[Polyphony/sustain measurements](phase4/harmonium-polyphony-results.json) ·
[Native test transcript](phase4/validation.txt) ·
[Estimator outlier analysis](phase4/estimator-outliers.json)

[Final successful build and rotation checks](https://github.com/harjotharjot/indian-music-app/actions/runs/42535362022)
(source `90caf43`). [UI test transcript](phase4/orientation-tests.log).
Screenshots: [harmonium landscape](phase4/harmonium-landscape-port-right.png),
[tanpura landscape](phase4/tanpura-landscape-port-left.png),
[harmonium portrait](phase4/harmonium-portrait.png).

[Download v0.4.0 unsigned IPA ZIP](https://github.com/harjotharjot/indian-music-app/actions/runs/42535362022/artifacts/13639038319)
(GitHub sign-in required; install through SideStore as an update).
