"""Audit actual banks and native long holds. Metrics flag regressions; listening is
required to accept reed authenticity and whether a repeat remains perceptible.
"""
import json,sys,shutil
from pathlib import Path
import numpy as np
import soundfile as sf
from scipy.signal import correlate,welch
import pyloudnorm as pyln
from sf2_audit import samples,zone_for_note
ROOT=Path(__file__).resolve().parents[2]
folder=Path(sys.argv[1]);out=folder.parent
banks={name:samples(path) for name,path in {
 'phase40':ROOT/'build/baseline-sounds/harmonium.sf2',
 'phase41':ROOT/'build/phase41-sounds/harmonium.sf2',
 'corrected':ROOT/'IndianMusic/Sounds/harmonium.sf2'}.items()}
prep=json.loads((ROOT/'IndianMusic/Sounds/phase42-preparation.json').read_text())
def rms(y):return float(np.sqrt(np.mean(y*y)))+1e-20
def best_corr(x,y,pad=32):
 # y includes pad additional samples at each side.
 c=correlate(y,x,mode='valid',method='fft');cs=np.r_[0,np.cumsum(y*y)]
 energy=cs[len(x):]-cs[:-len(x)]
 return float(np.max(c/np.sqrt(np.maximum(np.dot(x,x)*energy,1e-30))))
def read(path):
 y,sr=sf.read(path);assert sr==48000 and y.ndim==1
 assert np.isfinite(y).all() and np.max(abs(y))<.999
 return y
bank_audit=[]
for old,previous,new in zip(banks['phase40'],banks['phase41'],banks['corrected']):
 # Phase 4.1 changed sample start/gain, but not the looped recording itself.
 a=old['pcm'][old['relativeLoopStart']:old['relativeLoopEnd']]
 b=previous['pcm'][previous['relativeLoopStart']:previous['relativeLoopEnd']]
 assert len(a)==len(b)
 loop_corr=float(np.corrcoef(a,b)[0,1]);assert loop_corr>.99999
 x=old['pcm'][2400:21600];y=new['pcm'][2368:21632]
 corr=best_corr(x,y);assert corr>.999,"Recorded buildup changed"
 sr=new['sampleRate'];s,e=new['relativeLoopStart'],new['relativeLoopEnd']
 assert s/sr>=1.2 and 3.4<(e-s)/sr<6.1
 jump=abs(new['pcm'][e-1]-new['pcm'][s])
 ordinary=np.percentile(abs(np.diff(new['pcm'][s:e])),99.9)
 assert jump<ordinary*1.2,(new['name'],jump,ordinary)
 bank_audit.append(dict(root=new['root'],oldLoopSeconds=len(a)/sr,
   oldRelativeLoopStart=old['relativeLoopStart'],oldRelativeLoopEnd=old['relativeLoopEnd'],
   phase41LoopCorrelation=loop_corr,restoredAttackCorrelation=corr,
   newRelativeLoopStart=s,newRelativeLoopEnd=e,newLoopSeconds=(e-s)/sr,
   wrapStep=float(jump),ordinaryStepP999=float(ordinary)))
# Do not hide a crossfade cancellation behind a continuous endpoint.
for zone in prep['zones']:
 ratio=10**(zone['fadeLevelDifferenceDB']/20);c=zone['correlation']
 midpoint=20*np.log10(np.sqrt(1+ratio*ratio+2*c*ratio)/(1+ratio))
 zone['predictedMidpointCancellationDB']=float(midpoint)
 assert midpoint>-.8,(zone['note'],midpoint)

