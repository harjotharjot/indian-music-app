"""Prepare attributed sample loops using FFmpeg's existing crossfade filter."""
import hashlib,json,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'feasibility'))
from benchmark import read_audio,detect
import numpy as np
import soundfile as sf
out=ROOT/'IndianMusic/Sounds';out.mkdir(exist_ok=True)
manifest=[]
for pattern,source in [('pa',ROOT/'feasibility/curated/tanpura_pa_trimmed.wav'),('ma',ROOT/'feasibility/assets/tanpura_ma.mp3')]:
    start,end = (2,26) if pattern=='pa' else (16,40)
    # User-auditioned contamination intervals, with an additional safety margin.
    excluded = [] if pattern=='pa' else [(4.5,13.5)]
    assert all(end <= left or start >= right for left,right in excluded)
    y=read_audio(source)[start*48000:end*48000]
    _,hz=detect(y,'aubio_yinfast_conf90')
    hz=hz[np.isfinite(hz)]
    # Offline calibration around the creator's documented ~138-Hz Sa, not a live tuner.
    folded=hz*2**np.round(np.log2(138/hz))
    candidates=folded[np.abs(1200*np.log2(folded/138))<100]
    reference=float(np.median(candidates))
    target=out/f'tanpura_{pattern}.wav'
    filt=f'[0:a]atrim=start={start+2}:end={end},asetpts=PTS-STARTPTS[body];[1:a]atrim=start={start}:end={start+2},asetpts=PTS-STARTPTS[head];[body][head]acrossfade=d=2:c1=tri:c2=tri,aresample=48000[a]'
    temp=ROOT/'build'/f'tanpura_{pattern}_unnormalized.wav';temp.parent.mkdir(exist_ok=True)
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(source),'-i',str(source),'-filter_complex',filt,'-map','[a]','-ac','2','-c:a','pcm_s16le',str(temp)],check=True)
    data,sr=sf.read(temp,always_2d=True)
    gain=10**(-6/20)/np.max(np.abs(data))
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(temp),'-af',f'volume={gain:.12f}','-c:a','pcm_s16le',str(target)],check=True)
    data,sr=sf.read(target,always_2d=True)
    assert sr==48000 and len(data)==22*sr and np.isfinite(data).all()
    # Boundary continuity relative to ordinary adjacent-sample steps; not a listening test.
    steps=np.abs(np.diff(data,axis=0));jump=float(np.max(np.abs(data[0]-data[-1])))
    assert jump < float(np.percentile(steps,99.9))
    manifest.append(dict(pattern=pattern,file=target.name,referenceHz=reference,
        calibrationSupportFrames=len(candidates),calibrationP10P90Hz=np.percentile(candidates,[10,90]).tolist(),
        sourceExcerptSeconds=[start,end],excludedSourceIntervalsSeconds=excluded,
        durationSeconds=len(data)/sr,sampleRate=sr,channels=data.shape[1],peakDBFS=float(20*np.log10(np.max(np.abs(data)))),
        boundaryJump=jump,adjacentStepP999=float(np.percentile(steps,99.9)),
        sha256=hashlib.sha256(target.read_bytes()).hexdigest(),sourceSha256=hashlib.sha256(source.read_bytes()).hexdigest(),
        sourceURL=f'https://freesound.org/people/sankalp/sounds/{153263 if pattern=="pa" else 153265}/',
        creator='Sankalp Gulati (sankalp)',license='CC-BY-4.0',licenseURL='https://creativecommons.org/licenses/by/4.0/',
        modifications=f'Source seconds {start}–{end}; rotate past first 2 seconds and crossfade tail with head for 2 seconds; normalize peak to -6 dBFS; PCM16 stereo 48kHz.',
        limitations='Derived from MP3 preview; approximate Sa from mixed strings; no independent listening approval. Pa tail was trimmed; Ma source seconds 5–13 contain user-reported speech and are excluded with margin.'))
(out/'tanpura-sources.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(manifest,indent=2))
