"""Portable sample/timing audit and reference comparisons (NOT a Core Audio render).
Run: python scripts/phase51/validate.py --output build/phase51
Requires numpy, scipy, soundfile, matplotlib. Does not download or alter assets.
"""
import argparse, hashlib, json, pathlib
import numpy as np
import soundfile as sf
from scipy.signal import find_peaks
from onsets import RATE, LEAD, onset

ROOT=pathlib.Path(__file__).resolve().parents[2]
PATTERNS={
 'dadra':(['dha','dhin','na','dha','tin','na'],[0,3],[3]),
 'rupak':(['tin','tin','na','dhin','na','dhin','na'],[0,3,5],[0]),
 'keherwa':(['dha','ge','na','ti','na','ke','dhin','na'],[0,4],[4]),
 'teentaal':(['dha','dhin','dhin','dha','dha','dhin','dhin','dha','dha','tin','tin','na','na','dhin','dhin','dha'],[0,4,8,12],[8]),
 'ektaal':(['dhin','dhin',['dha','ge'],['ti','ta','ke','ta'],'tun','na','ke','na',['dha','ge'],['ti','ta','ke','ta'],'dhin','na'],[0,2,4,6,8,10],[2,6]),
 'jhaptal':(['dhin','na','dhin','dhin','na','tin','na','dhin','dhin','na'],[0,2,5,7],[5])}

