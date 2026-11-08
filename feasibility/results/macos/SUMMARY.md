# Measured results: macos

Each cell aggregates clip-level metrics. Errors use voiced estimates only; coverage is reported separately.
Octave errors are measured before any correction. No octave folding, smoothing or confidence gating was added.

| Detector | Signal group | Mean coverage % | Median clip error (cents) | Worst clip p95 (cents) | Mean octave errors % |
|---|---|---:|---:|---:|---:|
| aubio_yin | sine | 100.0 | 0.02 | 1.19 | 0.00 |
| aubio_yin | reed | 100.0 | 0.03 | 1.42 | 0.00 |
| aubio_yin | missing_fundamental | 100.0 | 0.03 | 1.42 | 0.00 |
| aubio_yin | vibrato | 100.0 | 8.88 | 13.25 | 0.00 |
| aubio_yin | noise_20db | 100.0 | 0.47 | 1.03 | 0.00 |
| aubio_yinfft | sine | 100.0 | 14.26 | 1901.71 | 6.25 |
| aubio_yinfft | reed | 87.5 | 1.80 | 1901.66 | 7.14 |
| aubio_yinfft | missing_fundamental | 87.5 | 1.79 | 1901.66 | 7.14 |
| aubio_yinfft | vibrato | 100.0 | 2.11 | 3.55 | 0.00 |
| aubio_yinfft | noise_20db | 100.0 | 1.53 | 2.11 | 0.00 |
| aubio_yinfast | sine | 100.0 | 0.02 | 1.19 | 0.00 |
| aubio_yinfast | reed | 100.0 | 0.03 | 1.42 | 0.00 |
| aubio_yinfast | missing_fundamental | 100.0 | 0.03 | 1.42 | 0.00 |
| aubio_yinfast | vibrato | 100.0 | 8.88 | 13.25 | 0.00 |
| aubio_yinfast | noise_20db | 100.0 | 0.47 | 1.03 | 0.00 |
| librosa_yin | sine | 100.0 | 0.02 | 1.19 | 0.00 |
| librosa_yin | reed | 100.0 | 0.03 | 1.41 | 0.00 |
| librosa_yin | missing_fundamental | 100.0 | 0.03 | 1.41 | 0.00 |
| librosa_yin | vibrato | 100.0 | 8.88 | 13.24 | 0.00 |
| librosa_yin | noise_20db | 100.0 | 0.47 | 1.03 | 0.00 |
| librosa_pyin | sine | 100.0 | 3.00 | 3.64 | 0.00 |
| librosa_pyin | reed | 100.0 | 3.00 | 3.64 | 0.00 |
| librosa_pyin | missing_fundamental | 100.0 | 3.00 | 3.64 | 0.00 |
| librosa_pyin | vibrato | 100.0 | 7.86 | 15.26 | 0.00 |
| librosa_pyin | noise_20db | 100.0 | 0.64 | 0.64 | 0.00 |

| Detector | Silence false voiced % | Noise false voiced % | Median compute/audio duration ratio |
|---|---:|---:|---:|
| aubio_yin | 0.0 | 37.3 | 0.0687 |
| aubio_yinfft | 0.0 | 0.0 | 0.0013 |
| aubio_yinfast | 0.0 | 37.3 | 0.0016 |
| librosa_yin | 0.0 | 98.0 | 0.0079 |
| librosa_pyin | 0.0 | 0.0 | 0.2817 |

## Real recordings: agreement only

YINFFT, YINFAST, librosa YIN and pYIN are compared with aubio YIN on coincident voiced frames.
These are related algorithms, so agreement does not establish correctness. No manual F0 labels exist.

