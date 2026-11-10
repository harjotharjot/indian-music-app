# Phase 5 — recorded tabla accompaniment

The accepted v0.4.4 (9) harmonium/tanpura baseline is retained. Tabla adds one
standard basic theka for Dadra, Rupak, Keherwa, Teentaal, Ektaal and Jhaptal,
independent transport/volume and a third compact instrument tab. This is the
Phase 5 audition build; musical authenticity and device performance require
real-iPhone acceptance. No microphone tuner, recording library, pitch shifter,
advanced compositions or multitrack recording is implemented.

## Recorded sources and selection

Shipping samples come from [Naad](https://github.com/oormicreations/naad), pinned
to `0e881b669f370b916efe429e4db79fd66bfb18b0`. Its README identifies the WAVs as
actual individual tabla strokes; the repository includes an MIT notice covering
Oormi Creations and Contributors. The original performer/session attribution is
not supplied upstream; no named performer or independent studio-quality claim
is inferred. The notice is bundled and readable in Tabla's Sound credits.

15 selected recordings cover nine bol/sample families: Dha ×2, Dhin ×2, Ge ×2,
Ke ×2, Ti ×2, muted Ta ×2, Na ×1, Tin ×1 and Tun ×1. Recorded combined Dha and
Dhin preserve simultaneous dayan/bayan attack and decay. Compatible variants alternate without pitch or timing jitter.
Single Na/Tin/Tun recordings are retained instead of mixing the library's other
noticeably differently tuned sets. Tabla retains source pitch: changing Sa or
cents adjusts the accepted instruments, not these percussion recordings.

The whole selected source waveform is retained: **no onset trim, synthesis,
time stretch, sustained sample loop, manufactured tail or reverb**. Standard
polyphase conversion changes 44.1 kHz to 48 kHz; mono is duplicated to stereo.
A family-wide gain preserves the takes' relative dynamics. A 0.125-ms boundary
fade removes initial nonzero sample edges, and a 45-ms final cosine fade removes
residual noise at the source endpoint. Resonant recordings last approximately
0.9–2.0 seconds, rather than the research corpus's half-second endpoints.
Natural acoustic quality still requires listening approval.

[Exact source URLs, source/output hashes, durations and gains](../IndianMusic/Sounds/tabla-sources.json) ·
[Bundled MIT notice](../IndianMusic/Sounds/Tabla/LICENSE.txt) ·
[Reproducible preparation script](../scripts/phase5/prepare_samples.py).
The script requires numpy, scipy and soundfile and fetches the pinned sources
when the research checkout is absent. Production has no Python dependency.

Alternatives examined:

- Phase 2's [Subodh Deolekar dataset](https://doi.org/10.5281/zenodo.4327350)
  provides 50 takes of each stroke, CC BY 4.0, recorded from professional players.
  Its resonant examples end around 0.5 s; the inspected Ge tail still has RMS
  about 0.018 in its last 100 frames. These short classifier clips were not
  preferred over the longer library recordings for sustained accompaniment.
- [IIT Bombay's 4-way corpus](https://doi.org/10.5281/zenodo.7110248), CC BY 4.0,
  contains isolated tabla performances and broad damped/resonant category
  annotations, not per-bol one-shot labels. Extracting and relabeling such phrases
  would require additional musical annotation. No extracted fragments ship.
- Marius Miron's CC0 Freesound pack contains longer dayan/closed-stroke recordings
  but no complete compatible open-bayan set. Pete Lockett samples in tabla-js
  mention project-specific permission; that permission was not assumed to
  transfer. Neither library ships in this app.

## Theka references

Definitions were checked against the notated thekas and clap/wave arrangements
in David and Chandrakantha Courtney's
[Index of Tals](https://chandrakantha.com/music-and-dance/i-class-music/index-of-tals/).
Spelling is normalized for display. This is reference verification, not an
independent musician's listening endorsement.

| Taal | Vibhags | Khali starts (matra) | Basic theka |
|---|---|---|---|
| [Dadra](https://chandrakantha.com/music-and-dance/i-class-music/index-of-tals/dadra-tal/) | 3+3 | 4 | Dha Dhin Na / Dha Tin Na |
| [Rupak](https://chandrakantha.com/music-and-dance/i-class-music/index-of-tals/rupak/) | 3+2+2 | **1 (sam)** | Tin Tin Na / Dhin Na / Dhin Na |
| [Keherwa](https://chandrakantha.com/music-and-dance/i-class-music/index-of-tals/kaherava/) | 4+4 | 5 | Dha Ge Na Ti / Na Ka Dhin Na |
| [Teentaal](https://chandrakantha.com/music-and-dance/i-class-music/index-of-tals/tintal/) | 4+4+4+4 | 9 | Dha Dhin Dhin Dha / Dha Dhin Dhin Dha / Dha Tin Tin Na / Na Dhin Dhin Dha |
| [Ektaal](https://chandrakantha.com/music-and-dance/i-class-music/index-of-tals/ektal/) | 2+2+2+2+2+2 | 3, 7 | Dhin Dhin / DhaGe TiRaKiTa / Tun Na / Kat Ta / DhaGe TiRaKiTa / Dhin Na |
| [Jhaptal](https://chandrakantha.com/music-and-dance/i-class-music/index-of-tals/jhaptal/) | 2+3+2+3 | 6 | Dhin Na / Dhin Dhin Na / Tin Na / Dhin Dhin Na |

Ektaal's DhaGe occupies one matra (two half-matra strokes); TiRaKiTa occupies
one matra (four quarter-matra strokes). Ka/Kat use closed bayan Ke; Ektaal's
resonant standalone Ta uses Na, whereas Ra/Ta inside TiRaKiTa uses the muted
right-hand recording. Rupak marks sam clearly but keeps it khali, without an
added bass stroke or heavy sam accent. One basic form is provided per taal;
this does not model every gharana, vilambit elaboration or tempo-specific variant.

## Audio implementation

`TablaTimeline` computes each onset from its absolute musical position and tempo
segment, rounded once to a 48-kHz frame. There is no cumulative rounded-beat
addition. A private serial dispatch queue replenishes 120 ms of scheduling every
20 ms; its timer does not trigger musical strokes. `AVAudioPlayerNode` performs
sample playback at specified audio times, with a shared host-time start. The UI
polls the audio-derived matra at 10 Hz only for display while foregrounded.
Opening the stable taal-selection sheet pauses display refresh, with audio
scheduling continuing independently; closing it catches up to the audio clock.

24 preattached sample voices allow complete tails to overlap across beats and
cycles, without cutting/restarting a single cycle buffer. Three preloaded dynamic
layers give lighter subdivisions and restrained vibhag accents. Samples and all
layers are decoded before starting. No files or buffer allocations are needed
in an audio render callback; no custom render DSP callback is added.

The engine paths are:

- Tabla voices → tabla source fade → **tabla dry bus** → independent monitor fader.
- Existing harmonium sampler → harmonium dry bus → existing monitor fader.
- Existing tanpura players/time-pitch → tanpura dry bus → existing monitor fader.

All share the existing engine/main mixer. No taps or microphone capture are
installed. Accepted instrument gains, soundfont, keyboard geometry, hitboxes,
slider, Full screen motion logic and settings keys are unchanged.

Tempo (30–240 BPM) changes at the next unscheduled integer matra, preserving
already queued events and musical phase. Taal changes finish old subdivisions
before the next unscheduled matra, start the new sam there and let old tails
finish. Stop clears only tabla players after a short source-bus gain ramp.
Pause freezes the tabla players' queued audio and phase; Resume continues it.
Fresh starts reset only the tabla fade mixer before its first scheduled stroke,
so native fader smoothing does not soften the attack. Pause/stop allow the native
gain ramp to finish before freezing or clearing a tail.
When tabla alone is paused, the engine is paused to avoid unnecessary rendering;
other active instruments keep their clock running. Changing tabs never stops
accompaniment; releasing held harmonium keys retains accepted behavior.

Background audio uses the existing playback session. Interruption recovery
remembers which accompaniments were playing and restarts those at a clean sam
only when the session permits resume. It does not resume previously held
harmonium notes. Headphone disconnect stops audio pending user action. Engine
configuration loss/media-services reset rebuilds or restarts the shared graph.
The lock-screen pause/play pair controls the currently active accompaniment(s),
with the existing tanpura default when neither is active.

## Real-iPhone checklist

1. Install over v0.4.4 through SideStore; verify existing Sa, cents, slider range,
   volumes and tanpura speed survived. Listen to all six supplied four-cycle demos
   and compare live playback. Check bol identity, bayan/dayan balance, natural
   attack/decay, repetition and Ektaal's subdivisions, including at slow tempo.
2. For each taal, verify matra count, sam and khali, especially Rupak's khali sam.
   Start, Pause, Resume and Stop repeatedly. Adjust BPM slowly and rapidly;
   change taals during playback and while paused. Listen for stray/stacked strokes
   or clicks and check that transitions land on the promised next matra.
3. Play each instrument alone, each pair and all three; vary each fader from zero
   to full while the others continue. Try harmonium chords and the Pa/Ma switch,
   including louder settings. Listen for distortion or unexpected ducking.
4. Check portrait, both landscape directions and their three-tab order; enter
   harmonium Full screen with rotation lock on, visit Tabla/Tanpura, and physically
   return upright. With lock off, check normal rotation after exiting Full screen.
   Scroll portrait harmonium settings to speed while its keyboard remains visible.
5. Lock the screen/background for several minutes with tabla alone and with
   tanpura. Check live timing on return and lock-screen transport. Test a phone
   call/Siri interruption, headphone/Bluetooth disconnect/reconnect and speaker
   route changes. Confirm safe stop/resume and no stuck harmonium notes.
6. Run a longer practice session at slow and fast BPM; assess timing against an
   external reference, touch latency, battery, warmth and any dropouts. Simulator
   and offline tests cannot establish these physical-device properties.

Stop after Phase 5 for the user's listening/device approval before Phase 6.

## Delivered build, listening files and results

**v0.5.0 (10)**, source `71f264d`:

- [Successful GitHub Actions build](https://github.com/harjotharjot/indian-music-app/actions/runs/42762225037)
- [Unsigned IPA ZIP for SideStore](https://github.com/harjotharjot/indian-music-app/actions/runs/42762225037/artifacts/13738307893)
- [Six-taal listening ZIP plus all-three mix](https://github.com/harjotharjot/indian-music-app/actions/runs/42762225037/artifacts/13738342699)
- [Complete test evidence, original WAV renders and simulator recordings](https://github.com/harjotharjot/indian-music-app/actions/runs/42762225037/artifacts/13738302882)

Extract the IPA ZIP in Files and install the IPA over the existing app through
SideStore. No bundle identifier or signing requirement changed. GitHub sign-in
is required; Actions artifacts expire after 30 days and can be rebuilt.

The listening ZIP contains lossless 48-kHz stereo FLACs. Each solo demonstration
uses 80 BPM, four complete cycles, the full tabla fader and three extra seconds
for the final tails. The app's initial tabla fader is 60%. The complete test
artifact also contains the original uncompressed native WAVs.

| File | Matras | Length |
|---|---:|---:|
| `dadra-80bpm.flac` | 6 | 21 s |
| `rupak-80bpm.flac` | 7 | 24 s |
| `keherwa-80bpm.flac` | 8 | 27 s |
| `teentaal-80bpm.flac` | 16 | 51 s |
| `ektaal-80bpm.flac` | 12 | 39 s |
| `jhaptal-80bpm.flac` | 10 | 33 s |
| `all-three-max-faders.flac` | Ektaal at 240 BPM, six-note harmonium chord, Pa drone | 8 s |

All checks passed:

- **Rhythm/model:** six reference sequences and vibhags, khali/sam, Ektaal's
  subdivisions; 12-hour timing models at 30, 80, 137 and 240 BPM stay within
  half a sample frame of absolute expected times. Phase-continuous tempo edits,
  validation and settings serialization passed.
- **Native offline audio:** all six four-cycle renders match independently
  summed sample waveforms at their expected frames, with maximum absolute error
  below `4.6e-8`. This verifies actual sample placement, alternate takes,
  subdivisions and overlapping tails across several cycles. Pause/resume matches
  uninterrupted audio after the native gain ramp; restart preserves the attack.
  A five-minute native offline render at 137 BPM, tempo edits and all six taal
  changes had no late events or exhausted voices.
- **Mixing:** maximum faders, a six-note harmonium chord and each of the six taals
  at 240 BPM with both Pa and Ma remained finite and unclipped. The included
  eight-second all-three demonstration peaks near **−6.79 dBFS**. Independent bus
  mutes preserve the other instruments; silent buses become silent as expected.
- **Simulator:** five tests passed on iPhone 16 Pro: portrait speed scrolling with
  the accepted pinned keyboard; Full screen across three tabs and normal rotation
  after return; synthetic interruption/engine-loss recovery; three-tab selection,
  ordering and layouts in portrait/both landscape directions; tabla transport,
  live taal/tempo change, background/foreground return and persisted settings.
  The complete 16-matra grid remains visible beside its controls in landscape.
  Test notification controls are compiled only in Debug regression launches and
  are absent from the Release IPA.
- **Accepted baseline:** the harmonium bank, harmonium touch model, keyboard
  rendering, PracticeView and both tanpura recordings are unchanged from v0.4.4.
  Native regressions passed 111 pitches, all-key long holds, attack/lifecycle and
  F♯ checks, chords/release, exact hitbox sweeps, navigation, independent faders,
  persistent settings and long Pa/Ma renders. Packaging verified arm64 iPhoneOS,
  the unsigned bundle, version metadata and every shipped sound hash.

[Validation summary](phase5/validation.txt) ·
[Native waveform data](phase5/waveform-validation.json) ·
[Listening-file metrics](phase5/listening-metrics.json).

Unmodified simulator captures: [Tabla portrait](phase5/tabla-portrait.png) ·
[Tabla landscape, port right](phase5/tabla-landscape-port-right.png) ·
[Tabla landscape, port left](phase5/tabla-landscape-port-left.png) ·
[Accepted harmonium landscape](phase5/harmonium-landscape.png) ·
[Portrait harmonium speed access](phase5/harmonium-portrait-speed.png).

These results establish implementation behavior, not musical authenticity,
physical-device latency, battery use or long background reliability. Those remain
for the real-iPhone checklist and the user's Phase 5 acceptance.
