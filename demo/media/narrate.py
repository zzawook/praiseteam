"""Generate the approved, non-private marketing narration and timing files."""
import asyncio
import json
import subprocess
from pathlib import Path
import edge_tts

ROOT = Path(__file__).resolve().parents[2]
STORY = ROOT / 'demo/media/storyboard.json'
WORK = ROOT / 'demo/media/work'
WORK.mkdir(parents=True, exist_ok=True)


async def main():
    story = json.loads(STORY.read_text())
    total = 0
    for scene in story['scenes']:
        audio = WORK / (scene['id'] + '.mp3')
        subtitle = WORK / (scene['id'] + '.srt')
        if not audio.exists():
            speech = edge_tts.Communicate(scene['narration'], story['voice'], rate='+0%')
            maker = edge_tts.SubMaker()
            with audio.open('wb') as output:
                async for chunk in speech.stream():
                    if chunk['type'] == 'audio':
                        output.write(chunk['data'])
                    elif chunk['type'] in ('WordBoundary', 'SentenceBoundary'):
                        maker.feed(chunk)
            subtitle.write_text(maker.get_srt(), encoding='utf-8')
        duration = float(subprocess.check_output(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', str(audio)]))
        scene['voice_duration'] = duration
        scene['duration'] = duration + 1
        scene['starts_at'] = total
        total += duration + 0.4
        print(scene['id'], round(duration, 2), flush=True)
    story['duration'] = total + 0.6
    (WORK / 'timeline.json').write_text(json.dumps(story, ensure_ascii=False, indent=2))
    print('Film duration:', round(story['duration'], 2), 'seconds')


asyncio.run(main())