| Recording | Detector | Median Hz | Voiced coverage % | Median absolute difference from aubio YIN (cents) | Difference > 50 cents % |
|---|---|---:|---:|---:|---:|
| harmonium_A2.wav | aubio_yin | 110.56 | 100.0 | 0.00 | 0.0 |
| harmonium_A2.wav | aubio_yinfft | 110.58 | 100.0 | 0.28 | 0.4 |
| harmonium_A2.wav | aubio_yinfast | 110.56 | 100.0 | 0.00 | 0.0 |
| harmonium_A2.wav | librosa_yin | 110.56 | 100.0 | 0.00 | 0.1 |
| harmonium_A2.wav | librosa_pyin | 110.68 | 100.0 | 1.91 | 0.1 |
| harmonium_A3.wav | aubio_yin | 221.21 | 100.0 | 0.00 | 0.0 |
| harmonium_A3.wav | aubio_yinfft | 221.22 | 100.0 | 0.11 | 0.0 |
| harmonium_A3.wav | aubio_yinfast | 221.21 | 100.0 | 0.00 | 0.0 |
| harmonium_A3.wav | librosa_yin | 221.21 | 100.0 | 0.00 | 0.0 |
| harmonium_A3.wav | librosa_pyin | 221.36 | 100.0 | 1.16 | 0.0 |
| harmonium_A4.wav | aubio_yin | 442.57 | 100.0 | 0.00 | 0.0 |
| harmonium_A4.wav | aubio_yinfft | 442.58 | 100.0 | 0.02 | 6.8 |
| harmonium_A4.wav | aubio_yinfast | 442.57 | 100.0 | 0.00 | 0.0 |
| harmonium_A4.wav | librosa_yin | 442.57 | 100.0 | 0.00 | 0.0 |
| harmonium_A4.wav | librosa_pyin | 442.71 | 100.0 | 0.54 | 0.0 |
| harmonium_C2.wav | aubio_yin | 65.42 | 100.0 | 0.00 | 0.0 |
| harmonium_C2.wav | aubio_yinfft | 130.85 | 100.0 | 1200.72 | 70.0 |
| harmonium_C2.wav | aubio_yinfast | 65.42 | 100.0 | 0.00 | 0.0 |
| harmonium_C2.wav | librosa_yin | 65.42 | 100.0 | 0.00 | 1.1 |
| harmonium_C2.wav | librosa_pyin | 65.43 | 100.0 | 0.81 | 1.1 |
| harmonium_C3.wav | aubio_yin | 131.20 | 100.0 | 0.00 | 0.0 |
| harmonium_C3.wav | aubio_yinfft | 131.22 | 100.0 | 0.18 | 0.0 |
| harmonium_C3.wav | aubio_yinfast | 131.20 | 100.0 | 0.00 | 0.0 |
| harmonium_C3.wav | librosa_yin | 131.20 | 100.0 | 0.00 | 0.1 |
| harmonium_C3.wav | librosa_pyin | 130.86 | 100.0 | 4.50 | 0.8 |
| harmonium_C4.wav | aubio_yin | 262.76 | 100.0 | 0.00 | 0.0 |
| harmonium_C4.wav | aubio_yinfft | 262.78 | 100.0 | 0.12 | 0.0 |
| harmonium_C4.wav | aubio_yinfast | 262.76 | 100.0 | 0.00 | 0.0 |
| harmonium_C4.wav | librosa_yin | 262.76 | 100.0 | 0.00 | 0.0 |
| harmonium_C4.wav | librosa_pyin | 263.24 | 100.0 | 3.12 | 0.0 |
| harmonium_C5.wav | aubio_yin | 526.62 | 100.0 | 0.00 | 0.0 |
| harmonium_C5.wav | aubio_yinfft | 526.72 | 100.0 | 0.31 | 0.0 |
| harmonium_C5.wav | aubio_yinfast | 526.62 | 100.0 | 0.00 | 0.0 |
| harmonium_C5.wav | librosa_yin | 526.62 | 100.0 | 0.00 | 0.0 |
| harmonium_C5.wav | librosa_pyin | 526.48 | 100.0 | 0.53 | 0.0 |
| voice_male.mp3 | aubio_yin | 233.16 | 95.2 | 0.00 | 0.0 |
| voice_male.mp3 | aubio_yinfft | 233.28 | 95.2 | 1.73 | 4.0 |
| voice_male.mp3 | aubio_yinfast | 233.16 | 95.2 | 0.00 | 0.0 |
| voice_male.mp3 | librosa_yin | 233.13 | 100.0 | 0.01 | 3.8 |
| voice_male.mp3 | librosa_pyin | 233.17 | 95.4 | 2.03 | 4.0 |
| voice_scale.mp3 | aubio_yin | 278.10 | 55.2 | 0.00 | 0.0 |
| voice_scale.mp3 | aubio_yinfft | 278.06 | 56.4 | 5.42 | 0.3 |
| voice_scale.mp3 | aubio_yinfast | 278.10 | 55.2 | 0.00 | 0.0 |
| voice_scale.mp3 | librosa_yin | 278.21 | 61.2 | 0.00 | 0.0 |
| voice_scale.mp3 | librosa_pyin | 278.89 | 60.8 | 2.49 | 0.0 |

