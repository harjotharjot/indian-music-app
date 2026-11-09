# Phase 4.1 — harmonium corrections

Version 0.4.1 (6). Phase 4 was not accepted on the phone. This update fixes the
reported issues; numerical and simulator results do not constitute iPhone approval.
No tabla, tuner, microphone or recording features were added.

## Audio

The native Apple sampler reproduction stops/prepares/restarts the engine without
reloading its bank. Its normalized spectral distance from the initial sampled C3
is 1.66288 (L1 distance, range 0–2). Restoring the bank **after engine allocation**
produced distance 0 in 50 independent restart cycles. The previous graph reused
the sampler after resource allocation without restoring the sampled instrument.
`startEngine` now restores program 0 of the bundled SF2 before accepting notes,
retains fine tuning, and stops/throws if restoration fails. The same shared engine
and independent dry/monitor buses remain in place.

Raw C3 has a transient, a quieter interval, then reed buildup; detecting the first
sample above -80 dBFS did not measure musical onset. The SF2 repair locates three
consecutive 10-ms windows of established reed energy, trims 0–380 ms depending on
the recording, and applies a 6-ms fade. Original source pitch correction and
sustain loop positions are retained. Sustained sample RMS is balanced with gains
bounded to ±6 dB. This remains recorded reed sound; no oscillator replaces it.

Reproduction: obtain `IndianMusic/Sounds/harmonium.sf2` from commit `b5bf10d`, then
run `scripts/phase4/correct_attacks.py original.sf2 output.sf2 audit.json` with
NumPy/SciPy. `Sounds/phase41-attacks.json` records original/output hashes, each
sample's trim and gain. The source manifest includes the updated bank hash.

Before monitor calibration, equal 60% settings measured C3 -41.39 LUFS,
Sa–Pa -27.03 LUFS and Sa–Ma -30.14 LUFS. Reeds now receive +5 dB sampler gain;
tanpura monitor receives -7 dB. Separate user faders remain unchanged in location
and meaning. Tanpura PCM, tuning, speed and loops are unchanged. These reference
levels do not imply equal loudness for every note/chord, register or phone route.

## Interface

- Existing top/bottom controls and settings sheet remain; the hand becomes
  **Release keys**. Register/octave-count controls are replaced by a continuous slider.
- A single normalized viewport position drives geometry, labels and hit testing
  across all 37 notes C2–C5. White keys are at least 44 points wide; black keys are
  56% as wide and 61% as long. Approximately 16 white keys fit in landscape when
  screen width permits. Portrait shows fewer keys at the same comfortable scale.
- The upper half maps C/D/E to two black regions and F/G/A/B to three; lower half
  maps to white keys. The upper final C5 has no following black key and is inert;
  its lower half remains playable. Viewport boundaries clip hit regions.
- Slider touch-down releases/cancels held notes and disables key input until
  navigation ends. Keyboard finger slides remain musical glissandi; they do not
  scroll the note range. Fractional slider changes do not snap to semitones/octaves.
- Saved settings keep their existing keys; legacy harmonium records decode without
  the new optional navigation position. The new position saves with those settings.
- Landscape rail is 50 points wide, icon-only, with 46-point minimum button height.
  Tanpura is a reusable monochrome SwiftUI Shape, inheriting the same selected
  accent/unselected gray style and background as Harmonium. VoiceOver names remain.
- Port right: Tanpura above Harmonium. Port left: Harmonium above Tanpura.
  Portrait keeps labeled Harmonium-left/Tanpura-right bottom navigation.
  The root extends to the charging-port edge to reclaim padding; the rail stays
  above instrument navigation containers. Orientation-change notifications trigger
  a window-scene read after the transition, including 180-degree turns that do
  not resize the view. Device orientation is a signal, not the source of tab order.

## Verification

The macOS workflow compiles/renders the real production graph, compares 50 stopped
engine restarts and 50 cycles with the engine running/tanpura scheduled, renders
37 keys × three tunings, 333 short/repeated taps, sustain, chords, releases,
independent faders, both long tanpura loop checks, and maximum-polyphony mixing.
Phase 4.0 and corrected samples are rendered in separate processes for before/after
audition, avoiding shared sampler sample caches. A C3 early-energy comparison
rejects identical or unimproved audition output.

The attack gate uses sustained-relative 10-ms energy windows and requires sound
in short taps. It cannot certify perceptual authenticity or absence of mechanical
noise. Listening on the phone remains the decisive attack/timbre check.

