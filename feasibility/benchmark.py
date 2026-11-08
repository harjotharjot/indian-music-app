"""Compare established estimators. Real-audio agreement is NOT ground-truth accuracy."""
import argparse
import json
from pathlib import Path
import platform
import time
import subprocess
import aubio
import librosa
import numpy as np
import scipy
import soundfile as sf
from signals import SR, FRAME, HOP, FMIN, FMAX, ROOT, fixtures

METHODS = ['aubio_yin', 'aubio_yinfft', 'aubio_yinfast', 'librosa_yin', 'librosa_pyin']

def detect(y, method):
    y = np.asarray(y, dtype=np.float32)
    if method.startswith('aubio_'):
        detector = aubio.pitch(method.removeprefix('aubio_'), FRAME, HOP, SR)
        detector.set_unit('Hz')
        detector.set_silence(-50)
        # Upstream defaults: YIN tolerance .15; YINFFT .85. Do not tune on test set.
        values, times = [], []
        for start in range(0, len(y)-HOP+1, HOP):
            values.append(float(detector(y[start:start+HOP])[0]))
            times.append((start + HOP - FRAME/2) / SR)
        values = np.array(values)
        times = np.array(times)
    else:
        params = dict(sr=SR, fmin=FMIN, fmax=FMAX, frame_length=FRAME, hop_length=HOP, center=False)
        if method == 'librosa_pyin':
            values, _, _ = librosa.pyin(y, resolution=0.1, **params)
        else:
            values = librosa.yin(y, **params)
        times = (np.arange(len(values))*HOP + FRAME/2) / SR
    values[(values < FMIN) | (values > FMAX)] = np.nan
    return times, values

def metrics(values, truth):
    valid = np.isfinite(values) & (values > 0)
    voiced = truth > 0
    if not voiced.any():
        return {'false_voiced_pct': float(100*np.mean(valid)), 'frames': len(values)}
    cents = 1200*np.log2(values[valid & voiced] / truth[valid & voiced])
    if not len(cents):
        return {'coverage_pct': 0., 'median_abs_cents': None, 'p95_abs_cents': None,
                'gross_error_pct': None, 'octave_error_pct': None, 'frames': len(values)}
    octaves = np.rint(cents/1200)
    return {'coverage_pct': float(100*np.mean(valid[voiced])),
            'median_abs_cents': float(np.median(np.abs(cents))),
            'p95_abs_cents': float(np.percentile(np.abs(cents),95)),
            'gross_error_pct': float(100*np.mean(np.abs(cents)>50)),
            'octave_error_pct': float(100*np.mean((np.abs(octaves)>=1) & (np.abs(cents-1200*octaves)<50))),
            'frames': len(values)}

def read_audio(path, max_seconds=None):
    y, sr = sf.read(path, always_2d=True)
    y = y.mean(axis=1)
    if max_seconds:
        y = y[:round(sr*max_seconds)]
    if sr != SR:
        y = librosa.resample(y, orig_sr=sr, target_sr=SR)
    return y.astype(np.float32)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', default=str(ROOT/'results/linux'))
    args = parser.parse_args()
    out = Path(args.output)
    out.mkdir(parents=True, exist_ok=True)
    # Warm up import/JIT. Timing excludes first compilation, includes estimator work.
    warm = next(fixtures())[2]
    for method in METHODS:
        detect(warm, method)
    rows = []
    for name, kind, y, truth in fixtures():
        for method in METHODS:
            start = time.perf_counter()
            times, values = detect(y, method)
            elapsed = time.perf_counter()-start
            # Exclude startup and release; compare frame-center instantaneous F0.
            keep = (times >= .3) & (times <= len(y)/SR-.15)
            reference = np.interp(times[keep], np.arange(len(truth))/SR, truth)
            row = dict(case=name, kind=kind, method=method, seconds=elapsed,
                       realtime_factor=elapsed/(len(y)/SR), **metrics(values[keep], reference))
            rows.append(row)
        print(name, flush=True)
    (out/'synthetic.json').write_text(json.dumps(rows, indent=2, allow_nan=False)+'\n')
    sample_rows, real_tracks = [], {}
    for entry in json.loads((ROOT/'samples.json').read_text()):
        path = ROOT/'assets'/entry['file']
        y = read_audio(path)
        peak = float(np.max(np.abs(y)))
        sample_rows.append(dict(file=entry['file'], duration_seconds=len(y)/SR,
          peak_dbfs=float(20*np.log10(max(peak,1e-12))), rms_dbfs=float(20*np.log10(max(np.sqrt(np.mean(y*y)),1e-12))),
          clipped_samples_pct=float(100*np.mean(np.abs(y)>=.999)),
          edge_jump=float(abs(y[-1]-y[0])), channels=sf.info(path).channels,
          source_sample_rate=sf.info(path).samplerate, role=entry['role']))
        if entry['role'] not in ['harmonium','voice']:
            continue
        # Same central excerpt for every estimator, no assumed exact note labels.
        y = y[:8*SR]
        tracks={}
        for method in METHODS:
            times, values = detect(y, method)
            keep = (times>=.3)&(times<=len(y)/SR-.15)
            times, values=times[keep],values[keep]
            tracks[method]={'times':times.tolist(), 'hz':[None if not np.isfinite(v) else float(v) for v in values]}
        real_tracks[entry['file']]=tracks
    (out/'sample_audit.json').write_text(json.dumps(sample_rows,indent=2)+'\n')
    (out/'real_tracks.json').write_text(json.dumps(real_tracks,indent=2,allow_nan=False)+'\n')
    versions=dict(python=platform.python_version(),platform=platform.platform(),numpy=np.__version__,
                  scipy=scipy.__version__,librosa=librosa.__version__,aubio=aubio.version,
                  sample_rate=SR,frame=FRAME,hop=HOP,fmin=FMIN,fmax=FMAX,
                  note='librosa pYIN uses 10-cent bins; default aubio tolerance; no octave correction or smoothing')
    (out/'environment.json').write_text(json.dumps(versions,indent=2)+'\n')

if __name__=='__main__':
    main()
