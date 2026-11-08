"""Measure actual Apple sampler renders with established aubio YINFAST."""
import json,sys
from pathlib import Path
import numpy as np
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'feasibility'))
from benchmark import detect,read_audio
folder=Path(sys.argv[1]);rows=[]
for path in sorted(folder.glob('note_*.wav')):
 _,note,cents=path.stem.split('_');expected=440*2**((int(note)-69+int(cents)/100)/12)
 y=read_audio(path);t,f=detect(y,'aubio_yinfast_conf90');f=f[(t>.3)&(t<.85)];valid=np.isfinite(f)
 assert valid.mean()>.95,(path,valid.mean())
 error=abs(1200*np.log2(f[valid]/expected));median=float(np.median(error))
 onset=np.flatnonzero(abs(y)>.0001)
 rows.append(dict(file=path.name,medianAbsCents=median,p95AbsCents=float(np.percentile(error,95)),firstAboveMinus80dBMilliseconds=float(onset[0]/48) if len(onset) else None))
 assert median<4,(path.name,median)
assert len(rows)==111
(folder.parent/'harmonium-pitch-results.json').write_text(json.dumps(rows,indent=2)+'\n')
print('PASS:',len(rows),'native sampler pitches; worst median cents',max(r['medianAbsCents'] for r in rows))
print('Render-only onset, ms median/max:',np.median([r['firstAboveMinus80dBMilliseconds'] for r in rows]),max(r['firstAboveMinus80dBMilliseconds'] for r in rows))
