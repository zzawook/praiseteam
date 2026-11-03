"""Validate client-only release settings and build signed Android store files."""
import argparse
import hashlib
import json
import shutil
import subprocess
from pathlib import Path
from release_config import validate

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--config', default='app/env/prod.json')
args = parser.parse_args()
config = (ROOT / args.config).resolve()
try:
    validate(json.loads(config.read_text()))
except ValueError as error:
    raise SystemExit(str(error))
if not (ROOT / 'app/android/key.properties').is_file():
    raise SystemExit('Release signing properties are missing.')
output = ROOT / 'output/store/android'
output.mkdir(parents=True, exist_ok=True)
for kind in ['appbundle', 'apk']:
    subprocess.run(['flutter', 'build', kind, '--release', '--dart-define-from-file=' + str(config)], cwd=ROOT/'app', check=True)
files = {
    'praiseteam-store.aab': ROOT/'app/build/app/outputs/bundle/release/app-release.aab',
    'praiseteam-store.apk': ROOT/'app/build/app/outputs/flutter-apk/app-release.apk',
}
for name, source in files.items():
    shutil.copy2(source, output/name)
(output/'SHA256SUMS').write_text(''.join(hashlib.sha256((output/name).read_bytes()).hexdigest()+'  '+name+'\n' for name in files))
print('Signed store artifacts:', output)
