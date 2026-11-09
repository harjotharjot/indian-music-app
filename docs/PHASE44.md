# v0.4.4 — portrait access, rotation and keyboard finish

The portrait harmonium now keeps its keyboard and continuous navigation slider
visible beneath a separate scrolling settings pane. Tanpura speed is available
in that pane and through the new portrait settings button. Existing tuning,
volume, transport and mode controls remain available above the keyboard.

Previously the keyboard followed the whole settings form in the scroll view.
Its UIKit attachment code also disabled touch cancellation on ancestor scroll
views, allowing musical touches to interfere with page scrolling. The keyboard
is now a sibling of the settings scroller and no longer changes ancestor scroll
configuration. Playing gestures and the upper black-key midpoint territories
remain unchanged.

Exiting forced Full screen now restores the scene's all-supported-orientations
geometry preference after the requested portrait transition. This clears the
portrait-only scene preference as well as the app orientation mask. The added
same-session regression enters forced landscape, returns to portrait, then
checks ordinary rotation in both directions. Ordinary automatic rotation follows
iPhone orientation lock; the existing Full screen button still overrides it.
The working forced-mode motion tracking and cross-tab persistence are retained.

Landscape harmonium uses the horizontal canvas previously reserved by the notch
safe area, with 24 points on the notch side and 8 points on the other side. The
Tanpura screen retains its existing safe-area behavior. This makes the keybed
wider without changing its aspect ratio or continuous navigation. The inner
navigation container ignores only the notch-side inset, preserving the sibling
switcher rail's layout boundary; ignoring both edges there would overlap the rail.

Black keys have rounded lower ends, using a radius of 48% of their face width.
This is a drawing-only change: upper territories still meet at adjacent black
centers' midpoints, and lower white-key territories are unchanged. The accepted
soundbank, sample processing, audio graph, gain and touch-mapping model have no
changes in this release.

## iPhone checks

1. In portrait, enable the harmonium. Scroll settings to Tanpura speed and adjust
   it. The keyboard and navigation slider should stay visible and playable.
   Also check speed through the toolbar settings button.
2. With orientation lock off, rotate normally in both directions and back to
   portrait. Enter Full screen, return to portrait, and repeat normal rotations
   without restarting the app.
3. With orientation lock on, confirm the existing Full screen button and tab
   switching still work. After holding landscape then turning upright, confirm
   the portrait keyboard returns.
4. Compare the landscape keybed margins and rounded black-key tips. Check the
   same upper midpoint territories and chords, and confirm accepted audio.

No new instruments or features outside these corrections are included.

## Delivered build and validation

[Successful GitHub Actions run — source `0e29539`](https://github.com/harjotharjot/indian-music-app/actions/runs/42663376761)

- [Unsigned v0.4.4 (9) IPA ZIP](https://github.com/harjotharjot/indian-music-app/actions/runs/42663376761/artifacts/13695338559)
- [Full native and simulator test evidence](https://github.com/harjotharjot/indian-music-app/actions/runs/42663376761/artifacts/13694699010)
- [Validation summary](phase44/validation.txt)

Install the extracted IPA over the existing app through SideStore.

All three simulator tests passed on iPhone 16 Pro: scrolling to and adjusting
portrait speed while the keyboard stays pinned; settings-sheet speed access;
forced landscape across tabs and return to portrait followed by normal rotation
both ways in the same session; and both instruments' switcher positions/colors.
Landscape assertions check the notch-side margin is below 40 points, and the
keyboard plus edge controls stay outside the switcher rail. Final captures show
24 points at the notch side, compared with the earlier 86-point inset.

[Portrait](phase44/portrait.png) ·
[Portrait speed and pinned keyboard](phase44/portrait-speed.png) ·
[Landscape, port right](phase44/landscape-port-right.png) ·
[Landscape, port left](phase44/landscape-port-left.png).
These are unmodified simulator captures. The rounded black-key ends are visible
in both orientations, with all landscape controls above the keyboard.

Native regressions passed exact black-key boundary sweeps, filtered crossings,
glissandi, chords/cancellation, persistence, 111 tuned key renders, all 37 keys
across three 32-second comparison banks, attack/lifecycle checks, the isolated
F♯ guard regression, simultaneous audio and long Pa/Ma tanpura renders. Packaging
validated the unsigned arm64 iPhone executable and v0.4.4 (9) metadata.

Physical gravity, Control Center orientation lock and device touch feel still
require the iPhone checklist above; simulator success is not hardware acceptance.