## Existing aubio confidence threshold

| Policy | Noise false voiced % | Silence false voiced % | Mean steady-tone coverage % |
|---|---:|---:|---:|
| aubio_yinfast | 37.3 | 0.0 | 100.0 |
| aubio_yinfast_conf90 | 0.0 | 0.0 | 100.0 |

| Recording | Policy | Voiced coverage % |
|---|---|---:|
| harmonium_A2.wav | aubio_yinfast | 100.0 |
| harmonium_A2.wav | aubio_yinfast_conf90 | 99.9 |
| harmonium_A3.wav | aubio_yinfast | 100.0 |
| harmonium_A3.wav | aubio_yinfast_conf90 | 100.0 |
| harmonium_A4.wav | aubio_yinfast | 100.0 |
| harmonium_A4.wav | aubio_yinfast_conf90 | 100.0 |
| harmonium_C2.wav | aubio_yinfast | 100.0 |
| harmonium_C2.wav | aubio_yinfast_conf90 | 98.9 |
| harmonium_C3.wav | aubio_yinfast | 100.0 |
| harmonium_C3.wav | aubio_yinfast_conf90 | 99.9 |
| harmonium_C4.wav | aubio_yinfast | 100.0 |
| harmonium_C4.wav | aubio_yinfast_conf90 | 100.0 |
| harmonium_C5.wav | aubio_yinfast | 100.0 |
| harmonium_C5.wav | aubio_yinfast_conf90 | 100.0 |
| voice_male.mp3 | aubio_yinfast | 95.2 |
| voice_male.mp3 | aubio_yinfast_conf90 | 83.8 |
| voice_scale.mp3 | aubio_yinfast | 55.2 |
| voice_scale.mp3 | aubio_yinfast_conf90 | 54.7 |

## Pitch shift

Apple files intentionally retain one second of render tail. Container duration is not a claim of tempo drift.
Active spans use 10-ms RMS bins and a relative -30 dB threshold; this is a coarse envelope diagnostic.

| Engine | Fixture | Worst median cents error across shifts | Worst active-duration difference (ms) |
|---|---|---:|---:|
| apple | shift_harmonium_A3.wav | nan | 10 |
| apple | shift_recorded_mix.wav | nan | 10 |
| apple | shift_reed.wav | 0.03 | 20 |
| apple | shift_sine.wav | 0.03 | 20 |
| apple | shift_tabla_Da_Test01.wav | nan | 0 |
| apple | shift_tanpura_pa.wav | nan | 20 |
| apple | shift_voice_scale.wav | nan | 0 |
| rubberband_r3 | shift_harmonium_A3.wav | nan | 10 |
| rubberband_r3 | shift_recorded_mix.wav | nan | 0 |
| rubberband_r3 | shift_reed.wav | 0.03 | 20 |
| rubberband_r3 | shift_sine.wav | 0.03 | 20 |
| rubberband_r3 | shift_tabla_Da_Test01.wav | nan | 0 |
| rubberband_r3 | shift_tanpura_pa.wav | nan | 0 |
| rubberband_r3 | shift_voice_scale.wav | nan | 0 |
