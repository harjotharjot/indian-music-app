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

from scipy.signal import periodogram
# Non-octave chord tones avoid confusing a lower note's harmonic with a missing voice.
chord=read_audio(folder/'chord.wav')[16800:45600]
freq,power=periodogram(chord,48000,window='hann',nfft=524288)
poly=[]
for note in [48,52,55,58,61,65]:
 target=440*2**((note-69)/12)
 solo=read_audio(folder/f'note_{note}_0.wav')[16800:45600]
 _,reference=periodogram(solo,48000,window='hann',nfft=524288)
 band=abs(freq-target)<2
 ratio=float(power[band].sum()/reference[band].sum())
 assert ratio>.1,(note,ratio)
 poly.append(dict(note=note,powerRelativeToSolo=ratio))
held=read_audio(folder/'held.wav')[24000:]
held=held[:len(held)//4800*4800].reshape(-1,4800)
minimum=float(np.sqrt(np.mean(held*held,axis=1)).min())
assert minimum>.0001,minimum
(folder.parent/'harmonium-polyphony-results.json').write_text(json.dumps(dict(chord=poly,heldMinimum100msRMS=minimum),indent=2)+'\n')
print('PASS: six distinct chord fundamentals, sustained-loop RMS floor',minimum)
