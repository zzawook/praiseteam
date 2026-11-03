"""Prepare a clearly marked silent review when narration cannot be generated.

Uses the last successful voice timings only to estimate reading time. It never
changes the production audio, its timing manifest, or the published MP4.
"""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
WORK = ROOT / 'demo/media/work'
PREVIEW = WORK / 'preview'
PREVIEW.mkdir(parents=True, exist_ok=True)


def spoken_length(value):
    return max(1, len(re.sub(r'\W', '', value)))


def timestamp(value):
    millis = round(value * 1000)
    return f'{millis // 3600000:02}:{millis // 60000 % 60:02}:{millis // 1000 % 60:02},{millis % 1000:03}'


def main():
    story = json.loads((ROOT / 'demo/media/storyboard.json').read_text())
    digest = hashlib.sha256(json.dumps(story, ensure_ascii=False, sort_keys=True).encode()).hexdigest()
    previous = json.loads((WORK / 'timeline.json').read_text())
    old = {scene['id']: scene for scene in previous['scenes']}
    total = 0
    for scene in story['scenes']:
        prior = old[scene['id']]
        length = spoken_length(scene['narration'])
        voice_duration = prior['voice_duration'] * length / spoken_length(prior['narration'])
        scene.update(voice_duration=voice_duration, duration=voice_duration + 1, starts_at=total)
        total += voice_duration + .4
        sentences = re.split(r'(?<=[.!?])\s+', scene['narration'].strip())
        weights = [spoken_length(sentence) for sentence in sentences]
        elapsed = .1
        subtitles = []
        for i, (sentence, weight) in enumerate(zip(sentences, weights), 1):
            end = min(voice_duration, elapsed + (voice_duration - .1) * weight / sum(weights))
            subtitles.append(f'{i}\n{timestamp(elapsed)} --> {timestamp(end)}\n{sentence}\n')
            elapsed = end
        (PREVIEW / f'{scene["id"]}.srt').write_text('\n'.join(subtitles))
    story.update(duration=total + .6, story_sha256=digest, preview=True, timing_estimated=True)
    (PREVIEW / 'timeline.json').write_text(json.dumps(story, ensure_ascii=False, indent=2) + '\n')
    print(f'Silent review: {story["duration"]:.1f}s; subtitle timing is provisional.', flush=True)


if __name__ == '__main__':
    main()
