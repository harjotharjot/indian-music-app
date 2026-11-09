"""Repair only Fs3's loop interpolation guard in the accepted v0.4.2 bank.
AUSampler reads the loop-end interpolation sample before returning to start+1.
A zero there creates an impulse when the reed is far from zero at loop start.
"""
import hashlib,json,struct,sys
from pathlib import Path
import numpy as np
source,target,audit=map(Path,sys.argv[1:]);b=bytearray(source.read_bytes())
def find(tag,lo=0,hi=None):
 hi=len(b) if hi is None else hi
 while lo+8<=hi:
  kind,n=struct.unpack_from('<4sI',b,lo)
  if kind==tag:return lo+8,n
  if kind in (b'RIFF',b'LIST'):
   got=find(tag,lo+12,lo+8+n)
   if got:return got
  lo+=8+n+n%2
smpl,n=find(b'smpl');shdr,nh=find(b'shdr')
changes=[]
for off in range(shdr,shdr+nh-46,46):
 name,start,end,ls,le,sr,root,_,_,_=struct.unpack_from('<20sIIIIIBbHH',b,off)
 if root!=54:continue
 assert le+64<=end and ls+64<le
 old=bytes(b[smpl+le*2:smpl+(le+64)*2])
 continuation=bytes(b[smpl+ls*2:smpl+(ls+64)*2])
 b[smpl+le*2:smpl+(le+64)*2]=continuation
 changes.append(dict(root=root,loopStart=ls,loopEnd=le,frames=64,
  oldFirstSample=struct.unpack_from('<h',old)[0],newFirstSample=struct.unpack_from('<h',continuation)[0]))
assert len(changes)==1
target.write_bytes(b)
audit.write_text(json.dumps(dict(sourceSHA256=hashlib.sha256(source.read_bytes()).hexdigest(),
 outputSHA256=hashlib.sha256(b).hexdigest(),changes=changes),indent=2)+'\n')
print(changes)
