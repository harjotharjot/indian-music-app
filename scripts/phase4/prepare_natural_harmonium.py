"""Offline reed preparation using FFmpeg resampling/fades and SciPy correlation.
Keep natural attacks; select long sustain loops before applying a phase-aligned
constant-gain crossfade. No runtime DSP or replacement synthesis.
"""
import argparse, hashlib, json, subprocess
from pathlib import Path
import numpy as np
import soundfile as sf
from scipy.signal import correlate, find_peaks, welch

SR=48000

def spectral_shape(x):
    f,p=welch(x,SR,nperseg=4096,noverlap=2048)
    bands=np.histogram(f,bins=np.geomspace(40,16000,25),weights=p)[0]
    return bands/(bands.sum()+1e-30)

def seam_measurements(y,start,end,n):
    # Compare the actual baked crossfade with the recorded material AFTER the
    # return. A phase/level match alone can still reset the reed's harmonic mix.
    before=y[end-4800:end].copy()
    a=np.linspace(0,1,n)
    before[-n:]=before[-n:]*(1-a)+y[start-n:start]*a
    after=y[start:start+4800]
    spectral=float(np.sum(abs(spectral_shape(before)-spectral_shape(after))))
    level=abs(float(20*np.log10(np.sqrt(np.mean(after*after)/np.mean(before*before)))))
    return spectral,level