Model tests sweep continuous viewport positions and touch regions. Simulator tests
verify both screens and physical orientation ordering, slider interaction, selected
accessibility state, and blue-versus-gray pixels for both selected icons. Screenshots
and audio reports are uploaded in the test artifact alongside the unsigned IPA.

## Real-iPhone checklist

Install over the current app using SideStore; do not uninstall first.

1. Enable/play/disable/re-enable harmonium ten times, both with tanpura playing and
   stopped. Compare the same C notes: sampled reed timbre must remain unchanged.
2. Compare C and A♯, then every key: short taps, rapid repetitions, sustained notes,
   three-finger chords, duplicate fingers, white/black slides, and Release keys.
   Report knocks, missed tone, unnatural attacks or stuck notes with note/register.
3. Drag navigation slowly through its full range and both endpoints. It must move
   continuously without sounding notes; play again after lifting navigation fingers.
4. Test upper black regions and lower white regions, including viewport edges.
5. Rotate both ways: port right has Tanpura on top; port left has Harmonium on top.
   Select each icon and check its blue/gray state. Confirm useful controls remain.
6. At 60% compare C3, other registers/chords, Sa–Pa and Sa–Ma. Listen for imbalance
   and distortion on the speaker and your usual headphones.
7. Confirm Sa/cents, sargam, separate volumes, speed and settings after relaunch.
   Lock/background tanpura; verify playback, lock-screen transport and interruption
   recovery. Held harmonium notes must release on backgrounding or tab changes.

Report phone model, audio route and the failing note/action. Bluetooth adds latency;
no physical touch-to-sound latency, battery or thermal result is claimed by CI.

## Delivered build and measured results

[Successful build](https://github.com/harjotharjot/indian-music-app/actions/runs/42542905615)
for app/test source `bd524d7`:
[unsigned IPA ZIP](https://github.com/harjotharjot/indian-music-app/actions/runs/42542905615/artifacts/13642143110) ·
[full test/audio artifact](https://github.com/harjotharjot/indian-music-app/actions/runs/42542905615/artifacts/13642272001).
Extract the ZIP and install the `.ipa` through SideStore over the existing app.

- 50 stopped-engine restart cycles and 50 live-engine cycles with tanpura scheduled
  matched the initial normalized sampler spectrum (maximum L1 distance 0).
  The deliberately unrestored restart reproduced distance 1.66288.
- All 111 note/tuning cases passed; worst clip median absolute pitch error
  0.8180 cents. This is a median estimator result, not instantaneous accuracy.
- 37 attack cases and 333 short/repeated taps passed. First 50-ms C3 RMS relative
  to sustained reed RMS improved from 0.1080 to 0.6313. This is energy evidence,
  not an authenticity rating or measured physical touch latency.
- Equal 60% reference levels: harmonium C3 -36.39 LUFS, Sa–Pa -34.03 LUFS,
  Sa–Ma -37.14 LUFS. The 37-note maximum-volume chord plus tanpura peaked at
  0.66575 full scale without clipping. Chords differ in perceived loudness from
  solo notes; phone listening is still required.
- Both 160-second tanpura loop/speed/tuning renders and restarts passed.
- Simulator passed both instruments in portrait and both landscape directions:
  rail edge, tab order, taps, continuous slider interaction, and dynamic icon colors.
- Unsigned arm64 iPhoneOS IPA packaging and asset hashes passed.

[Before: v0.4.0 simulator, one octave](phase41/before-landscape.png) ·
[After: port right](phase41/after-landscape-port-right.png) ·
[After: port left](phase41/after-landscape-port-left.png) ·
[After: portrait](phase41/after-portrait.png) ·
[Tanpura selected](phase41/tanpura-landscape-port-right.png).
Screenshots are unmodified simulator captures; the app still follows system light/dark mode.

[Lifecycle/attack/loudness data](phase41/phase41-results.json) ·
[Pitch data](phase41/harmonium-pitch-results.json) ·
[Polyphony/sustain data](phase41/harmonium-polyphony-results.json) ·
[Validation summary](phase41/validation.txt).

Remaining acceptance is real-iPhone listening and touch testing using the checklist
above, especially natural attacks, subjective balance, physical latency and background
behavior. Phase 4.1 stops here for that test; CI does not certify those device results.
