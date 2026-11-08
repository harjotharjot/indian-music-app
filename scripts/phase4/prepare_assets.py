"""Offline preparation: existing aubio, FFmpeg and SF2cute; no runtime DSP dependency."""
import hashlib,json,re,subprocess,sys,urllib.request,concurrent.futures
from pathlib import Path
import numpy as np
import soundfile as sf
from pydub import AudioSegment
ROOT=Path(__file__).resolve().parents[2];sys.path.insert(0,str(ROOT/'feasibility'))
from benchmark import read_audio,detect
OUT=ROOT/'IndianMusic/Sounds';WORK=ROOT/'build/phase4';WORK.mkdir(parents=True,exist_ok=True)
PIN='622c2f1c32c8cfce4158ddc3eb26e518ddef37e5'

def pitch(y,expected):
 _,f=detect(y.astype(np.float32),'aubio_yinfast_conf90');f=f[np.isfinite(f)]
 f=f*2**np.round(np.log2(expected/f))
 f=f[np.abs(1200*np.log2(f/expected))<100]
 assert len(f)>10
 return float(np.median(f)),np.percentile(f,[10,90]).tolist()

def tanpuras(pa,ma):
 inputs=[('pa',pa),('ma',ma)]
 manifest=[]
 for pattern,source in inputs:
  # Choose 60 seconds well inside each long recording; preserve stereo and realistic cycles.
  start,end,fade=30,90,3
  temp=WORK/f'{pattern}.wav'
  filt=f'[0:a]atrim=start={start+fade}:end={end},asetpts=PTS-STARTPTS[b];[1:a]atrim=start={start}:end={start+fade},asetpts=PTS-STARTPTS[h];[b][h]acrossfade=d={fade}:c1=tri:c2=tri[a]'
  subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-i',str(source),'-filter_complex',filt,'-map','[a]','-ar','48000','-ac','2',str(temp)],check=True)
  y,sr=sf.read(temp,always_2d=True);gain=10**(-9/20)/abs(y).max()
  target=OUT/f'tanpura_{pattern}.wav';sf.write(target,y*gain,sr,subtype='PCM_16')
  ref,spread=pitch(y[:24*sr].mean(axis=1),130.81278265)
  steps=np.abs(np.diff(y,axis=0));jump=float(np.max(abs(y[0]-y[-1])))
  assert jump<np.percentile(steps,99.9)
  manifest.append(dict(pattern=pattern,file=target.name,referenceHz=ref,durationSeconds=len(y)/sr,boundaryJump=jump*gain,adjacentStepP999=float(np.percentile(steps,99.9))*gain,sourceExcerptSeconds=[start,end],excludedSourceIntervalsSeconds=[],sha256=hashlib.sha256(target.read_bytes()).hexdigest(),sourceSha256=hashlib.sha256(source.read_bytes()).hexdigest(),sourceFile=source.name,sourceURL=None,creator='User-supplied recording; original creator not specified',license='Not specified; supplied for this private app, no public redistribution license assumed',calibrationP10P90Hz=spread,modifications='Seconds 30–90; rotate first 3 seconds into a 3-second tail crossfade; -9 dBFS peak; stereo PCM16 48 kHz.',limitations='C reference estimated from mixed-string recording. No independent listening confirmation. Original MP3 uploads remain in session attachments.'))
 (OUT/'tanpura-sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print('Tanpura',[(r['pattern'],r['referenceHz'],r['durationSeconds']) for r in manifest],flush=True)

def harmonium():
 url=f'https://api.github.com/repos/nbrosowsky/tonejs-instruments/contents/samples/harmonium?ref={PIN}'
 files=[x for x in json.load(urllib.request.urlopen(url)) if x['name'].endswith('.wav')]
 def get(item):
  path=WORK/item['name']
  if not path.exists():path.write_bytes(urllib.request.urlopen(item['download_url'],timeout=60).read())
  return path
 with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:paths=list(pool.map(get,files))
 rows=[];tsv=[]
 for path in sorted(paths):
  note=path.stem;m=re.fullmatch(r'([A-G])(s?)(\d)',note);pc={'C':0,'D':2,'E':4,'F':5,'G':7,'A':9,'B':11}[m[1]]+bool(m[2]);midi=(int(m[3])+1)*12+pc
  y=read_audio(path);step=480
  rms=np.sqrt(np.mean(y[:len(y)//step*step].reshape(-1,step)**2,axis=1))
  onset=max(0,(np.flatnonzero(rms>rms.max()*.06)[0]*step)-240)
  raw=y[onset:];expected=440*2**((midi-69)/12)
  ref,spread=pitch(raw[24000:120000],expected)
  ratio=expected/ref
  trimmed=WORK/f'{note}-trim.wav';sf.write(trimmed,raw,48000,subtype='PCM_16')
  corrected=WORK/f'{note}-corrected.wav'
  subprocess.run(['ffmpeg','-v','error','-y','-i',str(trimmed),'-af',f'asetrate={48000*ratio:.9f},aresample=48000',str(corrected)],check=True)
  looped=WORK/f'{note}-loop.wav'
  recording=AudioSegment.from_wav(corrected)
  recording[:2500].append(recording[500:550],crossfade=50).export(looped,format='wav')
  data,sr=sf.read(looped);assert len(data)==120000
  data*=10**(-12/20)/abs(data).max()
  pcm=WORK/f'{note}.pcm';sf.write(WORK/f'{note}-ready.wav',data,48000,subtype='PCM_16');pcm.write_bytes((np.clip(data,-1,1)*32767).astype('<i2').tobytes()+bytes(128))
  measured,_=pitch(data[30000:110000],expected);error=1200*np.log2(measured/expected)
  assert abs(error)<4,(note,error)
  rows.append(dict(note=note,midi=midi,sourceURL='https://freesound.org/people/donyaquick/sounds/330410/',downloadURL=f'https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/{PIN}/samples/harmonium/{path.name}',sourceSha256=hashlib.sha256(path.read_bytes()).hexdigest(),referenceHzBefore=ref,referenceSpreadHz=spread,pitchCorrectionCents=float(1200*np.log2(ratio)),measuredPreparedErrorCents=float(error),trimmedLeadingSeconds=onset/48000,loopStartFrame=26400,loopEndFrame=120000))
  rows[-1]['includedInSoundfont'] = midi not in [37,38,40,42]
  if rows[-1]['includedInSoundfont']: tsv.append(f'{midi} {pcm} 26400 120000')
  else: rows[-1]['exclusionReason'] = 'Octave-ambiguous low-register source in native sampler checks; neighboring recorded notes cover this key within one semitone.'
 (WORK/'samples.tsv').write_text('\n'.join(tsv)+'\n')
 subprocess.run([str(WORK/'build-sf2'),str(WORK/'samples.tsv'),str(OUT/'harmonium.sf2')],check=True)
 (OUT/'harmonium-sources.json').write_text(json.dumps(dict(soundfontSHA256=hashlib.sha256((OUT/'harmonium.sf2').read_bytes()).hexdigest(),creator='donyaquick; WAV distribution by nbrosowsky/tonejs-instruments',license='CC0-1.0',licenseURL='https://creativecommons.org/publicdomain/zero/1.0/',upstreamCommit=PIN,writer='SF2cute 3c5fc83b6ba3d1feb377f9c86021fd77499eb7c0 (zlib/libpng license), build-time only',modifications='Trim leading silence; retune each recorded note to A440 equal temperament using FFmpeg; retain attack; crossfade sustain join; -12 dBFS peak; 80-ms sampler release.',notes=rows),indent=2)+'\n')
 print('Harmonium',len(rows),'samples; worst prepared median cents',max(abs(r['measuredPreparedErrorCents']) for r in rows),flush=True)

if __name__=='__main__':
 import argparse
 parser=argparse.ArgumentParser()
 parser.add_argument('--pa',type=Path);parser.add_argument('--ma',type=Path)
 parser.add_argument('--harmonium-only',action='store_true')
 args=parser.parse_args()
 if not args.harmonium_only:
  if args.pa is None or args.ma is None:parser.error('--pa and --ma must name the user-supplied originals')
  tanpuras(args.pa,args.ma)
 harmonium()
