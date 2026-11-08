"""Create compact measured tables from committed raw results."""
import json
from pathlib import Path
import numpy as np
from signals import ROOT
from benchmark import METHODS


def main():
    for directory in sorted((ROOT/'results').iterdir()):
        source=directory/'synthetic.json'
        if not source.exists():continue
        rows=json.loads(source.read_text())
        lines=['# Measured results: '+directory.name,'',
          'Each cell aggregates clip-level metrics. Errors use voiced estimates only; coverage is reported separately.',
          'Octave errors are measured before any correction. No octave folding, smoothing or confidence gating was added.','',
          '| Detector | Signal group | Mean coverage % | Median clip error (cents) | Worst clip p95 (cents) | Mean octave errors % |',
          '|---|---|---:|---:|---:|---:|']
        for method in METHODS:
            for group in ['sine','reed','missing_fundamental','vibrato','noise_20db']:
                subset=[r for r in rows if r['method']==method and r['kind']==group]
                if not subset:continue
                errors=[r['median_abs_cents'] for r in subset if r['median_abs_cents'] is not None]
                p95=[r['p95_abs_cents'] for r in subset if r['p95_abs_cents'] is not None]
                octave=[r['octave_error_pct'] for r in subset if r['octave_error_pct'] is not None]
                lines.append(f"| {method} | {group} | {np.mean([r['coverage_pct'] for r in subset]):.1f} | {np.median(errors) if errors else float('nan'):.2f} | {max(p95) if p95 else float('nan'):.2f} | {np.mean(octave) if octave else float('nan'):.2f} |")
        lines+=['','| Detector | Silence false voiced % | Noise false voiced % | Median compute/audio duration ratio |',
                '|---|---:|---:|---:|']
        for method in METHODS:
            sub=[r for r in rows if r['method']==method]
            false={r['kind']:r.get('false_voiced_pct') for r in sub if 'false_voiced_pct' in r}
            lines.append(f"| {method} | {false.get('silence',0):.1f} | {false.get('noise_only',0):.1f} | {np.median([r['realtime_factor'] for r in sub]):.4f} |")
        tracksfile=directory/'real_tracks.json'
        if tracksfile.exists():
            lines+=['','## Real recordings: agreement only','',
              'YINFFT, YINFAST, librosa YIN and pYIN are compared with aubio YIN on coincident voiced frames.',
              'These are related algorithms, so agreement does not establish correctness. No manual F0 labels exist.','',
              '| Recording | Detector | Median Hz | Voiced coverage % | Median absolute difference from aubio YIN (cents) | Difference > 50 cents % |',
              '|---|---|---:|---:|---:|---:|']
            for file,tracks in json.loads(tracksfile.read_text()).items():
                baseline=tracks['aubio_yin'];bt=np.array(baseline['times']);bv=np.array(baseline['hz'],dtype=float)
                for method,track in tracks.items():
                    t=np.array(track['times']);v=np.array(track['hz'],dtype=float)
                    # Round to nearest frame, do not interpolate over unvoiced intervals.
                    idx=np.abs(bt[:,None]-t[None,:]).argmin(axis=0)
                    b=bv[idx]; valid=np.isfinite(v)&np.isfinite(b)&(np.abs(bt[idx]-t)<.012)
                    delta=np.abs(1200*np.log2(v[valid]/b[valid]))
                    median=float(np.nanmedian(v)) if np.isfinite(v).any() else float('nan')
                    lines.append(f"| {file} | {method} | {median:.2f} | {100*np.mean(np.isfinite(v)):.1f} | {np.median(delta) if len(delta) else float('nan'):.2f} | {100*np.mean(delta>50) if len(delta) else float('nan'):.1f} |")
        confidencefile=directory/'confidence.json'
        if confidencefile.exists():
            data=json.loads(confidencefile.read_text())
            lines+=['','## Existing aubio confidence threshold','',
                '| Policy | Noise false voiced % | Silence false voiced % | Mean steady-tone coverage % |',
                '|---|---:|---:|---:|']
            for method in ['aubio_yinfast','aubio_yinfast_conf90']:
                sub=[r for r in data['synthetic'] if r['method']==method]
                controls={r['kind']:r for r in sub if 'false_voiced_pct' in r}
                steady=[r for r in sub if r['kind'] in ['sine','reed','missing_fundamental']]
                lines.append(f"| {method} | {controls['noise_only']['false_voiced_pct']:.1f} | {controls['silence']['false_voiced_pct']:.1f} | {np.mean([r['coverage_pct'] for r in steady]):.1f} |")
            lines+=['','| Recording | Policy | Voiced coverage % |','|---|---|---:|']
            for row in data['real']:
                lines.append(f"| {row['file']} | {row['method']} | {row['coverage_pct']:.1f} |")
        shiftsfile=directory/'shifts.json'
        if shiftsfile.exists():
            shifts=json.loads(shiftsfile.read_text())
            lines+=['','## Pitch shift','',
              'Apple files intentionally retain one second of render tail. Container duration is not a claim of tempo drift.',
              'Active spans use 10-ms RMS bins and a relative -30 dB threshold; this is a coarse envelope diagnostic.','',
              '| Engine | Fixture | Worst median cents error across shifts | Worst active-duration difference (ms) |',
              '|---|---|---:|---:|']
            for engine in ['apple','rubberband_r3']:
                for fixture in sorted(set(r['file'] for r in shifts)):
                    sub=[r for r in shifts if r['engine']==engine and r['file']==fixture]
                    errs=[r['median_abs_cents'] for r in sub if r.get('median_abs_cents') is not None]
                    spans=[]
                    for r in sub:
                        a,b=r['input_active_span'],r['output_active_span']
                        if a[0] is not None and b[0] is not None:spans.append(abs((b[1]-b[0])-(a[1]-a[0]))*1000)
                    lines.append(f"| {engine} | {fixture} | {max(errs) if errs else float('nan'):.2f} | {max(spans) if spans else float('nan'):.0f} |")
        (directory/'SUMMARY.md').write_text('\n'.join(lines)+'\n')

if __name__=='__main__':main()
