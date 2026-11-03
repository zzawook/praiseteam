"""Keep approved UI captures and map their speech anchors to a replacement voice.

Both live panes use the same continuous time map. No cuts or frame interpolation
are introduced; the recorded UI state and annotation strokes stay intact.
"""
import argparse
import hashlib
import json
from pathlib import Path

MEDIA = Path(__file__).resolve().parent
WORK = MEDIA / 'work'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-timing', type=Path, required=True)
    parser.add_argument('--source-timeline', type=Path, required=True)
    args = parser.parse_args()
    old = json.loads(args.source_timing.read_text())
    old_story = {s['id']: s for s in json.loads(args.source_timeline.read_text())['scenes']}
    new = json.loads((MEDIA / 'timing.json').read_text())
    new_story = {s['id']: s for s in json.loads((WORK / 'timeline.json').read_text())['scenes']}
    clips = json.loads((WORK / 'clips.json').read_text())
    result = {'method': 'piecewise-linear', 'clips': {}}
    for name, clip in clips.items():
        scene = 'live' if name.startswith('live-') else name
        old_cues, new_cues = old['scenes'][scene]['cues'], new['scenes'][scene]['cues']
        points = [[0, 0]] + sorted([[value, new_cues[key]] for key, value in old_cues.items()])
        points += [[old_story[scene]['duration'], new_story[scene]['duration']]]
        slopes = []
        for (a, x), (b, y) in zip(points, points[1:]):
            assert b > a and y > x, f'{name}: non-monotonic cue map'
            slopes.append((y - x) / (b - a))
        assert min(slopes) > .4 and max(slopes) < 2.5, f'{name}: review extreme speed change {slopes}'
        result['clips'][name] = {
            'capture_sha256': sha(clip['file']), 'capture_start': clip['start'],
            'audio_sha256': new['scenes'][scene]['audio_sha256'],
            'source_audio_sha256': old['scenes'][scene]['audio_sha256'],
            'points': points,
        }
        print(name, 'time-map slopes', [round(slope, 3) for slope in slopes])
    (WORK / 'capture_retiming.json').write_text(json.dumps(result, indent=2) + '\n')


if __name__ == '__main__':
    main()
