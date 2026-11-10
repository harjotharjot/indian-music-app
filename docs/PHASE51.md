# Phase 5.1 — corrections prepared; native validation pending

Source baseline: `0df9d98` (Phase 5, accepted Phase 4 instruments retained).
Version prepared: **0.5.1 (11)**. No CI workflow was dispatched; this work is on a
feature branch to avoid the main-branch IPA workflow while minutes are exhausted.
No new IPA or updated native screenshot has been produced. Do not treat the
portable results below as an iPhone listening or visual acceptance result.

## Tabla alignment

The existing timeline rounds absolute positions once; it does not accumulate
rounded beat durations. Inspection found a preparation/scheduling mismatch:
recordings start on the musical grid, whereas their attack landmarks occur at
different offsets. The 15 offsets range from **4 to 218 frames (0.083–4.542 ms)**.
There is no evidence here of a large silence delay or a cumulative clock defect.
These small offsets alone may not explain every subjective timing concern.

The operational onset landmark is the first causal 48-frame (1-ms) RMS crossing
of 8% of the largest RMS in the first 250 ms, using the louder channel. This is
a reproducible attack estimate, not a universal definition of perceptual onset.
Measurements include 5%, 8%, 12% and 20% threshold sensitivity; natural attack
shapes differ. Peaks are deliberately not forced to coincide.

`tabla-sources.json` records one `onsetFrame` per take. Each complete buffer starts
that many frames before its intended attack. A common 480-frame (10-ms) initial
pre-roll permits this on the first sam too. Queue late-event checks and voice
availability now use the compensated file start; matra position uses the attack
grid. Tempo edits, independent transports, dynamic layers and alternating takes
retain the existing scheduling path. End-frame limits remain musical durations.

**Every shipped WAV is byte-for-byte unchanged.** No trimming, tail processing,
pitch processing, resonance modification or new render DSP is introduced. Combined
Dha/Dhin recordings retain their recorded internal dayan/bayan timing and stereo
relationship; there are no separate drum players to synchronize for these bols.
This audit does not establish perceptual simultaneity of those original takes;
if their internal hand timing is objectionable on audition, replace the combined
recording rather than independently deforming its frequencies.

[Measurements](phase51/measurements.json) · [Comparison chart](phase51/onset-comparison.png)

## Before/after listening comparisons

These are **portable independent reference sums**, not recordings from the iOS
engine. Both versions have the same 10-ms origin, loudness, takes and dynamics;
only sample starts differ. Each plays four cycles at 80 BPM with three seconds
for tails. FLAC is lossless 48-kHz stereo. The small correction can be subtle.
No claim of human listening approval is made.

| Taal | Before | After |
|---|---|---|
| Dadra | [FLAC](phase51/listening/dadra-80bpm-before.flac) | [FLAC](phase51/listening/dadra-80bpm-after.flac) |
| Rupak | [FLAC](phase51/listening/rupak-80bpm-before.flac) | [FLAC](phase51/listening/rupak-80bpm-after.flac) |
| Keherwa | [FLAC](phase51/listening/keherwa-80bpm-before.flac) | [FLAC](phase51/listening/keherwa-80bpm-after.flac) |
| Teentaal | [FLAC](phase51/listening/teentaal-80bpm-before.flac) | [FLAC](phase51/listening/teentaal-80bpm-after.flac) |
| Ektaal | [FLAC](phase51/listening/ektaal-80bpm-before.flac) | [FLAC](phase51/listening/ektaal-80bpm-after.flac) |
| Jhaptal | [FLAC](phase51/listening/jhaptal-80bpm-before.flac) | [FLAC](phase51/listening/jhaptal-80bpm-after.flac) |

## Shared tuning and interface

The existing `AudioCoordinator.settings` already persists global Sa/key, octave,
cents and tanpura parameters under `tanpura.settings.v1`. It remains the sole
source; no second tuning store or migration is added. Reusable tuning controls
now expose the missing octave selection on harmonium as well as the note and
cents on every relevant surface. Tanpura pitch follows the combined tuning;
harmonium sampler tuning follows cents only. Keyboard MIDI notes, geometry,
navigation and sargam mapping retain their existing implementation.

Landscape and forced Full screen use three areas in the supplied reference's
order: enable/release/sargam on the left; Sa/cents summary above tanpura playback
and Pa/Ma in the center; taal/BPM summary above tabla playback on the right.
The continuous slider and keyboard remain below. Existing SwiftUI bordered
buttons, segmented controls, type styles, accent colors and material are used.

