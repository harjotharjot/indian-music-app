#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests/audio
xcrun swiftc -parse-as-library IndianMusic/HarmoniumSettings.swift scripts/tests/HarmoniumModelTests.swift -o build/tests/harmonium-model
build/tests/harmonium-model | tee build/tests/harmonium-model.txt
xcrun swiftc -parse-as-library IndianMusic/TanpuraSettings.swift IndianMusic/HarmoniumSettings.swift IndianMusic/PracticeAudioGraph.swift scripts/tests/HarmoniumAudioTests.swift -o build/tests/harmonium-audio
mkdir -p build/baseline-sounds
cp IndianMusic/Sounds/* build/baseline-sounds/
git show b5bf10d:IndianMusic/Sounds/harmonium.sf2 > build/baseline-sounds/harmonium.sf2
build/tests/harmonium-audio "$PWD/build/baseline-sounds" "$PWD/build/tests/audio" baseline | tee build/tests/baseline-audio.txt
build/tests/harmonium-audio "$PWD/IndianMusic/Sounds" "$PWD/build/tests/audio" | tee build/tests/harmonium-audio.txt

# Three independent Apple-sampler processes, with the same fixed graph and gains.
xcrun swiftc -parse-as-library IndianMusic/TanpuraSettings.swift IndianMusic/HarmoniumSettings.swift IndianMusic/PracticeAudioGraph.swift scripts/tests/HarmoniumComparisonTests.swift -o build/tests/harmonium-comparisons
mkdir -p build/phase41-sounds
cp IndianMusic/Sounds/* build/phase41-sounds/
git show 8ec81ba:IndianMusic/Sounds/harmonium.sf2 > build/phase41-sounds/harmonium.sf2
build/tests/harmonium-comparisons "$PWD/build/baseline-sounds" "$PWD/build/tests/comparisons/phase40"
build/tests/harmonium-comparisons "$PWD/build/phase41-sounds" "$PWD/build/tests/comparisons/phase41"
build/tests/harmonium-comparisons "$PWD/IndianMusic/Sounds" "$PWD/build/tests/comparisons/corrected"

mkdir -p build/phase42-accepted-sounds
cp IndianMusic/Sounds/* build/phase42-accepted-sounds/
git show 40d8eeb:IndianMusic/Sounds/harmonium.sf2 > build/phase42-accepted-sounds/harmonium.sf2
build/tests/harmonium-comparisons "$PWD/build/phase42-accepted-sounds" "$PWD/build/tests/fsharp-before" 42,54,66