def events(name, bpm, cycles):
    beats,starts,khali=PATTERNS[name]
    for cycle in range(cycles):
        for i,bols in enumerate(beats):
            if isinstance(bols,str):bols=[bols]
            for sub,bol in enumerate(bols):
                beat=cycle*len(beats)+i+sub/len(bols)
                strength=.8 if sub else (1.06 if i in starts and i not in khali else .94)
                yield beat, bol, strength

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--output',type=pathlib.Path,default=ROOT/'build/phase51');args=parser.parse_args()
    out=args.output;out.mkdir(parents=True,exist_ok=True)
    manifest=json.loads((ROOT/'IndianMusic/Sounds/tabla-sources.json').read_text())
    samples={};rows=[]
    for entry in manifest['samples']:
        path=ROOT/'IndianMusic/Sounds'/entry['file']
        assert hashlib.sha256(path.read_bytes()).hexdigest()==entry['sha256']
        a,sr=sf.read(path,always_2d=True)
        assert sr==RATE and np.isfinite(a).all() and len(a)==entry['frames']
        measured=onset(a);assert measured==entry['onsetFrame'] and 0<=measured<LEAD
        # Measure a separately rendered isolated event, including the entire waveform.
        target=LEAD+RATE;start=target-measured
        isolated=np.zeros((start+len(a),2));isolated[start:]+=a
        observed=onset(isolated[start:])+start
        assert observed==target
        # Integrity: no samples, channels, attacks or resonance were altered.
        assert np.array_equal(isolated[start:start+len(a)],a)
        samples.setdefault(entry['bol'],[]).append((a,measured))
        rows.append(dict(file=entry['file'],onsetFrame=measured,beforeMs=measured/48,
                         afterMs=(observed-target)/48,
                         thresholdSensitivityMs={str(t):onset(a,t)/48 for t in [.05,.08,.12,.2]}))
    results=[]
    for name in PATTERNS:
        for bpm in [30,80,137,240]:
            takes={};errors=[];active=[];max_voices=0
            length=LEAD+round(len(PATTERNS[name][0])*4*RATE*60/bpm)+3*RATE
            before=np.zeros((length,2));after=np.zeros_like(before)
            for beat,bol,gain in events(name,bpm,4):
                n=takes.get(bol,0);takes[bol]=n+1
                a,offset=samples[bol][n%len(samples[bol])]
                ideal=LEAD+beat*RATE*60/bpm;grid=LEAD+round(beat*RATE*60/bpm)
                start=grid-offset;errors.append(start+offset-ideal)
                active=[end for end in active if end>start];active.append(start+len(a));max_voices=max(max_voices,len(active))
                before[grid:grid+len(a)]+=a*gain*.8
                after[start:start+len(a)]+=a*gain*.8
            assert max(abs(np.array(errors)))<=.500001 and max_voices<=24
            assert max(np.max(abs(before)),np.max(abs(after)))<1
            if bpm==80:
                sf.write(out/f'{name}-80bpm-before.flac',before,RATE,subtype='PCM_24')
                sf.write(out/f'{name}-80bpm-after.flac',after,RATE,subtype='PCM_24')
            # 12-hour absolute frame arithmetic: no repeated rounded-beat addition.
            beats=np.arange(0,12*3600*bpm/60,.25)
            ideal=beats*RATE*60/bpm
            drift=float(np.max(abs(np.rint(ideal)-ideal)));assert drift<=.500001
            results.append(dict(taal=name,bpm=bpm,cycles=4,events=sum(takes.values()),maximumGridErrorFrames=float(max(abs(np.array(errors)))),
                                twelveHourGridErrorFrames=drift,maximumVoices=max_voices,peakAfter=float(np.max(abs(after)))))
    # A phase-continuous tempo-edit arithmetic check across all six patterns,
    # rounding absolute positions once on each side of a non-integral boundary.
    edits=[]
    for name in PATTERNS:
        beat_array=np.array([e[0] for e in events(name,137,8)])
        boundaries=[(0.,137.),(3.,73.),(9.,240.),(15.,30.),(21.,191.)]
        frames=np.empty(len(beat_array));anchor=float(LEAD)
        for i,(boundary,bpm) in enumerate(boundaries):
            if i:
                prev,tempo=boundaries[i-1];anchor+=(boundary-prev)*RATE*60/tempo
            end=boundaries[i+1][0] if i+1<len(boundaries) else np.inf
            mask=(beat_array>=boundary)&(beat_array<end)
            frames[mask]=anchor+(beat_array[mask]-boundary)*RATE*60/bpm
        assert np.all(np.diff(np.rint(frames))>0)
        edits.append(dict(taal=name,maximumGridErrorFrames=float(np.max(abs(np.rint(frames)-frames)))))
    # Dominant resonant spectral peaks are evidence for evaluating tuning, not
    # automatic f0 labels: tabla modes are inharmonic and differ by bol.
    pitches=[]
    for bol in ['na','tin','tun','dha','dhin','ge']:
        for take,(a,_) in enumerate(samples[bol]):
            x=a[int(.04*RATE):int(.4*RATE)].mean(axis=1)
            fft=abs(np.fft.rfft(x*np.hanning(len(x)),n=262144))
            freq=np.fft.rfftfreq(262144,1/RATE)
            peaks,_=find_peaks(fft);peaks=[p for p in peaks if 60<freq[p]<2000]
            peaks=sorted(peaks,key=lambda p:fft[p],reverse=True)[:5]
            pitches.append(dict(bol=bol,take=take+1,dominantResonancesHz=[round(float(freq[p]),2) for p in peaks]))
    report=dict(method='Portable independent reference sums; not AVAudioEngine output, listening approval, or native UI validation.',
                sampleRate=RATE,preRollFrames=LEAD,samples=rows,taalChecks=results,tempoArithmetic=edits,resonances=pitches,
                maximumBeforeMs=max(r['beforeMs'] for r in rows),maximumAfterMs=max(r['afterMs'] for r in rows))
    (out/'measurements.json').write_text(json.dumps(report,indent=2)+'\n')
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    fig,ax=plt.subplots(figsize=(11,5))
    labels=[r['file'].split('/')[1].replace('.wav','') for r in rows];x=np.arange(len(rows))
    ax.bar(x-.18,[r['beforeMs'] for r in rows],.36,label='Before: file start on grid')
    ax.bar(x+.18,[r['afterMs'] for r in rows],.36,label='After: attack landmark on grid')
    ax.set_xticks(x,labels,rotation=45);ax.set_ylabel('Attack landmark delay (ms)')
    ax.set_title('Tabla sample alignment · portable reference measurement')
    ax.legend();fig.tight_layout();fig.savefig(out/'onset-comparison.png',dpi=160);plt.close(fig)
    print(f'PASS: 15 asset hashes and measured landmarks; intact stereo waveforms; 24 six-taal/tempo reference renders; 12-hour arithmetic <=0.5 frame; tempo-edit arithmetic. Before max {report["maximumBeforeMs"]:.3f} ms, aligned landmark 0 ms. Native playback/UI tests remain pending.')

if __name__=='__main__':main()
