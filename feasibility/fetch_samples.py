"""Download a small, attributed feasibility corpus. No account/API key required."""
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parent
ASSETS = ROOT / 'assets'
PIN = '622c2f1c32c8cfce4158ddc3eb26e518ddef37e5'

def get(url):
    with urllib.request.urlopen(url, timeout=90) as response:
        return response.read()

def save(name, data):
    (ASSETS / name).write_bytes(data)
    return {'file': name, 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}

def freesound(spec):
    name, author, sound_id, license_id, role, tuning = spec
    page = f'https://freesound.org/people/{author}/sounds/{sound_id}/'
    html = get(page).decode()
    license_url = {'CC0-1.0': 'https://creativecommons.org/publicdomain/zero/1.0/',
                   'CC-BY-4.0': 'https://creativecommons.org/licenses/by/4.0/'}[license_id]
    assert license_url.removeprefix('https:') in html, f'License not confirmed: {page}'
    previews = re.findall(r'https://cdn.freesound.org/previews/[^\s"<>]+-hq.mp3', html)
    assert previews, page
    url = previews[0]
    result = save(name + '.mp3', get(url))
    result.update(source=page, download=url, creator=author, license=license_id,
                  license_url=license_url, role=role, tuning=tuning,
                  quality='Freesound HQ MP3 preview; NOT original lossless WAV', modifications='none')
    return result

def harmonium(note):
    url = f'https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/{PIN}/samples/harmonium/{note}.wav'
    result = save('harmonium_' + note + '.wav', get(url))
    result.update(source='https://freesound.org/people/donyaquick/sounds/330410/',
                  download=url, creator='donyaquick; distributed by nbrosowsky/tonejs-instruments',
                  license='CC0-1.0', license_url='https://creativecommons.org/publicdomain/zero/1.0/',
                  role='harmonium', tuning=note + ' (label, not calibrated ground truth)',
                  quality='upstream distributed WAV; segmentation/processing provenance not fully documented',
                  modifications='none', upstream_commit=PIN)
    return result

def main():
    expected = json.loads((ROOT/'samples.json').read_text()) if (ROOT/'samples.json').exists() else []
    ASSETS.mkdir(exist_ok=True)
    specs = [
        ('tanpura_pa', 'sankalp', 153263, 'CC-BY-4.0', 'tanpura', 'pa SA SA sa; about 138 Hz'),
        ('tanpura_ma', 'sankalp', 153265, 'CC-BY-4.0', 'tanpura', 'ma SA SA sa; about 138 Hz'),
        ('voice_scale', 'mooncubedesign', 442571, 'CC0-1.0', 'voice', 'A major scale; no frame-level F0 labels'),
        ('voice_male', 'TheEndOfACycle', 663189, 'CC0-1.0', 'voice', 'vowels with hall reverb; no F0 labels'),
    ]
    # Verify original harmonium license and upstream source attribution before reuse.
    original = get('https://freesound.org/people/donyaquick/sounds/330410/').decode()
    assert '//creativecommons.org/publicdomain/zero/1.0/' in original
    provenance = get(f'https://raw.githubusercontent.com/nbrosowsky/tonejs-instruments/{PIN}/sample-source-info.txt')
    assert b'330410' in provenance
    (ROOT / 'licenses/harmonium-source-info.txt').write_bytes(provenance)
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        entries = list(pool.map(freesound, specs))
        entries += list(pool.map(harmonium, ['C2', 'C3', 'C4', 'C5', 'A2', 'A3', 'A4']))
    record = json.loads(get('https://zenodo.org/api/records/4327350'))
    assert record['metadata']['license']['id'] == 'cc-by-4.0'
    files = sorted(record['files'], key=lambda f: f['key'])
    # One actual original WAV for each distinct prefix; keep multiple Na takes if available.
    chosen = {}
    for item in files:
        prefix = item['key'].split('_')[0]
        chosen.setdefault(prefix, item)
    for item in chosen.values():
        result = save('tabla_' + item['key'], get(item['links']['self']))
        result.update(source='https://zenodo.org/records/4327350', download=item['links']['self'],
                      creator='Subodh Deolekar', license='CC-BY-4.0',
                      license_url='https://creativecommons.org/licenses/by/4.0/', role='tabla',
                      tuning='C# set per source; stroke names retained verbatim',
                      quality='original dataset WAV', modifications='none')
        entries.append(result)
    entries.sort(key=lambda item: item['file'])
    if expected:
        assert {e['file']:e['sha256'] for e in entries} == {e['file']:e['sha256'] for e in expected}, 'Upstream sample content changed; review before updating manifest'
    (ROOT / 'samples.json').write_text(json.dumps(entries, indent=2) + '\n')
    print(f'Downloaded {len(entries)} samples, {sum(e["bytes"] for e in entries)} bytes')

if __name__ == '__main__':
    main()
