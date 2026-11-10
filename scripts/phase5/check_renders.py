"""Compare actual Core Audio renders with independent bol/frame reference sums."""
import pathlib,json,sys,hashlib
import numpy as np
import soundfile as sf
root=pathlib.Path(__file__).resolve().parents[2];out=pathlib.Path(sys.argv[1])
manifest=json.loads((root/'IndianMusic/Sounds/tabla-sources.json').read_text())
samples={}
for e in manifest['samples']:
 p=root/'IndianMusic/Sounds'/e['file'];assert hashlib.sha256(p.read_bytes()).hexdigest()==e['sha256']
 a,sr=sf.read(p,always_2d=True);assert sr==48000 and np.isfinite(a).all() and np.max(abs(a))<.31
 assert np.max(abs(a[-1]))<1e-6
 samples.setdefault(e['bol'],[]).append(a)
patterns={
 'dadra':(['dha','dhin','na','dha','tin','na'],[0,3],[3]),
 'rupak':(['tin','tin','na','dhin','na','dhin','na'],[0,3,5],[0]),
 'keherwa':(['dha','ge','na','ti','na','ke','dhin','na'],[0,4],[4]),
 'teentaal':(['dha','dhin','dhin','dha','dha','dhin','dhin','dha','dha','tin','tin','na','na','dhin','dhin','dha'],[0,4,8,12],[8]),
 'ektaal':(['dhin','dhin',['dha','ge'],['ti','ta','ke','ta'],'tun','na','ke','na',['dha','ge'],['ti','ta','ke','ta'],'dhin','na'],[0,2,4,6,8,10],[2,6]),
 'jhaptal':(['dhin','na','dhin','dhin','na','tin','na','dhin','dhin','na'],[0,2,5,7],[5])}
listening=out.parent/'tabla-listening';listening.mkdir(exist_ok=True)
results=[]
for name,(beats,starts,khali) in patterns.items():
 actual,sr=sf.read(out/(name+'-80bpm.wav'),always_2d=True);assert sr==48000
 reference=np.zeros_like(actual);takes={};events=[]
 for cycle in range(4):
  for index,bols in enumerate(beats):
   if isinstance(bols,str):bols=[bols]
   for sub,bol in enumerate(bols):
    beat=cycle*len(beats)+index+sub/len(bols);frame=round(beat*48000*60/80)
    n=takes.get(bol,0);takes[bol]=n+1;a=samples[bol][n%len(samples[bol])]
    layer=.8 if sub else (1.06 if index in starts and index not in khali else .94)
    end=min(frame+len(a),len(actual));reference[frame:end]+=a[:end-frame]*layer*.8
    events.append({'frame':frame,'bol':bol})
 error=float(np.max(abs(actual-reference)));assert error<2e-5,(name,error)
 # All intended onset frames, variations, overlapping tails and several cycle seams
 # must match the independently summed recordings, not just energy/onset metrics.
 assert np.max(abs(actual))<1 and np.sqrt(np.mean(actual**2))>.005
 sf.write(listening/(name+'-80bpm.flac'),actual,sr,subtype='PCM_24')
 results.append(dict(taal=name,cycles=4,bpm=80,onsets=len(events),maximumWaveformError=error,peak=float(np.max(abs(actual))),seconds=len(actual)/sr))
a,sr=sf.read(out/'all-three-max-faders.wav',always_2d=True);sf.write(listening/'all-three-max-faders.flac',a,sr,subtype='PCM_24')
(out/'waveform-validation.json').write_text(json.dumps(results,indent=2)+'\n')
print('PASS: all six native renders match independent absolute-frame sample sums (<2e-5); complete attacks, round robins, subdivisions, multi-cycle tails, no waveform clipping. Musical acceptance still requires listening.')
