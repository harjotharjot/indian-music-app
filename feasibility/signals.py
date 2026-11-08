"""Test fixtures, not a pitch-detection or pitch-shifting implementation."""
from pathlib import Path
import json
import numpy as np
import soundfile as sf

SR = 48000
FRAME = 4096
HOP = 512
FMIN, FMAX = 60.0, 2200.0
ROOT = Path(__file__).resolve().parent
WORK = ROOT / 'generated'

def tone(frequency, kind='sine', duration=1.0, seed=42):
    t = np.arange(round(SR * duration)) / SR
    f = np.full(len(t), frequency)
    if kind == 'vibrato':
        f *= 2 ** (25 * np.sin(2 * np.pi * 5 * t) / 1200)
    phase = 2 * np.pi * np.cumsum(f) / SR
    amps = [1] if kind == 'sine' else [0.08, 1, 0.65, 0.4, 0.2, 0.15]
    if kind == 'missing_fundamental':
        amps[0] = 0
    y = sum(a * np.sin(h * phase + 0.13 * h) for h, a in enumerate(amps, 1) if h * frequency < SR / 2)
    y *= np.minimum(t / 0.02, 1) * np.minimum((duration - t) / 0.02, 1)
    y = 0.7 * y / max(np.max(np.abs(y)), 1e-9)
    if kind == 'noise_20db':
        rng = np.random.default_rng(seed)
        y += rng.normal(0, np.sqrt(np.mean(y*y)) / 10, len(y))
    return y.astype(np.float32), f

def fixtures():
    for hz in [65.4064, 82.4069, 110, 220, 440, 880, 1760, 2093.005]:
        for cents in [-37, 17]:
            freq = hz * 2 ** (cents / 1200)
            for kind in ['sine', 'reed', 'missing_fundamental']:
                # Stay inside declared detector range.
                yield f'{kind}_{hz:g}_{cents:+d}', kind, *tone(freq, kind)
    for kind in ['vibrato', 'noise_20db']:
        yield kind + '_110', kind, *tone(110, kind)
    yield 'silence', 'silence', np.zeros(SR, dtype=np.float32), np.zeros(SR)
    rng = np.random.default_rng(42)
    yield 'noise_only', 'noise_only', rng.normal(0, .05, SR).astype(np.float32), np.zeros(SR)

def prepare_shifts():
    WORK.mkdir(exist_ok=True)
    rows = []
    for kind in ['sine', 'reed']:
        y, _ = tone(220, kind, duration=3)
        y[:SR//4] = 0
        y[-SR//4:] = 0
        name = f'shift_{kind}.wav'
        sf.write(WORK / name, y, SR, subtype='FLOAT')
        rows.append({'file': name, 'f0': 220, 'role': kind})
    import subprocess
    for file in ['harmonium_A3.wav', 'tanpura_pa.mp3', 'voice_scale.mp3', 'tabla_Da_Test01.wav']:
        source = ROOT / 'assets' / file
        if source.exists():
            name = 'shift_' + source.stem + '.wav'
            subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-t','6','-ar',str(SR),'-ac','1',str(WORK/name)], check=True)
            rows.append({'file': name, 'f0': None, 'role': file.split('_')[0]})
    (WORK / 'shift_inputs.json').write_text(json.dumps(rows, indent=2))

if __name__ == '__main__':
    prepare_shifts()
