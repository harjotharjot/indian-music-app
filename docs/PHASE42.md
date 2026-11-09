# Harmonium correction — v0.4.2 (7)

This corrects the remaining Phase 4.1 sound and touch problems. Real-iPhone sound
approval remains with the user. No tabla or unrelated features are included.

## Why the attacks sounded artificial

Phase 4.1 selected established reed energy and cut 0–380 ms from sample starts,
then applied a 6-ms fade. This removed natural reed buildup, particularly in lower
notes, even though sustained timbre was good. The old fast-onset energy gates
rewarded that change and were insufficient as an authenticity test.

This bank restores the Phase 4.0 recorded attack from the original pinned CC0
recordings and retains the original pitch corrections and leading-silence edits.
Only a 45-ms half-cosine opening fade softens the initial mechanical impulse.
After that fade, the recorded rise is left intact. There is no synthetic replacement
attack, oscillator, transient enhancer, or runtime envelope compensation.

Tests compare the 50–450-ms waveform to the original bank, allowing constant gain
and sub-millisecond resampling alignment, and compare actual Apple sampler output
for all playable notes. A short tap may be quieter than the established reed;
that is not treated as a reason to cut away its natural response again.

## Why the old loops were audible

The Phase 4.0 script discarded the recordings after 2.5 seconds, despite having
7–12 seconds of material. For every note it blended the last 50 ms into source
500–550 ms, then set the SF2 loop to **550–2500 ms**. It did not select the points
by waveform phase, level, or the natural variation of each reed. Phase 4.1 changed
attack position/gain but retained these loops.