Summaries toggle compact, scrollable overlay cards. The tanpura card edits shared
Sa, octave, cents, speed and volume. The tabla card edits taal, BPM and volume.
Opening or closing these cards neither invokes a transport action nor releases
keyboard notes. The keyboard remains present and touchable outside the card.
The full settings sheet and portrait harmonium settings now also include tabla.

Only the tabla glyph is rotated 180 degrees. Tabla transport labels have fixed
width/height; the position indicator reserves fixed space across stopped, playing,
paused, sam and khali states to prevent its changing text from shifting buttons.
Native visual verification is pending, particularly on the smallest iPhone and
with accessibility text sizes.

## Tabla tuning decision: deferred

The resonant dayan recordings share components near **525 and 785 Hz**; Na's
strongest measured component is near 786 Hz, Tin's near 525 Hz, and Tun also has
an appreciable component near 285 Hz. These are spectral resonances, not validated
fundamental-pitch labels. Bayan Ge has broad, time-varying low resonances around
92–113 Hz. Combined Dha/Dhin contain these bass components and dayan together.

A uniform shift would change both drums and their attacks. Selectively tuning
only Na/Tin/Tun would leave the same dayan in Dha/Dhin at its original pitch.
Spanning all 12 Sa choices in two octaves would also require large shifts, with
no pitch-shift quality validation for these mixed recordings. Authentic shared
Sa tuning therefore needs more than a targeted correction. The recommended next
approach is musician-verified, separately recorded dayan and bayan strokes, with
dayan recorded at several tonic pitches (or complete matched banks per tonic),
carefully limited interpolation and a shared onset-calibrated clock. Keep bayan
at musically appropriate natural pitch. No tabla sample is pitch-shifted here.

## Verification and remaining delivery work

Passed locally in Linux:

- All 15 asset hashes, channel/sample lengths and onset metadata reproduce.
- Isolated compensated reference buffers reach the chosen landmark exactly on
  the grid and contain each complete stereo recording unchanged.
- 24 reference renders: six taals × 30/80/137/240 BPM, four cycles each; finite,
  unclipped samples, fewer than 24 overlapping voices. Twelve-hour absolute-frame
  arithmetic stays within half a frame; piecewise tempo arithmetic remains
  ordered and within half a frame. These are independent calculations, not tests
  of the compiled Swift sequencer or a live audio device.
- Swift tree-sitter syntax parsing, Python compilation, shell syntax and
  `git diff --check` pass. Syntax parsing does not replace Swift type checking.

The existing Phase 3/4/5 and simulator scripts were attempted and all stop with
`xcrun: command not found`. This Linux environment has no Xcode, Apple audio
frameworks or iOS Simulator. Native regression results from Phase 5 apply to
that historical build only, not to these changes.

Prepared for the next available Apple environment:

- Expanded `TablaAudioTests` renders all six taals at four tempos. The independent
  native-waveform checker accounts for per-take advance and initial pre-roll.
  Existing pause/resume/restart, tempo/taal changes, five-minute scheduling,
  mixing and accepted-instrument regressions remain in place.
- Added UI tests for stable transport rectangles across all states, portrait,
  both landscape directions and forced Full screen; shared note/octave/cents
  across tabs, mini panels and relaunch; panel opening without transport-state or
  keyboard-geometry changes. Tests retain native screenshot attachments.

Before delivery as an installable correction: run `scripts/test-phase5.sh`,
`scripts/test-phase3.sh`, `scripts/test-phase4.sh`, the Phase 5 waveform checker,
and `scripts/simulator-smoke.sh` on macOS; inspect the resulting native screenshots
against the supplied arrangement, audition timing and transitions, then build
and package **0.5.1 (11)** only when free capacity is confirmed. Real iPhone
acceptance must verify natural attacks, simultaneity, tempo changes, long sessions,
shared tuning and small-screen controls. No IPA link or fabricated screenshots
are supplied. Stop at Phase 5.1 pending the user's iPhone approval.

Reproduce the portable comparisons without CI:

```sh
python -m venv build/phase51-venv
build/phase51-venv/bin/pip install -r scripts/phase51/requirements.txt
build/phase51-venv/bin/python scripts/phase51/validate.py
```
