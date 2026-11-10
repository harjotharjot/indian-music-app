#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests/tabla
xcrun swiftc -parse-as-library IndianMusic/TablaSettings.swift scripts/tests/TablaModelTests.swift -o build/tests/tabla-model
build/tests/tabla-model | tee build/tests/tabla-model.txt
xcrun swiftc -parse-as-library IndianMusic/TanpuraSettings.swift IndianMusic/HarmoniumSettings.swift IndianMusic/TablaSettings.swift IndianMusic/TablaSequencer.swift IndianMusic/PracticeAudioGraph.swift scripts/tests/TablaAudioTests.swift -o build/tests/tabla-audio
build/tests/tabla-audio "$PWD/IndianMusic/Sounds" "$PWD/build/tests/tabla" | tee build/tests/tabla-audio.txt
