"""Select only the synthetic chart in the requested disposable emulator picker."""
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

adb, device, output = sys.argv[1:]
prefix = [adb, '-s', device]
deadline = time.monotonic() + 90
opened_roots = False
while time.monotonic() < deadline:
    try:
        dumped = subprocess.run(prefix + ['shell', 'uiautomator', 'dump', '/sdcard/praiseteam-qa.xml'],
                                timeout=12, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.TimeoutExpired:
        continue
    if dumped.returncode:
        time.sleep(.5)
        continue
    raw = subprocess.check_output(prefix + ['shell', 'cat', '/sdcard/praiseteam-qa.xml'])
    try:
        nodes = list(ET.fromstring(raw).iter('node'))
    except ET.ParseError:
        time.sleep(.5)
        continue
    target = next((n for n in nodes if n.get('text') == 'PraiseTeam-QA.png'), None)
    if target is not None:
        Path(output, '40-android-file-picker.png').write_bytes(
            subprocess.check_output(prefix + ['exec-out', 'screencap', '-p']))
        coords = list(map(int, re.findall(r'\d+', target.get('bounds'))))
        subprocess.check_call(prefix + ['shell', 'input', 'tap',
                              str((coords[0]+coords[2])//2), str((coords[1]+coords[3])//2)])
        print('Selected the synthetic chart through the Android system picker.', flush=True)
        sys.exit(0)
    downloads = next((n for n in nodes if n.get('text') in ('Downloads', '다운로드')), None)
    roots = next((n for n in nodes if n.get('content-desc') in ('Show roots', '루트 표시')), None)
    target = downloads if downloads is not None else (roots if not opened_roots else None)
    if target is not None:
        coords = list(map(int, re.findall(r'\d+', target.get('bounds'))))
        subprocess.check_call(prefix + ['shell', 'input', 'tap',
                              str((coords[0]+coords[2])//2), str((coords[1]+coords[3])//2)])
        if target is roots:
            opened_roots = True
    time.sleep(.5)
raise SystemExit('Synthetic chart was not found in the Android system picker.')