def spectrum(y):
 f,p=welch(y,48000,nperseg=min(4096,len(y)),noverlap=min(2048,len(y)//2-1))
 edges=np.geomspace(40,16000,25)
 a=np.histogram(f,bins=edges,weights=p)[0]
 return a/(a.sum()+1e-30)
def changes(y,t):
 i=round(t*48000);w=4800
 before=y[i-w:i];after=y[i:i+w]
 return abs(20*np.log10(rms(after)/rms(before))),float(np.sum(abs(spectrum(after)-spectrum(before))))
rows=[];meter=pyln.Meter(48000)
listening=out/'listening';listening.mkdir(exist_ok=True)
for note in range(36,73):
 clips={name:read(folder/name/f'note_{note}.wav') for name in banks}
 for name,y in clips.items():
  assert len(y)==48000*32
  z=zone_for_note(banks[name],note);rate=2**((note-z['root'])/12)
  first=z['relativeLoopEnd']/z['sampleRate']/rate
  period=(z['loopEnd']-z['loopStart'])/z['sampleRate']/rate
  times=np.arange(first,31.8,period)
  assert len(times)>=3,(note,name,times)
  metrics=[changes(y,t) for t in times]
  # Compare against the recording's ordinary motion; do not flatten bellows/reeds.
  natural=[changes(y,t) for t in np.arange(1,31,.125)
           if min(abs(t-times))>.2]
  level95=float(np.percentile([m[0] for m in natural],95))
  spectral95=float(np.percentile([m[1] for m in natural],95))
  if name=='corrected':
   assert max(m[0] for m in metrics)<max(1.0,level95*1.5),(note,'seam level',metrics,level95)
   assert max(m[1] for m in metrics)<max(.25,spectral95*1.5),(note,'seam spectrum',metrics,spectral95)
   blocks=y[24000:len(y)//4800*4800].reshape(-1,4800)
   assert np.sqrt(np.mean(blocks*blocks,axis=1)).min()>1e-4,(note,'silent sustain')
  rows.append(dict(note=note,bank=name,root=z['root'],loopPeriodSeconds=period,
      repetitions=len(times),boundaryTimesSeconds=times.tolist(),
      maxBoundaryLevelChangeDB=max(m[0] for m in metrics),naturalLevelChangeP95DB=level95,
      maxBoundarySpectralL1=max(m[1] for m in metrics),naturalSpectralL1P95=spectral95))
  if note in [48,49,51]:
   # Equal loudness, constant gain per file: preserve the attacks and loop shapes.
   gain=10**((-30-meter.integrated_loudness(y))/20)
   assert np.max(abs(y*gain))<.98
   sf.write(listening/f'{name}_{note}_32s.wav',y*gain,48000,subtype='PCM_16')
  # Full per-key comparison remains lossless, at its original monitor gain.
  sf.write(folder/name/f'note_{note}.flac',y,48000,subtype='PCM_16')
 # A real playback test of restored recorded buildup, including transposed zones.
 c=best_corr(clips['phase40'][2400:21600],clips['corrected'][2368:21632])
 assert c>.995,(note,'native attack differs from original reed',c)
 for name in banks:(folder/name/f'note_{note}.wav').unlink()
(listening/'README.txt').write_text('32-second mono PCM16 Apple-sampler renders, matched to -30 LUFS by constant gain.\n48=C3, 49=C#3, 51=D#3. phase40=original bank, phase41=aggressively trimmed bank, corrected=natural attacks and new loops.\nListen to the opening and several complete repetitions. Metrics do not certify perceptual seamlessness.\n')
report=dict(bankAudit=bank_audit,preparation=prep,renderedLoops=rows,
    limitations='Objective checks are not listening certification. Authentic attacks and perceptually hidden repetition need iPhone acceptance.')
(out/'phase42-results.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS: actual SF2 loop headers, preserved reed prefixes, bounded crossfade cancellation')
print('PASS: 111 native 32-second holds; every playable/transposed key, >=3 wraps each')
print('Minimum native repeats:',min(x['repetitions'] for x in rows if x['bank']=='corrected'))
print('Minimum restored source attack correlation:',min(x['restoredAttackCorrelation'] for x in bank_audit))
print('Listening files:',len(list(listening.glob('*.wav'))),'32-second equal-loudness comparisons')
