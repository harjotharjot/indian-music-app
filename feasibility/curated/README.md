# Tanpura Pa audition correction

Source: Sankalp Gulati (`sankalp`), [Acoustic Tanpura 4](https://freesound.org/people/sankalp/sounds/153263/),
licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

The user reported speech in the last three seconds. This derivative removes 3.5
seconds from the tail, including a half-second margin, and adds a 50-ms fade out.
It is a decoded MP3 preview, not the original lossless recording. Verify by listening
before accepting it. A fade-out does not make a seamless tanpura loop.

Reproduce after running `python feasibility/fetch_samples.py`:

```sh
ffmpeg -i feasibility/assets/tanpura_pa.mp3 \
  -af 'atrim=end=34.972721088,afade=t=out:st=34.922721088:d=0.05' \
  -c:a pcm_s16le feasibility/curated/tanpura_pa_trimmed.wav
```

The JSON manifest records source/output SHA-256 and measured duration. The original
sample manifest and earlier results remain intact. This is a Phase 2 correction;
no app audio feature has been implemented.
