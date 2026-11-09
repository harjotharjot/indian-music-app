#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/tests
xcrun simctl list devices available --json > build/tests/simulator-devices.json
simulator_id=$(python3 - <<'PY'
import json
j=json.load(open('build/tests/simulator-devices.json'))
for runtime,devices in j['devices'].items():
    if 'iOS' not in runtime:continue
    for device in devices:
        if device['isAvailable'] and 'iPhone' in device['name']:
            print(device['udid'])
            raise SystemExit(0)
raise SystemExit('No available iPhone simulator')
PY
)
xcrun simctl boot "$simulator_id" || true
xcrun simctl bootstatus "$simulator_id" -b
xcodebuild -project IndianMusic.xcodeproj -scheme IndianMusic -configuration Debug \
  -sdk iphonesimulator -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath build/Simulator CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual build > build/tests/simulator-build.log 2>&1
cp build/Simulator/Build/Products/Debug-iphonesimulator/IndianMusic.app/Info.plist build/tests/simulator-Info.plist
/usr/libexec/PlistBuddy -c "Print CFBundleIdentifier" build/tests/simulator-Info.plist
codesign --verify --verbose build/Simulator/Build/Products/Debug-iphonesimulator/IndianMusic.app
xcrun simctl install "$simulator_id" build/Simulator/Build/Products/Debug-iphonesimulator/IndianMusic.app
xcrun simctl launch "$simulator_id" com.harjotharjot.indianmusic | tee build/tests/simulator-launch.txt
# Give SwiftUI time to draw the initial form before capture.
sleep 3
xcrun simctl io "$simulator_id" screenshot build/tests/phase3-iphone.png
xcrun simctl terminate "$simulator_id" com.harjotharjot.indianmusic
trap 'xcrun xcresulttool export attachments --path build/tests/Orientation.xcresult --output-path build/tests/orientation-screenshots || true' EXIT
xcodebuild test -project IndianMusic.xcodeproj -scheme IndianMusic -configuration Debug \
  -sdk iphonesimulator -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath build/Simulator -resultBundlePath build/tests/Orientation.xcresult \
  -parallel-testing-enabled NO -test-timeouts-enabled YES -maximum-test-execution-time-allowance 120 CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual \
  2>&1 | tee build/tests/orientation-tests.log
xcrun simctl shutdown "$simulator_id"
