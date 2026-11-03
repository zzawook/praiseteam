"""Check that the finished film contains every supplied voice track on time.

Requires NumPy (included in requirements-align.txt) and FFmpeg. Compares decoded
waveforms, including each ending, to catch missing speech or cumulative drift
after chapter crossfades. Does not require the alignment model or GPU.
"""
import hashlib
import json
import subprocess
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'demo/media/work'
RATE = 8000


def pcm(path):
    return np.frombuffer(subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', str(path), '-ac', '1', '-ar', str(RATE),
        '-f', 'f32le', '-',
    ]), dtype=np.float32)


def similarity(a, b):
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))


def main():
    story = json.loads((WORK / 'timeline.json').read_text())
    timing = json.loads((ROOT / 'demo/media/timing.json').read_text())
    film = ROOT / 'output/demo/praiseteam-tour-ko.mp4'
    whole = pcm(film)
    probe = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(film),
    ]))
    video = next(stream for stream in probe['streams'] if stream['codec_type'] == 'video')
    assert (video['width'], video['height']) == (1920, 1080)
    assert abs(float(probe['format']['duration']) - story['duration']) < .05
    report = []
    for scene in story['scenes']:
        name = scene['id']
        source = WORK / f'{name}.mp3'
        assert hashlib.sha256(source.read_bytes()).hexdigest() == timing['scenes'][name]['audio_sha256']
        original = pcm(source).astype(np.float64)
        start = round((scene['starts_at'] + timing['narration_delay']) * RATE)
        pad = round(.2 * RATE)
        begin = max(0, start - pad)
        window = whole[begin:start + len(original) + pad].astype(np.float64)
        original -= original.mean()
        window -= window.mean()
        n = 1 << (len(window) + len(original) - 1).bit_length()
        correlation = np.fft.irfft(np.fft.rfft(window, n) * np.conj(np.fft.rfft(original, n)), n)
        offset = int(np.argmax(correlation[:len(window) - len(original) + 1]))
        matched = window[offset:offset + len(original)]
        lag = (begin + offset - start) / RATE
        score = similarity(matched, original)
        ending = similarity(matched[-RATE // 2:], original[-RATE // 2:])
        assert abs(lag) < 1 / 30, f'{name}: narration drift {lag:.3f}s'
        assert score > .97, f'{name}: narration differs from supplied track ({score:.3f})'
        assert ending > .92, f'{name}: missing/changed ending ({ending:.3f})'
        check = {'scene': name, 'offset_seconds': lag,
                 'waveform_correlation': round(score, 5), 'ending_correlation': round(ending, 5)}
        report.append(check)
        print(check)
    (WORK / 'narration-verification.json').write_text(json.dumps(report, indent=2) + '\n')
    print(f'PASS: {len(report)} voice tracks, complete and aligned within one video frame.')


if __name__ == '__main__':
    main()
