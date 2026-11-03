"""Exercise only the demo PDF's save/cancel dialogs on PraiseTeam_QA_API36."""
import hashlib
import json
import re
import shlex
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
from pathlib import Path

adb, device, log, output = sys.argv[1:]
prefix = [adb, '-s', device]
assert subprocess.check_output(prefix + ['emu', 'avd', 'name'], text=True).splitlines()[0] == 'PraiseTeam_QA_API36'
out = Path(output)
out.mkdir(parents=True, exist_ok=True)
deadline = time.monotonic() + 180
phase = 0
metadata = None
saved = None
owned_target = False

def tap(node):
    xy = list(map(int, re.findall(r'\d+', node.get('bounds'))))
    subprocess.check_call(prefix + ['shell', 'input', 'tap', str((xy[0]+xy[2])//2), str((xy[1]+xy[3])//2)])

try:
    while time.monotonic() < deadline and phase < 3:
        text = Path(log).read_text(errors='replace') if Path(log).exists() else ''
        match = re.search(r'NATIVE_SHEET_FILE (\{[^\n]+\})', text)
        if match and metadata is None:
            metadata = json.loads(match[1])
            assert metadata['name'].startswith('In Jesus Name - ') and '/' not in metadata['name']
            saved = '/sdcard/Download/' + metadata['name']
            # Never overwrite an existing file, even on this disposable AVD.
            exists = subprocess.run(prefix + ['shell', 'test', '-e', shlex.quote(saved)], capture_output=True).returncode == 0
            assert not exists, 'The QA download target already exists'
        marker = 'NATIVE_SHEET_SAVE_READY' if phase == 0 else f'NATIVE_SHEET_CANCEL_READY_{phase}'
        if metadata is None or marker not in text:
            time.sleep(.3)
            continue
        try:
            subprocess.run(prefix + ['shell', 'uiautomator', 'dump', '/sdcard/praiseteam-download-qa.xml'],
                           timeout=12, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            raw = subprocess.check_output(prefix + ['shell', 'cat', '/sdcard/praiseteam-download-qa.xml'])
            nodes = list(ET.fromstring(raw).iter('node'))
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError, ET.ParseError):
            continue
        system = [n for n in nodes if 'documentsui' in n.get('package', '')]
        if not system:
            time.sleep(.3)
            continue
        if phase == 0:
            # Prefer Downloads when the picker initially presents another root.
            downloads = next((n for n in system if n.get('text') in ('Downloads', '다운로드')), None)
            if downloads is None:
                roots = next((n for n in system if n.get('content-desc') in ('Show roots', '루트 표시')), None)
                if roots is not None: tap(roots)
                time.sleep(.3)
                continue
            save = next((n for n in system if n.get('text', '').upper() in ('SAVE', '저장') and n.get('enabled') == 'true'), None)
            if save is None:
                tap(downloads)
                time.sleep(.3)
                continue
            (out/'android-save-dialog.png').write_bytes(subprocess.check_output(prefix+['exec-out','screencap','-p']))
            tap(save)
            owned_target = True
            for _ in range(30):
                result = subprocess.run(prefix+['exec-out','cat',saved], capture_output=True)
                if result.returncode == 0 and hashlib.sha256(result.stdout).hexdigest() == metadata['sha256']:
                    (out/'downloaded.pdf').write_bytes(result.stdout)
                    break
                time.sleep(.2)
            else: raise AssertionError('Saved PDF differs from the original or is missing')
            print('PASS native Android save dialog writes the exact original PDF.', flush=True)
        else:
            subprocess.check_call(prefix+['shell','input','keyevent','4'])
            print('PASS native Android save dialog cancellation '+str(phase), flush=True)
        phase += 1
        time.sleep(.5)
    assert phase == 3, 'Native save/cancel flow did not complete'
finally:
    if saved and owned_target:
        subprocess.run(prefix+['shell','rm','-f','--',shlex.quote(saved)], check=True)