Across the old fixed crossfade, retuned source waveform correlations were about
0.056 (C3), -0.021 (C#3), and -0.273 (D#3). Blending unrelated or opposing reed
phases causes cancellation and changes the harmonic balance during the fade. The
wrap itself can be sample-continuous while a brief dip/chorusing effect remains
obvious each time it repeats. Returning to early reed material can also reset
its evolving tone. This defect was already present in Phase 4.0.

The new preparation selects later, longer sustained material per recorded zone,
using established correlation/phase alignment, level/envelope matching and spectral
matching of the actual baked return before crossfading. A first native audit
rejected D3 for a timbre reset despite its small level change; selection was
refined rather than weakening that check. Loops last **2.39–5.98 seconds** in this bank, rather than imposing a fixed
1.95-second loop; the search expands to the recording's natural cycle when needed. The
end blends into material immediately *before* the chosen loop start, then continues
through that start. Unity-sum fades avoid the level boost of an equal-power fade
on strongly correlated reed material. Fade lengths vary with the recording.
D3's recording could not provide a sufficiently consistent timbral return under
the joint phase/level constraints, so that key uses the retained C#3 reed sample
transposed up one semitone. This is the existing nearest-neighbor sampler method
already used for other unsuitable/missing zones.
Only the end blend is edited; the remaining recorded sustain and its natural
movement are retained. No bellows modulation, compressor, or live looping DSP
was added. SciPy supplies correlation; FFmpeg supplies resampling/fades; SF2cute
writes the bank. These remain build-time tools.

The original and Phase 4.1 looped recordings are compared directly from actual
SF2 headers/PCM. The new loop headers, wrap steps, predicted crossfade cancellation,
level changes, spectra and natural within-recording variation are audited. Native
Apple sampler renders hold **every C2–C5 key for 32 seconds** in each of three
independent processes: Phase 4.0 bank, Phase 4.1 bank, corrected bank. Separate
processes avoid the sampler's cross-instance sample cache. This includes keys
transposed from neighboring sample zones and several wraps per corrected note.

The more complex multi-reed samples do not have perfect waveform correlation
between distant sections (including G#3). Objective checks bound obvious
cancellation/jumps but **do not establish that a listener cannot hear a repeat**.
The full long holds are supplied for that test, rather than declaring a waveform
continuity metric to be perceptual acceptance.

## Touch changes

The user selected displayed-key alignment with a small side tolerance.

- Visible black rectangles own their complete height, including their tips. The
  former split at 50% keyboard height incorrectly assigned the bottom 11% of
  visibly black keys to white notes, while group-wide upper regions reached well
  beyond their visible sides.
- Touch forgiveness is now 3 points horizontally on each side, stopping at the
  actual black-key bottom. There are no invisible extensions below lower corners
  or across distant upper white areas. Exact bodies take priority before checking
  white containment, including shared floating-point borders.
- Initial taps remain immediate. For a moving finger, a candidate note must remain
  for 6, 12 or 18 ms depending on speed. Very brief intermediate crossings are
  cancelled rather than immediately sounded. The old deliberate note remains
  until a new note is accepted; leaving the keyboard releases it immediately.
- Coalesced UIKit samples provide path/velocity information. A main-run-loop timer
  accepts a finger that stops on its target without requiring another move event.
  Lifting/cancelling, navigation, rotation and Release keys invalidate pending notes.
- Deliberate glissandi with region occupancy above the short dwell still register.
  Extremely fast crossings are intentionally filtered; physical feel needs testing.

Model tests cover taps, C#→C→B fast crossings, both glissando directions, boundary
reversal, duplicate fingers, cancellation, exact black tips and tolerance edges,
several viewport offsets, and portrait/landscape dimensions.

## Preserved systems

The shared audio graph, soundbank lifecycle restoration, monitor calibration,
independent volumes, note ledger/chords, navigation slider, playable range, tanpura
modes/background behavior, settings persistence, compact rail and tab ordering
were retained. App identity is unchanged for a SideStore update. Existing audio,
pitch, lifecycle, fader, sustain, release, tanpura and orientation tests remain.

## Reproduce assets

Use `scripts/phase4/prepare_natural_harmonium.py` with the pinned source recordings,
NumPy/SciPy/SoundFile, FFmpeg and the existing pinned SF2cute writer compiled from
`scripts/phase4/build_soundfont.cpp`. The source manifest lists every download URL
and original hash; preparation checks those hashes before processing. The manifest
and `Sounds/phase42-preparation.json` record the candidate points, fades, gains,
correlations and final bank hash. Prepared sustained RMS retains the accepted
Phase 4.1 reference level; monitor gains are unchanged.

## iPhone acceptance checklist

Install as an update through SideStore; retain existing settings.

1. Compare original, Phase 4.1 and corrected C3/C#3/D#3 audition files at the same
   device volume. Listen first without watching the loop times. Check opening reed
   buildup and several repetitions, not just the first second.
2. Hold those notes in the app for 30 seconds, then check every key and several
   chords. Listen for a cut, dip, repeated swish, phasing or timbre reset. Include
   G#3, D3, E3 and F4, whose recordings are more complex to loop.
3. Slide C#→B quickly across C, in both upper and lower keyboard regions. Then try
   deliberate white/black glissandi. Check normal taps and stopped-finger changes.
4. Test black-key sides and bottom corners at different slider positions and both
   orientations. Check no stale note fires after lifting, Release keys or navigation.
5. Recheck enable/disable timbre, chords/release, independent volumes, both tanpuras,
   background playback, saved settings and rotation. These were working beforehand.

Report note/register, direction, approximate time of an audible loop change, phone
model and audio route. Authenticity and perceptual seamlessness require listening;
CI does not certify physical touch latency or subjective tone. Stop here until
harmonium sound is accepted on the iPhone.

## Delivered build and results

[Successful build — source `4a953d8`](https://github.com/harjotharjot/indian-music-app/actions/runs/42576385163)

- [Unsigned v0.4.2 IPA ZIP](https://github.com/harjotharjot/indian-music-app/actions/runs/42576385163/artifacts/13655986022)
- [Short listening set: nine WAV files](https://github.com/harjotharjot/indian-music-app/actions/runs/42576385163/artifacts/13655886216)
- [Full test artifact, including all 37 keys × three banks](https://github.com/harjotharjot/indian-music-app/actions/runs/42576385163/artifacts/13655826399)

The listening ZIP contains 32-second, equal-loudness versions of C3 (48), C#3 (49),
and D#3 (51): `phase40`, `phase41`, and `corrected`. These compare sample banks
through the same fixed engine and monitor settings; they do not reintroduce the
old engine lifecycle defect. Matching uses a constant gain per file to -30 LUFS,
so opening envelopes and repeated loop behavior remain intact. The full artifact
contains lossless per-key FLACs at the actual monitor gain in `comparisons/`.

Actual sampler measurements, using 100-ms windows around each loop return:

| Key | Old boundary level change, max | Corrected, max | Old spectral L1, max | Corrected, max |
|---|---:|---:|---:|---:|
| C3 | 0.979 dB | 0.011 dB | 0.326 | 0.078 |
| C#3 | 1.851 dB | 0.293 dB | 0.148 | 0.029 |
| D3 | 2.335 dB | 0.118 dB | 0.539 | 0.031 |
| D#3 | 0.786 dB | 0.006 dB | 0.256 | 0.036 |
| F4 | 1.781 dB | 0.113 dB | 0.103 | 0.073 |

Phase 4.0 and Phase 4.1 produce the same old-loop measurements; the attack/gain
changes did not repair their looped material. D3's corrected result uses the
one-semitone C#3 donor described above. Spectral L1 is normalized band-power
change (0–2), not a perceptual quality score.

- All 111 native 32-second holds passed; corrected clips include at least five
  actual loop returns per key. Transposed keys are included.
- Across corrected keys, maximum measured boundary level change was 0.436 dB;
  maximum spectral L1 was 0.161. Checks also compare with each recording's normal
  within-note variation and inspect actual SF2 headers and endpoint steps.
- Retained source attack correlation to Phase 4.0 after the opening fade was at
  least 0.99999986. Same-source native playback prefixes passed correlation checks;
  D3's deliberate donor change is explicitly exempted from an identical-source
  comparison and audited through its C#3 zone instead.
- 111 key/tuning cases passed, worst clip median pitch error 0.890 cents.
- 100 lifecycle cycles, 333 short/repeated taps, sustain, chord fundamentals,
  duplicate fingers, release/cancellation, independent faders and clipping passed.
- Equal 60% levels were C3 -36.48 LUFS, Sa–Pa -34.03 LUFS and Sa–Ma -37.14 LUFS.
  The maximum-volume 37-note-plus-tanpura stress render peaked at 0.924 full scale.
  Monitor calibration was not changed.
- Both 160-second tanpura regressions and simulator orientation/selection/slider
  checks passed. Boundary sweeps and adaptive slide/glissando model tests passed.
- Device arm64 unsigned packaging and sample hash checks passed.

[Full loop/attack audit](phase42/phase42-results.json) ·
[Lifecycle/loudness regression data](phase42/phase41-results.json) ·
[Pitch data](phase42/harmonium-pitch-results.json) ·
[Sustain/polyphony data](phase42/harmonium-polyphony-results.json) ·
[Validation summary](phase42/validation.txt).

These measurements do not certify perceptual seamlessness, natural tone, or
physical gesture latency. Listen to the supplied comparisons and test on the
phone using the checklist above. This correction stops for that acceptance.
