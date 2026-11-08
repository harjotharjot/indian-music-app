"""Evaluate aubio's existing confidence output as an explicit rejection policy."""
import argparse,json
from pathlib import Path
import numpy as np
from benchmark import detect,metrics,read_audio
from signals import ROOT,SR,fixtures

parser=argparse.ArgumentParser()
parser.add_argument('--output',default=str(ROOT/'results/linux'))
args=parser.parse_args()
rows=[]
for name,kind,y,truth in fixtures():
    for method in ['aubio_yinfast','aubio_yinfast_conf90']:
        times,values=detect(y,method)
        keep=(times>=.3)&(times<=len(y)/SR-.15)
        reference=np.interp(times[keep],np.arange(len(truth))/SR,truth)
        rows.append(dict(case=name,kind=kind,method=method,**metrics(values[keep],reference)))
real=[]
for entry in json.loads((ROOT/'samples.json').read_text()):
    if entry['role'] not in ['harmonium','voice']:continue
    y=read_audio(ROOT/'assets'/entry['file'],max_seconds=8)
    for method in ['aubio_yinfast','aubio_yinfast_conf90']:
        times,values=detect(y,method)
        values=values[(times>=.3)&(times<=len(y)/SR-.15)]
        real.append(dict(file=entry['file'],method=method,coverage_pct=float(100*np.mean(np.isfinite(values)))))
out=Path(args.output);out.mkdir(parents=True,exist_ok=True)
(out/'confidence.json').write_text(json.dumps({'synthetic':rows,'real':real},indent=2,allow_nan=False)+'\n')
