"""Generate the approved, non-private marketing narration and timing files."""
import asyncio
import hashlib
import json
import subprocess
from pathlib import Path
import edge_tts

ROOT = Path(__file__).resolve().parents[2]
STORY = ROOT / 'demo/media/storyboard.json'
WORK = ROOT / 'demo/media/work'
WORK.mkdir(parents=True, exist_ok=True)


def fingerprint(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


async def main():
    story = json.loads(STORY.read_text())
    if story.get('narration_source', {}).get('type') == 'import':
        raise SystemExit('This film uses supplied audio. Run import_narration.py; do not regenerate the voice.')
    story_hash = fingerprint(story)
    total = 0
    for scene in story['scenes']:
        audio = WORK / (scene['id'] + '.mp3')
        subtitle = WORK / (scene['id'] + '.srt')
        stamp = WORK / (scene['id'] + '.speech.sha256')
        rate = '+0%'
        speech_hash = fingerprint({'text': scene['narration'], 'voice': story['voice'], 'rate': rate})
        cached = audio.exists() and subtitle.exists() and stamp.exists() and stamp.read_text().strip() == speech_hash
        if not cached:
            speech = edge_tts.Communicate(scene['narration'], story['voice'], rate=rate)
            maker = edge_tts.SubMaker()
            pending_audio = audio.with_suffix('.pending.mp3')
            with pending_audio.open('wb') as output:
                async for chunk in speech.stream():
                    if chunk['type'] == 'audio':
                        output.write(chunk['data'])
                    elif chunk['type'] in ('WordBoundary', 'SentenceBoundary'):
                        maker.feed(chunk)
            pending_subtitle = subtitle.with_suffix('.pending.srt')
            pending_subtitle.write_text(maker.get_srt(), encoding='utf-8')
            subprocess.run(['ffprobe', '-v', 'error', str(pending_audio)], check=True)
            if not pending_subtitle.read_text().strip():
                raise RuntimeError(f'No subtitles generated for {scene["id"]}')
            pending_audio.replace(audio)
            pending_subtitle.replace(subtitle)
            stamp.write_text(speech_hash + '\n')
        duration = float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', str(audio)]))
        scene['voice_duration'] = duration
        scene['duration'] = duration + 1
        scene['starts_at'] = total
        total += duration + 0.4
        print(scene['id'], round(duration, 2), flush=True)
    story['duration'] = total + 0.6
    story['story_sha256'] = story_hash
    (WORK / 'timeline.json').write_text(json.dumps(story, ensure_ascii=False, indent=2))
    print('Film duration:', round(story['duration'], 2), 'seconds')


if __name__ == '__main__':
    asyncio.run(main())
