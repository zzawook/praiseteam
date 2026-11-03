"""Choose a simulator actually installed on the Codemagic macOS runner."""
import json
import os
import re
import subprocess
from pathlib import Path


def simctl(*args):
    return subprocess.check_output(['xcrun', 'simctl', *args], text=True)


def version(runtime):
    return tuple(map(int, re.findall(r'\d+', runtime)))


devices = json.loads(simctl('list', 'devices', 'available', '--json'))['devices']
choices = [
    (version(runtime), device)
    for runtime, items in devices.items()
    if '.iOS-' in runtime
    for device in items
    if device.get('isAvailable') and device['name'].startswith('iPhone')
]
if not choices:
    raise SystemExit('This Xcode image has no available iPhone simulator.')
choices.sort(key=lambda pair: (pair[0], 'Pro' in pair[1]['name'], pair[1]['name']), reverse=True)
device = choices[0][1]
if device['state'] != 'Booted':
    simctl('boot', device['udid'])
subprocess.run(['xcrun', 'simctl', 'bootstatus', device['udid'], '-b'], check=True)
with Path(os.environ['CM_ENV']).open('a') as env:
    env.write(f"NATIVE_IOS_DEVICE={device['udid']}\n")
print(f"Selected {device['name']} ({device['udid']}).")
