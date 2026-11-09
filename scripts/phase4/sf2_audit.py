"""Read actual SoundFont sample headers/PCM (no assumed loop metadata)."""
import struct
from pathlib import Path
import numpy as np

def samples(path):
    b=Path(path).read_bytes()
    def find(tag,lo=0,hi=None):
        hi=len(b) if hi is None else hi
        while lo+8<=hi:
            kind,n=struct.unpack_from('<4sI',b,lo)
            if kind==tag:return lo+8,n
            if kind in (b'RIFF',b'LIST'):
                got=find(tag,lo+12,lo+8+n)
                if got:return got
            lo+=8+n+n%2
    pcm,n=find(b'smpl');data=np.frombuffer(b,dtype='<i2',offset=pcm,count=n//2).astype(float)/32768
    shdr,n=find(b'shdr');rows=[]
    for off in range(shdr,shdr+n-46,46):
        name,start,end,ls,le,sr,root,_,_,_=struct.unpack_from('<20sIIIIIBbHH',b,off)
        assert start<=ls<le<=end<=len(data)
        rows.append(dict(name=name.split(b'\0')[0].decode(),start=start,end=end,
            loopStart=ls,loopEnd=le,sampleRate=sr,root=root,pcm=data[start:end],
            relativeLoopStart=ls-start,relativeLoopEnd=le-start))
    return sorted(rows,key=lambda x:x['root'])

def zone_for_note(zones,note):
    # Matches the unchanged builder's nearest-root key-range assignment (ties low).
    return min(zones,key=lambda x:(abs(x['root']-note),x['root']))
