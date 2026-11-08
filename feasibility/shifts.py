"""Render Apple TimePitch vs Rubber Band, then measure without hiding tail latency."""
import argparse
import json
import subprocess
from pathlib import Path
import numpy as np
import soundfile as sf
from benchmark import detect, metrics, read_audio
from signals import ROOT, WORK, SR, prepare_shifts

SHIFTS = [-600, -300, -100, -17, 17, 100, 300, 600]

def active_span(y):
    # 10-ms RMS bins, relative -30 dB threshold; coarse diagnostic, not perceptual truth.
    step = SR//100
    y=y[:len(y)//step*step].reshape(-1,step)
    rms=np.sqrt(np.mean(y*y,axis=1))
    active=np.flatnonzero(rms>max(np.max(rms)*10**(-30/20),1e-6))
    return [float(active[0]/100),float((active[-1]+1)/100)] if len(active) else [None,None]

def run():
    parser=argparse.ArgumentParser()
    parser.add_argument('--native', required=True)
    parser.add_argument('--output',default=str(ROOT/'results/macos'))
    args=parser.parse_args()
    out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
    prepare_shifts()
    rows=[]
    for entry in json.loads((WORK/'shift_inputs.json').read_text()):
        source=WORK/entry['file']
        original=read_audio(source)
        for cents in SHIFTS:
            for engine in ['apple','rubberband_r3']:
                target=WORK/f'{source.stem}_{engine}_{cents:+d}.wav'
                if engine=='apple':
                    command=[args.native,str(source),str(target),str(cents)]
                else:
                    command=['rubberband','-3','-p',str(cents/100),str(source),str(target)]
                completed=subprocess.run(command,check=True,text=True,capture_output=True)
                y=read_audio(target)
                row=dict(file=entry['file'],engine=engine,cents=cents,
                         input_seconds=len(original)/SR,output_seconds=len(y)/SR,
                         input_active_span=active_span(original),output_active_span=active_span(y),
                         peak=float(np.max(np.abs(y))),finite=bool(np.isfinite(y).all()),
                         render_log=completed.stdout.strip())
                if entry['f0']:
                    times,hz=detect(y,'aubio_yin')
                    keep=(times>.6)&(times<2.3)
                    row.update(metrics(hz[keep],np.full(sum(keep),entry['f0']*2**(cents/1200))))
                rows.append(row)
                print(engine,source.name,cents,flush=True)
    (out/'shifts.json').write_text(json.dumps(rows,indent=2,allow_nan=False)+'\n')
    # Functional acceptance; voice/full-mix quality cannot be established by pitch error alone.
    for row in rows:
        assert row['finite'] and row['peak']>1e-5, row
        if row['file']=='shift_sine.wav':
            assert row['coverage_pct']>95 and row['median_abs_cents']<5, row
        if row['engine']=='rubberband_r3':
            assert abs(row['input_seconds']-row['output_seconds'])<.03,row

if __name__=='__main__':
    run()
