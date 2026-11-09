"""Spectral lifecycle and tonal attack regressions on actual Apple sampler output."""
import json,sys
from pathlib import Path
import numpy as np
import soundfile as sf
from scipy.signal import periodogram
folder=Path(sys.argv[1]); rows=[]
def read(p):
 y,sr=sf.read(p); return y.mean(axis=1) if y.ndim>1 else y
base=read(folder/'lifecycle_initial.wav')
def fingerprint(y):
 _,p=periodogram(y[12000:45000],48000,nfft=65536); return p/(np.sum(p)+1e-30)
b=fingerprint(base)
def distance(y): return float(np.sum(abs(fingerprint(y)-b)))
for i in range(50):
 d=distance(read(folder/f'lifecycle_{i}.wav')); assert d<.15,(i,d)
 rows.append(d)
print('Unrestored restart spectral distance:',distance(read(folder/'lifecycle_unrestored.wav')))
print('50 restored restart cycles; maximum spectral distance:',max(rows))
attacks=[]
for note in range(36,73):
 y=read(folder/f'note_{note}_0.wav'); stable=np.sqrt(np.mean(y[24000:40000]**2))
 rms=np.sqrt(np.mean(y[:48000].reshape(-1,480)**2,axis=1))
 onset=np.flatnonzero(rms>stable*.3); assert len(onset) and onset[0]<=6,(note,onset)
 for duration in [2400,4800,9600]:
  for rep in range(3):
   tap=read(folder/f'tap_{note}_{duration}_{rep}.wav')
   assert np.sqrt(np.mean(tap**2)) > stable*.2,(note,duration,rep)
 attacks.append(dict(note=note,onset10msWindow=int(onset[0]),sustainedRMS=float(stable)))
report=dict(lifecycleSpectralDistances=rows,unrestoredSpectralDistance=distance(read(folder/'lifecycle_unrestored.wav')),attacks=attacks)
(folder.parent/'phase41-results.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS: 37 tonal attacks and 333 short/repeated notes')
