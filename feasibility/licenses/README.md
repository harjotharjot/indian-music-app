# Attribution and dependency notices

Sample files are research inputs, not bundled in the iPhone app. `samples.json`
contains each creator, exact source URL, download URL, license URL, SHA-256 and
modification status. Files have not been edited; decoded/resampled test excerpts
and shifted derivatives are in CI artifacts only. All redistributed derivatives
remain attributed to the source creator. MP3 previews are explicitly identified.

- Tanpura: Sankalp Gulati (`sankalp`), Acoustic Tanpura 4 / 5, Freesound
  [153263](https://freesound.org/people/sankalp/sounds/153263/) and
  [153265](https://freesound.org/people/sankalp/sounds/153265/).
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- Harmonium: donyaquick, [Harmonium Samples — All Keys and Drones](https://freesound.org/people/donyaquick/sounds/330410/),
  recorded at Euterpea Studio, Yale. [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
  Distributed WAVs retrieved from `nbrosowsky/tonejs-instruments` commit
  `622c2f1c32c8cfce4158ddc3eb26e518ddef37e5`; source-info text retained here.
- Tabla: Subodh Deolekar, [Tabla strokes dataset (2020)](https://zenodo.org/records/4327350),
  DOI 10.5281/zenodo.4327350. [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
- Singing: mooncubedesign, [Singing Scale — A Major](https://freesound.org/people/mooncubedesign/sounds/442571/),
  and TheEndOfACycle, [Vocals — Man Singing Note](https://freesound.org/people/TheEndOfACycle/sounds/663189/).
  Both [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).

Research dependencies, not incorporated into the app:

| Component | Version / source | License and implications |
|---|---|---|
| aubio | Python/C 0.4.9; iOS compile probe `ad5cf975aed08cc4562dd008cf9f83b12b82ffb8` | [GPL-3.0-or-later](https://github.com/aubio/aubio/blob/master/COPYING); review obligations before distributing linked builds. |
| librosa | 0.10.2.post1 | [ISC](https://github.com/librosa/librosa/blob/0.10.2.post1/LICENSE.md); Python-only research tool here. |
| NumPy | 1.26.4 | BSD-3-Clause; numerical fixtures/analysis. |
| SciPy | 1.14.1 | BSD-3-Clause; numerical analysis. |
| SoundFile | 0.12.1 | BSD-3-Clause wrapper; libsndfile LGPL; desktop decoding only. |
| Rubber Band | version captured by macOS job | [GPL-2.0-or-later / commercial](https://breakfastquay.com/rubberband/license.html); research CLI, no iOS integration or redistribution in app. |
| FFmpeg | version captured in runtime logs | Build-dependent LGPL/GPL; desktop conversion only, not shipped in app. |
| AVFoundation | Xcode / OS recorded with results | Apple SDK/framework terms; native candidate. |
| SoundpipeAudioKit | inspected, not benchmarked | MIT package; underlying third-party notices also require review before use. |
| SoundTouch | researched, not benchmarked | LGPL-2.1 or separate license; not integrated. |

Synthetic fixtures and harnesses are original test infrastructure, not new pitch
or time-stretch algorithms. No copied algorithm implementation was added.
