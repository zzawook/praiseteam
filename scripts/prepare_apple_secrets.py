"""Create the private Edge Function environment file from an Apple signing key.

This never uploads secrets and never prints their values. Existing token
storage encryption keys are reused: replacing one would strand saved tokens.
"""
import argparse
import base64
import json
import os
from pathlib import Path
import re
import secrets
import subprocess

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--team-id',required=True)
p.add_argument('--key-id',required=True)
p.add_argument('--private-key',type=Path,required=True)
args=p.parse_args()
if not all(re.fullmatch(r'[A-Z0-9]{10}',v) for v in [args.team_id,args.key_id]):
    raise SystemExit('Use the 10-character Apple Team ID and Sign in with Apple Key ID.')
subprocess.run(['openssl','pkey','-in',str(args.private_key),'-check','-noout'],check=True,stdout=subprocess.DEVNULL)
private=args.private_key.read_text().strip()
if not private.startswith('-----BEGIN PRIVATE KEY-----'):
    raise SystemExit('Expected the downloaded Apple PKCS#8 .p8 key.')
folder=root/'.secrets';folder.mkdir(mode=0o700,exist_ok=True)
keyfile=folder/'apple-token-encryption.key'
if not keyfile.exists():
    fd=os.open(keyfile,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    with os.fdopen(fd,'w') as out:out.write(base64.b64encode(secrets.token_bytes(32)).decode()+'\n')
encryption=keyfile.read_text().strip()
if len(base64.b64decode(encryption,validate=True))!=32:
    raise SystemExit('Existing Apple token encryption key is invalid; do not overwrite it.')
values={'APPLE_CLIENT_ID':'com.kjaehyeok.praiseteam','APPLE_TEAM_ID':args.team_id,'APPLE_KEY_ID':args.key_id,
        'APPLE_PRIVATE_KEY':private,'APPLE_TOKEN_ENCRYPTION_KEY':encryption}
path=folder/'apple-signin.env'
fd=os.open(path,os.O_WRONLY|os.O_CREAT|os.O_TRUNC,0o600)
with os.fdopen(fd,'w') as out:
    for name,value in values.items():out.write(name+'='+json.dumps(value)+'\n')
path.chmod(0o600)
print('Prepared .secrets/apple-signin.env. Back up it and the encryption key securely.')
