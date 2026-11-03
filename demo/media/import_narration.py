"""Import approved MP3s unchanged and align the script locally to their speech.

Use Python 3.12 and requirements-align.txt. Model weights are downloaded once;
the supplied audio is processed locally, never uploaded to a speech service.
"""
import argparse
import hashlib
import json
import re
import shutil
import subprocess
from pathlib import Path

from align_cues import ANCHORS, normalized

MEDIA = Path(__file__).resolve().parent
WORK = MEDIA / 'work'
MODEL = 'kresnik/wav2vec2-large-xlsr-korean'
DELAY = .4


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fingerprint(value):
    return hashlib.sha256(json.dumps(value, ensure_ascii=False, sort_keys=True).encode()).hexdigest()


def duration(path):
    return float(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_entries', 'format=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1', str(path),
    ]))


def save_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n')


def cue_time(words, phrase):
    wanted = normalized(phrase)
    for index, word in enumerate(words):
        combined = ''
        for part in words[index:index + 10]:
            combined += normalized(part['word'])
            if combined.startswith(wanted):
                return round(float(word['start']) + DELAY, 3)
            if not wanted.startswith(combined):
                break
    raise ValueError(f'Missing aligned phrase: {phrase}')


def srt_timestamp(seconds):
    ms = round(seconds * 1000)
    return f'{ms // 3600000:02}:{ms // 60000 % 60:02}:{ms // 1000 % 60:02},{ms % 1000:03}'


def write_subtitles(path, words):
    groups, pending = [], []
    for word in words:
        text = ' '.join(part['word'] for part in [*pending, word])
        if pending and (len(text) > 54 or word['end'] - pending[0]['start'] > 5.5):
            groups.append(pending)
            pending = []
        pending.append(word)
        if re.search(r'[.!?]$', word['word']):
            groups.append(pending)
            pending = []
    if pending:
        groups.append(pending)
    blocks = []
    for index, group in enumerate(groups):
        start, end = group[0]['start'], group[-1]['end'] + .12
        if index + 1 < len(groups):
            end = min(end, groups[index + 1][0]['start'])
        blocks.append(f'{index + 1}\n{srt_timestamp(start)} --> {srt_timestamp(end)}\n' +
                      ' '.join(word['word'] for word in group))
    path.write_text('\n\n'.join(blocks) + '\n')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source_dir', type=Path, help='Directory containing supplied MP3 filenames')
    parser.add_argument('--device', choices=['cuda', 'cpu'], default='cpu')
    args = parser.parse_args()
    story = json.loads((MEDIA / 'storyboard.json').read_text())
    source = story.get('narration_source', {})
    assert source.get('type') == 'import', 'Storyboard must select imported narration'
    manifest = json.loads((MEDIA / source['manifest']).read_text())
    assert set(manifest['scenes']) == {scene['id'] for scene in story['scenes']}
    WORK.mkdir(exist_ok=True)
    # Validate all sources before replacing any approved working audio.
    for scene in story['scenes']:
        source = manifest['scenes'][scene['id']]
        assert sha(args.source_dir / source['filename']) == source['sha256'], scene['id']
    story_hash = fingerprint(story)
    result = {'narration_delay': DELAY, 'alignment': {'method': 'forced', 'model': MODEL}, 'scenes': {}}
    model = metadata = None
    total = 0
    for scene in story['scenes']:
        name = scene['id']
        source = manifest['scenes'][name]
        source_audio = args.source_dir / source['filename']
        audio = WORK / f'{name}.mp3'
        voice_duration = duration(source_audio)
        stamp = {'audio_sha256': source['sha256'],
                 'narration_sha256': hashlib.sha256(scene['narration'].encode()).hexdigest(),
                 'model': MODEL}
        cache = WORK / f'{name}-import-alignment.json'
        aligned = json.loads(cache.read_text()) if cache.exists() else {}
        if aligned.get('source') != stamp:
            import whisperx
            if model is None:
                model, metadata = whisperx.load_align_model('ko', args.device, model_name=MODEL)
            waveform = whisperx.load_audio(str(source_audio))
            alignment = whisperx.align(
                [{'start': 0, 'end': len(waveform) / 16000, 'text': scene['narration']}],
                model, metadata, waveform, args.device, return_char_alignments=True,
            )
            aligned = {'source': stamp, **alignment}
            save_json(cache, aligned)
        words = aligned['word_segments']
        assert normalized(''.join(word['word'] for word in words)) == normalized(scene['narration']), name
        assert all('start' in word and 'end' in word for word in words), f'{name}: incomplete alignment'
        assert all(a['start'] <= b['start'] for a, b in zip(words, words[1:])), name
        assert 0 <= words[0]['start'] < 1.5 and words[-1]['end'] <= voice_duration, name
        cues = {key: cue_time(words, phrase) for key, phrase in ANCHORS[name].items()}
        result['scenes'][name] = {**stamp, 'cues': cues}
        shutil.copyfile(source_audio, audio)
        assert sha(audio) == source['sha256'], f'{name}: imported audio changed'
        write_subtitles(WORK / f'{name}.srt', words)
        scene.update(voice_duration=voice_duration, duration=voice_duration + 1, starts_at=total)
        total += voice_duration + DELAY
        print(name, round(voice_duration, 3), cues, flush=True)
    story.update(duration=total + .6, story_sha256=story_hash)
    save_json(WORK / 'timeline.json', story)
    save_json(MEDIA / 'timing.json', result)
    print(f'Imported nine unchanged voice tracks. Film duration: {story["duration"]:.3f}s')


if __name__ == '__main__':
    main()