def choose_loop(y, hz):
    best=None
    for fade_seconds in sorted(set([max(.015,3/hz), max(.03,4/hz), max(.045,6/hz)])):
        n=round(fade_seconds*SR)
        half_period=round(SR/hz*4)
        # Steady recorded material only; never loop into the attack. Long loops keep
        # the source's reed/bellows movement instead of repeating a synthetic cycle.
        for s in np.arange(1.25,2.76,.125):
            start=round(s*SR); head=y[start-n:start]
            he=np.dot(head,head)
            for duration in np.arange(3.5,6.01,.125):
                end=round((s+duration)*SR)
                if end+half_period+SR//5>=len(y):continue
                search=y[end-n-half_period:end+half_period]
                dots=correlate(search,head,mode='valid',method='fft')
                cs=np.r_[0,np.cumsum(search*search)]
                energies=cs[n:]-cs[:-n]
                correlations=dots/np.sqrt(np.maximum(he*energies,1e-25))
                ix=int(np.argmax(correlations)); corr=float(correlations[ix]); end+=ix-half_period
                tail=y[end-n:end]
                level=abs(float(20*np.log10(np.sqrt(np.mean(tail*tail)/np.mean(head*head)))))
                # Also compare level and slope over 200-ms neighborhoods, to avoid
                # replacing a quiet/reedy body with a bright/loud one at every wrap.
                w=SR//5
                def rms(a):return np.sqrt(np.mean(a*a))+1e-12
                body_db=abs(20*np.log10(rms(y[end-w:end])/rms(y[start-w:start])))
                slope=abs(20*np.log10(rms(y[end:end+w])/rms(y[end-w:end]))-
                          20*np.log10(rms(y[start:start+w])/rms(y[start-w:start])))
                if corr < .72: continue
                spectral,seam_level=seam_measurements(y,start,end,n)
                if seam_level > .6: continue
                score=(1-corr)*10+spectral*50+seam_level*5+level*.22+body_db*.12+slope*.10-duration*.015
                row=dict(start=start,end=end,fade=n,correlation=corr,fadeLevelDifferenceDB=level,
                         bodyLevelDifferenceDB=float(body_db),envelopeSlopeDifferenceDB=float(slope),spectralDistance=spectral,seamLevelDifferenceDB=seam_level,score=float(score))
                if best is None or score<best['score']:best=row
    # A few multi-reed recordings decorrelate over time. Search their entire
    # later sustain rather than forcing an arbitrary millisecond grid match.
    if best['correlation'] < .98 or best['spectralDistance'] > .15:
        for fade_seconds in [max(.015,3/hz), max(.03,4/hz), max(.045,6/hz)]:
            n=round(fade_seconds*SR)
            for seconds in np.arange(1.25,min(4.51,len(y)/SR-3.75),.1):
                start=round(seconds*SR); head=y[start-n:start]
                lo=start+round(3.5*SR)-n; hi=min(start+6*SR,len(y)-SR//5)
                search=y[lo:hi];dots=correlate(search,head,mode='valid',method='fft')
                cs=np.r_[0,np.cumsum(search*search)];eng=cs[n:]-cs[:-n]
                cc=dots/np.sqrt(np.maximum(np.dot(head,head)*eng,1e-25))
                peaks,_=find_peaks(cc,distance=max(1,round(SR/hz/2)))
                for ix in peaks[np.argsort(cc[peaks])[-64:]]:
                    end=lo+int(ix)+n;tail=y[end-n:end];corr=float(cc[ix])
                    level=abs(float(20*np.log10(np.sqrt(np.mean(tail*tail)/np.mean(head*head)))))
                    w=SR//5
                    body_db=abs(20*np.log10(rms(y[end-w:end])/rms(y[start-w:start])))
                    slope=abs(20*np.log10(rms(y[end:end+w])/rms(y[end-w:end]))-
                              20*np.log10(rms(y[start:start+w])/rms(y[start-w:start])))
                    duration=(end-start)/SR
                    if corr < .72: continue
                    spectral,seam_level=seam_measurements(y,start,end,n)
                    if seam_level > .6: continue
                    score=(1-corr)*10+spectral*50+seam_level*5+level*.22+body_db*.12+slope*.10-duration*.015
                    if score<best['score']:
                        best=dict(start=start,end=end,fade=n,correlation=corr,fadeLevelDifferenceDB=level,
                            bodyLevelDifferenceDB=float(body_db),envelopeSlopeDifferenceDB=float(slope),spectralDistance=spectral,seamLevelDifferenceDB=seam_level,score=float(score))
    assert best is not None
    return best

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--raw',type=Path,required=True)
    ap.add_argument('--writer',type=Path,required=True);ap.add_argument('--work',type=Path,required=True)
    ap.add_argument('--manifest',type=Path,default=Path('IndianMusic/Sounds/harmonium-sources.json'))
    ap.add_argument('--output',type=Path,default=Path('IndianMusic/Sounds/harmonium.sf2'))
    args=ap.parse_args();args.work.mkdir(parents=True,exist_ok=True)
    manifest=json.loads(args.manifest.read_text());rows=[];tsv=[]
    for source in manifest['notes']:
        if not source['includedInSoundfont']:continue
        raw=args.raw/(source['note']+'.wav')
        assert hashlib.sha256(raw.read_bytes()).hexdigest()==source['sourceSha256'],raw
        path=args.work/(source['note']+'-natural.wav')
        ratio=2**(source['pitchCorrectionCents']/1200)
        # Retain the Phase 4.0 leading-silence edit and the recorded reed rise.
        # The 45-ms half-cosine fade attenuates the mechanical opening impulse;
        # after that point there is no envelope reshaping or onset threshold cut.
        filters=f"aresample={SR},atrim=start={source['trimmedLeadingSeconds']},asetpts=PTS-STARTPTS,asetrate={SR*ratio:.9f},aresample={SR},afade=t=in:st=0:d=0.045:curve=hsin"
        subprocess.run(['ffmpeg','-v','error','-y','-i',str(raw),'-af',filters,'-ac','1','-c:a','pcm_f32le',str(path)],check=True)
        y,sr=sf.read(path);assert sr==SR
        hz=440*2**((source['midi']-69)/12);loop=choose_loop(y,hz)
        s,e,n=loop['start'],loop['end'],loop['fade']
        # Established pre-loop crossfade: end blends into material BEFORE loop
        # start, then continues to start. A unity-sum linear fade avoids the
        # +3 dB bump of equal-power fades on strongly correlated reed waveforms.
        head=y[s-n:s].copy();tail=y[e-n:e].copy();ramp=np.linspace(0,1,n)
        y=y[:e].copy();y[-n:]=tail*(1-ramp)+head*ramp
        # Preserve Phase 4.1's accepted sustained-level target, not its attack.
        target=.085;gain=target/np.sqrt(np.mean(y[s:e]**2));y*=gain
        assert abs(y).max()<.95,(source['note'],abs(y).max())
        pcm=args.work/(source['note']+'.pcm')
        pcm.write_bytes(np.round(y*32767).astype('<i2').tobytes()+bytes(128))
        sf.write(args.work/(source['note']+'-prepared.wav'),y,SR,subtype='PCM_16')
        tsv.append(f"{source['midi']} {pcm.resolve()} {s} {e}")
        rows.append(dict(note=source['note'],midi=source['midi'],**loop,
                         loopSeconds=(e-s)/SR,gainDB=float(20*np.log10(gain)),
                         rawSHA256=source['sourceSha256'],preparedSHA256=hashlib.sha256(pcm.read_bytes()).hexdigest()))
        source['loopStartFrame']=s;source['loopEndFrame']=e
        print(source['note'],'loop',round(s/SR,3),round(e/SR,3),'corr',round(loop['correlation'],5),'dB',round(loop['fadeLevelDifferenceDB'],3),flush=True)
    table=args.work/'samples.tsv';table.write_text('\n'.join(tsv)+'\n')
    subprocess.run([str(args.writer.resolve()),str(table),str(args.output)],check=True)
    manifest['soundfontSHA256']=hashlib.sha256(args.output.read_bytes()).hexdigest()
    manifest['phase42']='Natural Phase 4.0 reed attacks restored with 45ms transient fade; longer phase/level-matched sustain loops and unity-sum crossfades. See phase42-preparation.json.'
    args.manifest.write_text(json.dumps(manifest,indent=2)+'\n')
    (args.output.parent/'phase42-preparation.json').write_text(json.dumps(dict(sampleRate=SR,attackFadeMilliseconds=45,sustainRMS=.085,zones=rows),indent=2)+'\n')

if __name__=='__main__':main()
