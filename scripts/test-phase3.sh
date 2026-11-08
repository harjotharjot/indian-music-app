#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
xcrun swiftc -parse-as-library IndianMusic/TanpuraSettings.swift scripts/tests/SettingsTests.swift -o build/tests/settings
build/tests/settings | tee build/tests/settings.txt
xcrun swiftc -parse-as-library IndianMusic/TanpuraSettings.swift IndianMusic/TanpuraGraph.swift scripts/tests/GraphTests.swift -o build/tests/graph
build/tests/graph "$PWD/IndianMusic/Resources" | tee build/tests/graph.txt
