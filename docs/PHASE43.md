# v0.4.3 — F sharp, keyboard layout and full-screen practice

## Isolated F♯3 click

The accepted v0.4.2 bank has a zero-filled sample at F♯3's loop-end interpolation
boundary. Its loop-start value is -12520 in PCM16, far from zero. Native Apple
sampler renders showed a one-sample excursion toward zero at 9.228 seconds and
every following return (approximately 14.61, 19.99, 25.36 and 30.74 seconds).
This is an interpolation-padding discontinuity, separate from the earlier attack
and crossfade problems. It was especially audible on this reed because of its
large waveform amplitude at the chosen boundary.

The fix fills 64 interpolation-padding frames with the corresponding loop-start
continuation. The musical sample, attack, loop points, gain and every other reed
remain unchanged. `fix_fsharp_guard.py` reproduces the edit against the accepted
bank; `Sounds/phase43-fsharp.json` records hashes, location and first value.

The regression uses the actual Apple sampler, compares before/after 32-second
F♯3 holds, checks high-frequency impulse energy at all five returns, and verifies
F♯2/F♯4 plus all unrelated bank PCM remain unchanged. The old return peak was
3.37 times its ordinary high-band reference; after correction it was about 0.76
of that reference. Listening comparisons are supplied, rather than treating a
metric as perceptual acceptance.

## Upper hit regions and proportions

This supersedes the earlier small-side-tolerance behavior, following the supplied
red-line diagram:

- The entire area from key tops through black-key tip height belongs only to black
  keys, including the visibly white gaps. There are no upper white-key islands.
- Adjacent black territories meet at the horizontal midpoint between their centers,
  including across B/C and E/F gaps. The right neighbor begins exactly at the
  midpoint. First/last black territories extend to the viewport edge.
- Below that split, each white key owns its ordinary width. Both drawing and touch
  mapping use the same continuous viewport offset. Off-keyboard points release.
- White-key height/width targets 4.05, black width is 56% of white width, and black
  height is 61% of white height, following the reference's proportions. White
  widths retain a 44-point minimum. Landscape density therefore adapts to available
  height and is roughly 14 white keys on the test phone, rather than forcing 16.
- Portrait keeps approximately one visible white-key octave with the same aspect
  target. The slider remains continuous across C2–C5.
- Sa/cents, sargam toggle, tanpura transport/mode and settings access are above the
  landscape keyboard. Portrait's existing tuning/mixer controls now precede its
  keyboard in the scroll view. Nothing is removed. Note labels remain on keys;
  instrument navigation retains its existing rail/bottom-bar location.
- The monochrome tanpura silhouette rotates clockwise 45 degrees and retains
  exactly the same dynamic selection coloring/background logic.

Immediate taps, adaptive slide filtering, multitouch and cancellation/release
behavior remain. Tests sweep upper-region points, exact adjacent-black midpoints,
viewport positions, lower white regions and both portrait/landscape dimensions.

## Portrait Full screen button

The harmonium's portrait navigation bar has a Full screen button. It requests
real landscape scene geometry using the public iOS 16+ `requestGeometryUpdate`
API and an app-level supported-orientation mask; no private UIDevice setter or
fake rotated drawing is used. The state belongs to the app, so changing to the
tanpura tab preserves landscape mode. Both instruments provide an explicit exit.

For automatic portrait return, Core Motion gravity is sampled at 5 Hz only while
forced mode is active and the app is foregrounded. This detects physical movement
when system rotation lock suppresses ordinary orientation notifications. Stable
landscape first arms return; stable upright portrait then exits forced mode and
requests portrait geometry. Holding the phone upright while pressing Full screen
does not immediately undo the request. Flat/transient poses do not cause flips.
The simulator/sensor-unavailable fallback uses device orientation. Sensors stop
when the app backgrounds or forced mode ends; no motion history is saved.

A completed geometry request explicitly resynchronizes the actual window-scene
orientation, including a locked-device 180-degree turn that need not resize the
view or produce UIDevice notifications. The rail still follows the port side and
uses the existing orientation-dependent ordering.

Model tests exercise gravity classification, initial upright entry, landscape
arming, transient/flat rejection and portrait return. Simulator tests enter from
portrait, change tabs, remain wide while the phone is upright, then simulate a
landscape-to-portrait movement and verify the portrait interface returns.
Actual Control Center rotation-lock behavior and physical gravity still require
an iPhone test; the simulator does not reproduce that hardware/system setting.

## iPhone check

1. Install over the current app through SideStore. Hold F♯3 for 32 seconds and
   compare the supplied before/after files. Also confirm F♯2/F♯4 and accepted notes.
2. Tap upper white-looking gaps: only the nearest black note should sound. Check
   both sides of each midpoint, including B/C and E/F gaps, at several slider
   positions. Below black tips, white notes should work normally.
3. Compare the new proportions and above-keyboard controls in both landscape
   directions; check all prior controls, volume balance, chords and note release.
4. Turn on iPhone portrait orientation lock. From portrait, tap Full screen. Switch
   to Tanpura and back: landscape should remain. Physically hold landscape, then
   turn upright: portrait should resume. Repeat for both landscape directions.
5. Check explicit Exit full screen on both tabs, starting while held upright, and
   background/resume. Tanpura background playback should retain existing behavior.

Stop after this correction for real-device acceptance; no new instrument work.

## Delivered build and evidence

[Successful build — source `322c8cb`](https://github.com/harjotharjot/indian-music-app/actions/runs/42582420347)

- [Unsigned v0.4.3 (8) IPA ZIP](https://github.com/harjotharjot/indian-music-app/actions/runs/42582420347/artifacts/13658246081)
- [F♯3 before/after 32-second audio](https://github.com/harjotharjot/indian-music-app/actions/runs/42582420347/artifacts/13657982032)
- [Full tests, all-key holds and simulator recordings](https://github.com/harjotharjot/indian-music-app/actions/runs/42582420347/artifacts/13658176447)

Install the extracted IPA over the existing app through SideStore.

Native F♯3 return-window high-band RMS fell from 0.003953 to 0.000887, about
13 dB. Its ordinary high-band reference stayed unchanged at 0.001173. F♯2 and
F♯4's before/after native samples were identical; unrelated bank PCM was identical.
The five tested F♯3 returns were at 9.228, 14.607, 19.985, 25.364 and 30.742 seconds.

All 37 keys × three 32-second comparison banks, 111 tuning cases, 100 lifecycle
cycles, short taps, sustain/chords, release/cancellation, faders, clipping, long
tanpura renders and package validation passed. Geometry tests passed upper-region
black-only sweeps, exact black-center midpoints, lower white regions and the new
aspect ratio. Simulator tests passed manual full-screen entry, cross-tab
persistence, physical-rotation fallback return, ordinary portrait/both landscape
directions, above-keyboard controls and selection colors.

Screenshots: [landscape, port right](phase43/landscape-port-right.png) ·
[landscape, port left](phase43/landscape-port-left.png) ·
[portrait settings and Full screen button](phase43/portrait.png) ·
[tanpura with rotated icon](phase43/tanpura-landscape.png).
Portrait settings scroll above the keyboard; the Full screen button stays in the
navigation bar. Screenshots are unmodified simulator captures.

[F♯ regression data](phase43/phase43-fsharp-results.json) ·
[Shared lifecycle/loudness suite](phase43/phase41-results.json) ·
[Pitch results](phase43/harmonium-pitch-results.json) ·
[Validation summary](phase43/validation.txt).

Real-iPhone listening, physical gesture feel and Control Center orientation-lock
behavior remain to be accepted using the checklist above. No claim of hardware
verification is made from simulator tests.
