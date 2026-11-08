#!/bin/bash
# Build upstream aubio unchanged; compile check only, not a device runtime test.
set -euo pipefail
mkdir -p build feasibility/results/ios
 git clone https://github.com/aubio/aubio.git build/aubio
 git -C build/aubio checkout ad5cf975aed08cc4562dd008cf9f83b12b82ffb8
(
  cd build/aubio
  bash scripts/get_waf.sh
  python waf configure --with-target-platform=ios --nodeps --disable-tests --disable-examples
  python waf build
)
archive=build/aubio/build/src/libaubio.a
test -f "$archive"
xcrun lipo -info "$archive"
xcrun otool -l "$archive" > feasibility/results/ios/aubio-load-commands.txt
# The upstream cross-build currently targets iOS 16.4; don't imply iOS 16.0 support.
python - <<'PY'
from pathlib import Path
p=Path('feasibility/results/ios/aubio-load-commands.txt').read_text()
assert 'LC_BUILD_VERSION' in p and 'platform 2' in p, 'Expected iOS object code'
Path('feasibility/results/ios/summary.txt').write_text(
    'PASS: upstream aubio ad5cf975aed08cc4562dd008cf9f83b12b82ffb8 built as arm64 iOS static library.\n'
    'Upstream deployment minimum: 16.4. No device execution or Swift linking tested.\n'
    'Desktop benchmark uses released aubio 0.4.9; this source revision is a separate compatibility probe.\n')
PY
