"""Reproducible Naad sample selection; no synthesis, pitch shifting or tail loops."""
import pathlib,json,hashlib,subprocess,urllib.request,math,sys
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parents[1]/"phase51"))
from onsets import onset
import numpy as np
import soundfile as sf
from scipy.signal import resample_poly
ROOT=pathlib.Path(__file__).resolve().parents[2]
PIN='0e881b669f370b916efe429e4db79fd66bfb18b0'
manifestPath=ROOT/'IndianMusic/Sounds/tabla-sources.json'
expected={s['sourcePath']:s['sourceSHA256'] for s in json.loads(manifestPath.read_text())['samples']} if manifestPath.exists() else {}
SELECT={'dha':('Dha',['01','02'],.30),'dhin':('Dhin',['01','03'],.29),'na':('Na',['01'],.22),'tin':('Tin',['01'],.22),'tun':('Tun',['01'],.22),'ge':('Ge',['01','03'],.25),'ke':('Ke',['07','09'],.16),'ti':('Ti',['09','10'],.14),'ta':('Ta',['05','06'],.14)}
out=ROOT/'IndianMusic/Sounds/Tabla';out.mkdir(exist_ok=True)
entries=[]
for bol,(folder,takes,target) in SELECT.items():
 group=[]
 for take in takes:
  path=f'Bol/{folder}/{folder}{take}.wav';url=f'https://raw.githubusercontent.com/oormicreations/naad/{PIN}/{path}'
  local=pathlib.Path('/tmp/naad-source')/path
  raw=local.read_bytes() if local.exists() else urllib.request.urlopen(url).read()
  if path in expected:assert hashlib.sha256(raw).hexdigest()==expected[path],path
  import io
  a,sr=sf.read(io.BytesIO(raw),always_2d=True)
  group.append((path,url,raw,a,sr))
 gain=target/max(np.max(np.abs(a)) for _,_,_,a,_ in group)
 for index,(path,url,raw,a,sr) in enumerate(group):
  # Keep the whole source: no aggressive onset trim and no fabricated decay.
  if a.shape[1]==1:a=np.repeat(a,2,axis=1)
  a=resample_poly(a,160,147,axis=0) if sr==44100 else a
  assert sr==44100
  a*=gain
  # 0.125-ms boundary de-click; 45-ms fade of residual tail/noise only.
  n=6;a[:n]*=np.linspace(0,1,n)[:,None]
  n=min(2160,len(a));a[-n:]*=(.5+.5*np.cos(np.linspace(0,np.pi,n)))[:,None]
  name=f'{bol}-{index+1}.wav';dest=out/name;sf.write(dest,a,48000,subtype='PCM_24')
  entries.append(dict(bol=bol,file='Tabla/'+name,onsetFrame=onset(sf.read(dest,always_2d=True)[0]),sourcePath=path,sourceURL=url,sourceSHA256=hashlib.sha256(raw).hexdigest(),sha256=hashlib.sha256(dest.read_bytes()).hexdigest(),frames=len(a),sourceSampleRate=sr,sourceChannels=group[index][3].shape[1],seconds=len(a)/48000,gain=gain,peak=float(np.max(abs(a))),tailFadeSeconds=.045))
manifest=dict(library='Naad recorded tabla bols',repository='https://github.com/oormicreations/naad',revision=PIN,creator='Oormi Creations and Contributors; individual recording performers not identified by upstream',license='MIT',processing='Whole recordings; 44.1 to 48 kHz polyphase resampling; mono duplicated to stereo; one gain per bol family; 0.125-ms initial de-click and 45-ms final cosine fade; no synthesis, pitch shift or repeated tails.',samples=entries)
manifest['timing']='Complete unmodified recordings are scheduled onsetFrame frames early against a common 480-frame pre-roll. Landmark: first causal 48-frame RMS crossing of 8% of first-250-ms maximum; louder channel. No peak alignment, trimming or independent manipulation of combined Dha/Dhin.'
(ROOT/'IndianMusic/Sounds/tabla-sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
licenseText=pathlib.Path('/tmp/naad-source/LICENSE.txt').read_text() if pathlib.Path('/tmp/naad-source/LICENSE.txt').exists() else urllib.request.urlopen(f'https://raw.githubusercontent.com/oormicreations/naad/{PIN}/LICENSE.txt').read().decode()
(ROOT/'IndianMusic/Sounds/Tabla/LICENSE.txt').write_text(licenseText)
print(PIN,len(entries),'recorded samples')
