"""Align visual cues to the already-approved narration without replacing it.

Requests word timestamps with the same voice and text, then verifies the
reference waveform matches the existing narration at zero lag. Cue times
include the renderer's 400 ms narration lead-in.
"""
import asyncio
from array import array
import hashlib
import json
import math
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MEDIA = ROOT / 'demo/media'
WORK = MEDIA / 'work'
ANCHORS = {
    'intro': {'rota': '로타를', 'setlist': '콘티를', 'sheets': '악보를', 'together': '흩어진'},
    'setlist': {'version': '버전을', 'edit': '순서와', 'publish': '콘티를 공지하면'},
    'songs': {'versions': '곡 안에', 'details': '각 버전의', 'history': '언제 불렀는지'},
    'rotation': {'status': '응답 상태를', 'auto': '자동 편성으로', 'blockouts': '참석하기 어려운', 'answer': '섬김 요청을'},
    'live': {'join': '라이브하기를', 'page': '페이지를 함께', 'cue': '한 번 더', 'unfollow': '따라가기를'},
    'notes': {'private': '나만의', 'shared': '팀이 함께 볼 필기를'},
    'chat': {'channels': '전체 공지와', 'poll': '투표로', 'notice': '중요한 안내를'},
    'home': {'overview': '홈을 열면', 'accept': '로타 요청이나', 'rsvp': '연습 참석 여부도', 'readiness': '리더는 준비 현황과'},
    'outro': {'samples': '데모에는', 'try': '직접 눌러 보고'},
}


def normalized(text):
    return re.sub(r'\W', '', text)


def cue_time(events, phrase):
    wanted = normalized(phrase)
    for i, event in enumerate(events):
        combined = ''
        for part in events[i:i + 7]:
            combined += normalized(part['text'])
            if combined.startswith(wanted):
                return round(event['offset'] / 10_000_000 + .4, 4)
            if not wanted.startswith(combined):
                break
    raise ValueError(f'No exact word boundary for: {phrase}')


def pcm(path):
    values = array('h', subprocess.check_output([
        'ffmpeg', '-v', 'error', '-i', str(path), '-ar', '24000', '-ac', '1', '-f', 's16le', '-',
    ]))
    if sys.byteorder != 'little':
        values.byteswap()
    return values


async def main():
    story = json.loads((MEDIA / 'storyboard.json').read_text())
    if story.get('narration_source', {}).get('type') == 'import':
        raise SystemExit('This film uses supplied audio. Run import_narration.py; do not regenerate the voice.')
    import edge_tts

    result = {'narration_delay': .4, 'scenes': {}}
    for scene in story['scenes']:
        name = scene['id']
        reference = WORK / f'{name}-alignment.mp3'
        boundaries = WORK / f'{name}-word-boundaries.json'
        if not reference.exists() or not boundaries.exists():
            events = []
            with reference.open('wb') as output:
                async for chunk in edge_tts.Communicate(
                    scene['narration'], story['voice'], rate='+0%', boundary='WordBoundary',
                ).stream():
                    if chunk['type'] == 'audio':
                        output.write(chunk['data'])
                    elif chunk['type'] == 'WordBoundary':
                        events.append(chunk)
            boundaries.write_text(json.dumps(events, ensure_ascii=False, indent=2))
        events = json.loads(boundaries.read_text())
        original = WORK / f'{name}.mp3'
        a, b = pcm(original), pcm(reference)
        assert len(a) == len(b), f'{name}: alignment audio duration changed'
        similarity = sum(x * y for x, y in zip(a, b)) / math.sqrt(sum(x * x for x in a) * sum(y * y for y in b))
        assert similarity > .985, f'{name}: alignment audio does not match ({similarity:.5f})'
        times = {key: cue_time(events, phrase) for key, phrase in ANCHORS[name].items()}
        result['scenes'][name] = {
            'audio_sha256': hashlib.sha256(original.read_bytes()).hexdigest(),
            'narration_sha256': hashlib.sha256(scene['narration'].encode()).hexdigest(),
            'waveform_similarity': round(similarity, 6),
            'cues': times,
        }
        print(name, times, flush=True)
    (MEDIA / 'timing.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    asyncio.run(main())
