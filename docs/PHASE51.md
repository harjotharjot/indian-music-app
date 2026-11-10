# Phase 5.1 — iPhone audition build 0.5.1 (11)

Source baseline: `0df9d98` (Phase 5, accepted Phase 4 instruments retained).
Version: **0.5.1 (11)**. All native audio checks passed in
[run 42869026998](https://github.com/harjotharjot/indian-music-app/actions/runs/42869026998).
The unsigned iPhone build is available from source `2272b79`:

**[Download the unsigned IPA ZIP](https://github.com/harjotharjot/indian-music-app/actions/runs/42874183491/artifacts/13793016213)**

Extract the ZIP in Files and install `IndianMusic-unsigned.ipa` over the existing
app through SideStore. The app remains unsigned until SideStore signs it for you.
The downloaded IPA was independently checked for version/build, bundle identifier,
absence of a signing envelope/provisioning profile, all 15 tabla sample hashes and
onset metadata, and its published SHA-256:

`80b49c5aa4d88782c821e589e913f4c1ec83ef13bb3a7434cfd059963dccf722`

Native audio checks passed. Six of seven simulator tests passed in the build run;
the remaining test's close-button identifier lookup was corrected and is being
[rerun separately](https://github.com/harjotharjot/indian-music-app/actions/runs/42878338544).
That correction changes UI automation/CI only; app source is identical to this IPA.
Standard macOS runners are free for this public repository. Repository visibility
was not changed.

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
Native captures were reviewed in both landscape directions. Smaller iPhones and
accessibility text sizes still need device review.

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

## Verification and delivery evidence

Native macOS audio checks passed for source `66c4d20` in
[run 42869026998](https://github.com/harjotharjot/indian-music-app/actions/runs/42869026998):

- Six taals at 30/80/137/240 BPM: **24 actual AVAudioEngine renders** match
  independent per-take compensated waveform sums. Maximum absolute error:
  **5.091 × 10⁻⁸**. Full attacks, tails, alternate takes and subdivisions remain.
- Five-minute native tabla scheduling, tempo/taal edits, pause/resume/restart,
  independent bus mutes and maximum-fader simultaneous instruments passed.
- Twelve-hour Swift timeline models stay within half a sample frame, including
  the original tempo-segment checks and the new initial pre-roll checks.
- Shared tuning/persistence models, both tanpura loop renders, 111 harmonium
  tuning cases, **111 native 32-second held-note comparisons**, loop boundaries,
  F♯ guard repair, attacks, lifecycle, chords and release checks passed.
- The arm64 iPhone Release app compiled and packaging checks passed.

[Native waveform measurements](phase51/native-waveform-validation.json) ·
[Complete native evidence ZIP](https://github.com/harjotharjot/indian-music-app/actions/runs/42869026998/artifacts/13791106775)

An initial unpaced offline run produced nondeterministic silent gaps. A focused
same-bank experiment reproduced large gaps in several different notes when
rendering as fast as possible; 1-ms sleeps between offline blocks removed those
large gaps. Pacing was added **only to the native test harnesses**, allowing
Core Audio's asynchronous sample workers to run. All waveform assertions and
tolerances remain unchanged. Production rendering and the harmonium bank were
not altered for this harness correction.

[Experiment](https://github.com/harjotharjot/indian-music-app/actions/runs/42868102347) ·
[Paired native experiment audio](https://github.com/harjotharjot/indian-music-app/actions/runs/42868102347/artifacts/13787214169)

Six of seven simulator tests passed in
[run 42874183491](https://github.com/harjotharjot/indian-music-app/actions/runs/42874183491):
portrait scrolling with a pinned keyboard and reachable speed controls; stable
tabla transport geometry in portrait, both landscapes and forced Full screen;
switcher order/selection; background transport; interruptions/engine recovery;
and physical-return/ordinary orientation behavior.

The remaining shared-tuning test selected Sa/octave/cents, verified synchronization
across portrait/landscape/tabs, opened the tanpura mini panel without pausing the
drone and edited cents, then failed to look up the close button by identifier.
The captured UI tree shows the button present with the correct accessible label,
"Close mini settings": SwiftUI inherited its parent panel identifier. The test now
uses that visible accessible label. A focused rerun is pending; **the full UI suite
is not reported as green**. This test-only correction does not change the app.
The rerun reuses completed native checks only after a Git diff guard confirms that
all audio source, assets and harnesses remain identical to validated `66c4d20`.

[Six passing UI tests and failure evidence](https://github.com/harjotharjot/indian-music-app/actions/runs/42874183491/artifacts/13792402783) ·
[Focused shared-tuning/panel rerun](https://github.com/harjotharjot/indian-music-app/actions/runs/42878338544)

Unmodified native iPhone 16 Pro captures from `66c4d20` (the subsequent app changes
only disambiguate accessibility identifiers):

- [Harmonium, port right](phase51/harmonium-landscape-port-right.png)
- [Harmonium, port left](phase51/harmonium-landscape-port-left.png)
- [Tabla portrait](phase51/tabla-portrait.png)
- [Tabla forced Full screen](phase51/tabla-forced-fullscreen.png)

Portable Linux checks also passed: all 15 WAV hashes, exact preservation of the
complete stereo waveforms, onset-metadata reproduction, independent four-cycle
reference sums across all 24 taal/tempo combinations, finite/unclipped output,
voice-count bounds, twelve-hour arithmetic, Python/shell checks and Swift syntax
parsing. The original portable before/after listening files remain reference sums;
the native waveform evidence above provides the separate Core Audio verification.

On iPhone, install over the existing app through SideStore. Audition all six taals
at slow, medium and fast tempos and during tempo edits. Check natural attacks,
combined strokes, longer practice sessions, shared Sa/octave/cents on every tab,
both mini panels, portrait/landscape/Full screen, held notes and keyboard navigation.
The objective onset landmark is not a claim of perceptual or musical acceptance.
**Stop at Phase 5.1 for the user's iPhone approval.** No microphone tuner or other
phase has begun.

Reproduce the portable comparisons without CI:

```sh
python -m venv build/phase51-venv
build/phase51-venv/bin/pip install -r scripts/phase51/requirements.txt
build/phase51-venv/bin/python scripts/phase51/validate.py
```
