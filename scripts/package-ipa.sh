#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

app="build/DerivedData/Build/Products/Release-iphoneos/IndianMusic.app"
test -d "$app"
plutil -lint "$app/Info.plist"
python3 - "$app" <<'PY'
import pathlib
import json
import hashlib
import plistlib
import sys

app = pathlib.Path(sys.argv[1])
with (app / 'Info.plist').open('rb') as stream:
    info = plistlib.load(stream)
assert not (app / 'Resources').exists(), 'Reserved legacy Resources folder at bundle root'
assert info['CFBundlePackageType'] == 'APPL', info
assert info['CFBundleIdentifier'] == 'com.harjotharjot.indianmusic', info
assert info['CFBundleSupportedPlatforms'] == ['iPhoneOS'], info
assert info['UIDeviceFamily'] == [1], info
assert info['MinimumOSVersion'] == '16.0', info
assert info['CFBundleShortVersionString'] == '0.4.2', info
assert 'audio' in info['UIBackgroundModes'], info
for name in ['tanpura_pa.wav', 'tanpura_ma.wav', 'tanpura-sources.json', 'harmonium.sf2', 'harmonium-sources.json']:
    assert (app / 'Sounds' / name).is_file(), name
sources = json.loads((app / 'Sounds' / 'tanpura-sources.json').read_text())
for source in sources:
    sound = app / 'Sounds' / source['file']
    assert hashlib.sha256(sound.read_bytes()).hexdigest() == source['sha256'], source['file']
    start, end = source['sourceExcerptSeconds']
    for left, right in source['excludedSourceIntervalsSeconds']:
        assert end <= left or start >= right, 'Source excerpt overlaps reported speech'
harmonium = json.loads((app / 'Sounds' / 'harmonium-sources.json').read_text())
assert hashlib.sha256((app / 'Sounds' / 'harmonium.sf2').read_bytes()).hexdigest() == harmonium['soundfontSHA256']
assert (app / info['CFBundleExecutable']).is_file(), info
assert not (app / 'embedded.mobileprovision').exists()
assert not (app / '_CodeSignature').exists()
print('Validated iPhone application metadata; minimum iOS 16.0; unsigned.')
PY

executable="$app/IndianMusic"
test "$(xcrun lipo -archs "$executable")" = arm64
xcrun vtool -show-build "$executable" > build/macho-build.txt
grep -Eq 'platform[[:space:]]+IOS$' build/macho-build.txt
{
  xcodebuild -version
  file "$executable"
  cat build/macho-build.txt
  echo 'PASS: arm64 iPhoneOS executable, application metadata, unsigned bundle.'
} > build/validation.txt

mkdir -p build/package/Payload
ditto "$app" build/package/Payload/IndianMusic.app
(
  cd build/package
  /usr/bin/zip -qry ../IndianMusic-unsigned.ipa Payload
)
unzip -t build/IndianMusic-unsigned.ipa
python3 - <<'PY'
import plistlib
import zipfile

with zipfile.ZipFile('build/IndianMusic-unsigned.ipa') as archive:
    prefix = 'Payload/IndianMusic.app/'
    info = plistlib.loads(archive.read(prefix + 'Info.plist'))
    executable = archive.read(prefix + info['CFBundleExecutable'])
    assert executable[:4] == b'\xcf\xfa\xed\xfe', 'Expected 64-bit Mach-O'
    assert int.from_bytes(executable[4:8], 'little') == 0x0100000C, 'Expected arm64'
    assert all(name.startswith('Payload/') for name in archive.namelist())
print('PASS: IPA contains Payload/IndianMusic.app with an arm64 executable.')
PY
shasum -a 256 build/IndianMusic-unsigned.ipa > build/IndianMusic-unsigned.ipa.sha256
cat build/validation.txt
