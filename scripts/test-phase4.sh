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
