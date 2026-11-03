"""Prepare client configuration on Codemagic without printing its contents."""
import json
import os
from pathlib import Path
from release_config import validate

root = Path(__file__).resolve().parents[1]
raw = os.environ.get('APP_CONFIG_JSON')
if not raw:
    raise SystemExit('Add APP_CONFIG_JSON to the praiseteam-production Codemagic variable group.')
try:
    values = validate(json.loads(raw), ios=True)
except (ValueError, TypeError) as error:
    raise SystemExit(str(error))
number = os.environ.get('PROJECT_BUILD_NUMBER', '')
if not number.isdecimal():
    raise SystemExit('Codemagic PROJECT_BUILD_NUMBER is missing.')
path = root/'app/env/store.ios.json'
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(values)+'\n')
path.chmod(0o600)
with Path(os.environ['CM_ENV']).open('a') as env:
    env.write(f'STORE_BUILD_NUMBER={1000+int(number)}\n')
print('Production client settings validated; unique iOS build number assigned.')
