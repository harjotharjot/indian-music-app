"""One-sample interpolation-guard click regression on actual Apple output."""
import json,sys
from pathlib import Path
import numpy as np
import soundfile as sf
from scipy.signal import butter,sosfilt
import pyloudnorm as pyln
from sf2_audit import samples,zone_for_note
root=Path(__file__).resolve().parents[2];out=Path(sys.argv[1])
before_bank=samples(root/'build/phase42-accepted-sounds/harmonium.sf2')
after_bank=samples(root/'IndianMusic/Sounds/harmonium.sf2')
assert len(before_bank)==len(after_bank)
for a,b in zip(before_bank,after_bank):
 assert a['root']==b['root'] and a['loopStart']==b['loopStart'] and a['loopEnd']==b['loopEnd']
 if a['root']!=54:assert np.array_equal(a['pcm'],b['pcm']),(a['root'],'Unrelated reed changed')
 else:
  e,s=a['relativeLoopEnd'],a['relativeLoopStart']
  assert np.array_equal(a['pcm'][:e],b['pcm'][:e])
  assert np.array_equal(b['pcm'][e:e+64],b['pcm'][s:s+64])
  assert np.array_equal(a['pcm'][e+64:],b['pcm'][e+64:])
rows=[]
for note in [42,54,66]:
 old,sr=sf.read(out/'fsharp-before'/f'note_{note}.wav')
 new,_=sf.read(out/'comparisons/corrected'/f'note_{note}.flac')
 if note!=54:
  error=float(np.sqrt(np.mean((old-new)**2))/np.sqrt(np.mean(old*old)))
  assert error<.001,(note,'Unrelated native F sharp changed',error)
  rows.append(dict(note=note,relativeNativeError=error));continue
 zone=zone_for_note(after_bank,note)
 first=zone['relativeLoopEnd']/sr;period=(zone['loopEnd']-zone['loopStart'])/sr
 times=np.arange(first,31.9,period)
 filt=butter(3,6000,fs=sr,btype='high',output='sos')
 def measure(y):
  high=sosfilt(filt,y);hop=240
  windows=np.sqrt(np.mean(high[:len(high)//hop*hop].reshape(-1,hop)**2,axis=1))
  # Use the note's own ordinary HF envelope, excluding the specific return sites.
  sample_times=np.arange(len(windows))*.005
  ordinary=windows[(sample_times>1)&np.array([min(abs(t-times))>.02 for t in sample_times])]
  p99=float(np.percentile(ordinary,99))
  spikes=[]
  for t in times:
   i=round(t*sr);spikes.append(float(np.sqrt(np.mean(high[i-120:i+120]**2))))
  return dict(maxReturnRMS=max(spikes),ordinaryP99RMS=p99,ratio=max(spikes)/p99,returns=spikes)
 oldm,newm=measure(old),measure(new)
 assert oldm['ratio']>2,(oldm,'Failed to reproduce the old click')
 assert newm['ratio']<1.5,newm
 assert newm['maxReturnRMS']<oldm['maxReturnRMS']*.5,(oldm,newm)
 listening=out/'fsharp-listening';listening.mkdir(exist_ok=True);meter=pyln.Meter(sr)
 for label,y in [('before-v042',old),('corrected',new)]:
  gain=10**((-30-meter.integrated_loudness(y))/20);assert abs(y*gain).max()<.98
  sf.write(listening/f'Fsharp3-{label}-32s.wav',y*gain,sr,subtype='PCM_16')
 (listening/'README.txt').write_text('F#3: 32-second native Apple sampler renders, equal loudness. Old click at about 9.23s, 14.61s, 19.99s, 25.36s, 30.74s. Only interpolation guard samples changed.\n')
 rows.append(dict(note=note,before=oldm,corrected=newm,boundaryTimes=times.tolist()))
 print('F#3 high-band return/ordinary ratio before and after:',oldm['ratio'],newm['ratio'])
(out/'phase43-fsharp-results.json').write_text(json.dumps(rows,indent=2)+'\n')
print('PASS: F#3 click reproduced and reduced; F#2/F#4 and all unrelated bank samples unchanged')
