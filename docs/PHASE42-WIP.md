# Harmonium correction — paused checkpoint

User requested stopping to conserve tokens. This is unfinished, unvalidated work.
No correction IPA or GitHub Actions build has been started for these changes.

## Findings

- Phase 4.1 trimmed 0–380 ms of natural reed buildup and applied a 6-ms fade.
- Phase 4.0 and 4.1 both use fixed 550–2500-ms loops, with a 50-ms crossfade.
  Source recordings actually contain 7–12 seconds of held material.
- Retuned raw-source correlation across the old fixed crossfade was about 0.056
  for C3, -0.021 for C#3, and -0.273 for D#3: mixing out-of-phase/uncorrelated
  reed material can cause a perceptible energy/timbre dip even with a continuous
  wrap point. These are analysis findings, not listening certification.

## Work saved, not accepted

- New offline `scripts/phase4/prepare_natural_harmonium.py` uses original sources,
  retains natural buildup with a 45-ms half-cosine transient fade, selects longer
  phase/level-matched sustain sections, and applies unity-sum pre-loop crossfades.
- Candidate bank and `Sounds/phase42-preparation.json` generated. Loop lengths
  roughly 3.5–6 seconds. Several complex reeds remain less correlated (G#3 ~0.76,
  D3 ~0.84, E3 ~0.85); do not declare perceptually seamless from these metrics.
- Lifecycle fix, shared engine, monitor calibration, navigation and rail unchanged.
- User explicitly selected displayed black-key shapes with small side tolerance.
  Candidate hit testing uses visible black rectangles plus 3 points horizontally,
  stops at their bottom edge, and gives full visible tips black-key priority.
- Added candidate 6/12/18-ms speed-adaptive filtering for changes under an existing
  finger; initial taps remain immediate. Timer/cancellation integration is drafted.
- Added boundary/slide model tests and a native 32-second-per-note comparison
  harness for Phase 4.0, Phase 4.1 and corrected banks in separate processes.
- Removed the old speed-based attack acceptance gates; realistic buildup must take
  precedence. Version draft is 0.4.2 (7).

## Resume

1. Review/compile Swift touch/filter changes and run new model tests on macOS CI.
2. Finish actual-SF2 loop/attack audit and native comparison analysis; inspect all
   playable keys, transposed zones, repeated loop energy/spectra, and source attack
   preservation. `scripts/phase4/sf2_audit.py` is drafted for actual SF2 headers.
3. Add appropriate workflow checks/artifacts for comparison renders. Existing
   `check_phase41.py` is partially adapted; a dedicated correction analysis is not
   yet written. Do not treat it as completed verification.
4. Check retained loudness calibration, clipping, note release, and existing tests.
5. Produce clearly labeled before/after long audio comparisons, then build unsigned
   IPA after checks pass. Explain perceptual limits; phone listening is decisive.
6. Stop for user acceptance. No tabla or unrelated features.

Raw recordings, prepared references, exploratory audits and logs remain under
`build/phase42/` in this workspace (ignored by Git). The pinned SF2cute checkout is
`/workspace/work/sf2cute`; analysis environment `/workspace/work/audio-venv`.
