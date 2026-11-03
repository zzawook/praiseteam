"""Fail if the sample score's unchanged title disappears during annotations.

Checks every captured frame, before any editing or chapter transitions. The
ROI is the title of the fixed 1280x800 demo score, above the annotation area.
"""
import json
import statistics
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
clip = json.loads((ROOT / 'demo/media/work/clips.json').read_text())['notes']
assert (clip['width'], clip['height']) == (1280, 800)
frames = subprocess.check_output([
    'ffmpeg', '-v', 'error', '-ss', str(clip['start']), '-i', clip['file'],
    '-t', '13.4', '-vf', 'fps=30,crop=400:70:430:98,format=gray', '-f', 'rawvideo', '-',
])
frame_bytes = 400 * 70
assert len(frames) % frame_bytes == 0
densities = [
    sum(pixel < 210 for pixel in frames[i:i + frame_bytes]) / frame_bytes
    for i in range(0, len(frames), frame_bytes)
]
assert len(densities) >= 390, 'The annotation capture is too short'
baseline = statistics.median(densities)
assert baseline > .02, 'The score title must be visible in this fixture'
blank = [i for i, density in enumerate(densities) if density < baseline * .5]
assert not blank, f'Score disappeared at clip seconds: {[round(i / 30, 3) for i in blank]}'
print(f'PASS: score stays visible in all {len(densities)} annotation frames.')
