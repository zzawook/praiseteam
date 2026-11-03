"""Verify the built Android release, including native 16 KB page compatibility."""
import os
from pathlib import Path
import struct
import subprocess
import zipfile

root = Path(__file__).resolve().parents[1]
out = root / 'output/store/android'
sdk = Path(os.environ.get('ANDROID_SDK_ROOT', Path.home() / 'Android/Sdk'))
versions = [p for p in (sdk / 'build-tools').iterdir() if p.name.replace('.', '').isdigit()]
build_tools = max(versions, key=lambda p: tuple(map(int, p.name.split('.'))))
apk, aab = out / 'praiseteam-store.apk', out / 'praiseteam-store.aab'
subprocess.run([str(build_tools / 'apksigner'), 'verify', '--verbose', '--print-certs', str(apk)], check=True)
subprocess.run([str(build_tools / 'zipalign'), '-c', '-P', '16', '4', str(apk)], check=True)
subprocess.run(['jarsigner', '-verify', str(aab)], check=True)
for archive in (apk, aab):
    checked = 0
    with zipfile.ZipFile(archive) as z:
        for name in z.namelist():
            if not name.endswith('.so'):
                continue
            elf = z.read(name)
            if elf[:4] != b'\x7fELF' or elf[4] != 2:
                continue
            endian = '<' if elf[5] == 1 else '>'
            phoff = struct.unpack_from(endian + 'Q', elf, 32)[0]
            size, count = struct.unpack_from(endian + 'HH', elf, 54)
            for i in range(count):
                at = phoff + size * i
                if struct.unpack_from(endian + 'I', elf, at)[0] == 1:
                    alignment = struct.unpack_from(endian + 'Q', elf, at + 48)[0]
                    if alignment < 16384:
                        raise SystemExit(f'{archive.name}: {name} LOAD alignment is only {alignment}')
            checked += 1
    if not checked:
        raise SystemExit(f'{archive.name}: no 64-bit native libraries checked')
    print(f'{archive.name}: {checked} 64-bit libraries pass 16 KB ELF alignment')
print('Android release signatures and alignment passed.')
