"""Repair recorded onsets in an existing SF2 using NumPy/SciPy, retaining sustain loops.
Input must be the original v0.4.0 bank; output and per-zone audit are explicit.
"""
import hashlib, json, struct, sys
from pathlib import Path
import numpy as np
from scipy.signal import butter, sosfilt
source, target, report = map(Path, sys.argv[1:])
b = bytearray(source.read_bytes())
def find(tag):
    # Traverse RIFF chunks; do not search arbitrary PCM bytes for fourcc strings.
    def walk(lo, hi):
        while lo + 8 <= hi:
            kind, n = struct.unpack_from('<4sI', b, lo)
            if kind == tag: return lo+8, n
            if kind in (b'RIFF', b'LIST'):
                got=walk(lo+12, lo+8+n)
                if got: return got
            lo += 8+n+(n%2)
    return walk(0,len(b))
smpl,size=find(b'smpl'); shdr,ns=find(b'shdr')
pcm=np.frombuffer(b,dtype='<i2',count=size//2,offset=smpl).copy()
rows=[]
for off in range(shdr,shdr+ns-46,46):
    name=bytes(b[off:off+20]).split(b'\0')[0].decode()
    start,end,loopstart,loopend,sr=struct.unpack_from('<5I',b,off+20)
    y=pcm[start:end].astype(float)/32768
    # Reject low-frequency handling noise; locate established reed energy rather
    # than the first transient. Require three consecutive 10-ms windows.
    filtered=sosfilt(butter(2,100,fs=sr,btype='highpass',output='sos'),y)
    hop=sr//100
    energy=np.sqrt(np.mean(filtered[:len(y)//hop*hop].reshape(-1,hop)**2,axis=1))
    steady=float(np.median(energy[50:150])); onset=0
    for i in range(0,min(40,len(energy)-3)):
        if np.all(energy[i:i+3] >= steady*.65): onset=i*hop; break
    onset=min(onset,loopstart-start-hop)
    z=y[onset:].copy()
    # Short fade suppresses the edit discontinuity while keeping recorded reeds.
    fade=int(sr*.006); z[:fade]*=np.linspace(0,1,fade)
    sustain=y[loopstart-start:loopend-start]
    rms=float(np.sqrt(np.mean(sustain*sustain)))
    gain=float(np.clip(.085/max(rms,1e-8),.5,2))
    z*=gain
    assert abs(z).max()<.98
    pcm[start+onset:end]=np.round(z*32767).astype('<i2')
    struct.pack_into('<I',b,off+20,start+onset)
    rows.append(dict(sample=name,trimMilliseconds=onset/sr*1000,sustainRMSBefore=rms,gainDB=20*np.log10(gain),fadeMilliseconds=6))
b[smpl:smpl+size]=pcm.tobytes();target.write_bytes(b)
report.write_text(json.dumps(dict(sourceSHA256=hashlib.sha256(source.read_bytes()).hexdigest(),outputSHA256=hashlib.sha256(b).hexdigest(),zones=rows),indent=2)+'\n')
print('Repaired',len(rows),'zones; trim ms range',min(x['trimMilliseconds'] for x in rows),max(x['trimMilliseconds'] for x in rows))
