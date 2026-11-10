#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
xcrun swiftc -parse-as-library IndianMusic/TanpuraSettings.swift scripts/tests/SettingsTests.swift -o build/tests/settings
build/tests/settings | tee build/tests/settings.txt
xcrun swiftc -parse-as-library IndianMusic/TanpuraSettings.swift IndianMusic/PracticeAudioGraph.swift IndianMusic/TablaSettings.swift IndianMusic/TablaSequencer.swift IndianMusic/HarmoniumSettings.swift scripts/tests/GraphTests.swift -o build/tests/graph
build/tests/graph "$PWD/IndianMusic/Sounds" | tee build/tests/graph.txt
