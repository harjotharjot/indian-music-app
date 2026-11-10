"""Deterministic attack landmark; no trimming or modification of sample audio.

First causal 1-ms RMS crossing of 8% of the maximum RMS in the first 250 ms.
Use the louder channel, so stereo phase cancellation cannot hide an attack.
This is an operational alignment landmark, not a claim about human perception.
"""
import numpy as np
RATE = 48000
LEAD = 480  # 10-ms common pre-roll leaves every complete recording intact.

def envelope(audio):
    power = np.max(np.asarray(audio) ** 2, axis=1)
    sums = np.concatenate(([0.0], np.cumsum(power)))
    end = np.arange(1, len(power) + 1)
    return np.sqrt((sums[end] - sums[np.maximum(0, end - 48)]) / 48)

def onset(audio, fraction=0.08):
    rms = envelope(audio)
    return int(np.flatnonzero(rms > fraction * rms[:12000].max())[0])
