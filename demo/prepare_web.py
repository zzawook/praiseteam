"""Name the separately built PWA and remove unused push-worker configuration."""
import hashlib
import json
import subprocess
from pathlib import Path
root = Path(__file__).resolve().parents[1]
web = root / 'app/build/demo'
manifest = web / 'manifest.json'
data = json.loads(manifest.read_text())
data.update(name='PraiseTeam Demo', short_name='PraiseTeam Demo', description='로그인 없이 둘러보는 찬양팀 샘플 데모')
manifest.write_text(json.dumps(data, ensure_ascii=False, indent=2)+'\n')
index = web / 'index.html'
index.write_text(index.read_text().replace('<title>PraiseTeam</title>', '<title>PraiseTeam Demo</title>').replace('content="PraiseTeam"', 'content="PraiseTeam Demo"'))
# Demo main never initializes Firebase. The copied production worker is unused.
(web / 'firebase-messaging-sw.js').unlink(missing_ok=True)

# A versioned media URL prevents returning visitors from playing a previously
# cached film after the script or voice has changed.
movie = web / 'praiseteam-tour-ko.mp4'
watch = web / 'watch.html'
if movie.exists() and watch.exists():
    version = hashlib.sha256(movie.read_bytes()).hexdigest()[:12]
    seconds = round(float(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_entries', 'format=duration',
        '-of', 'default=noprint_wrappers=1:nokey=1', str(movie),
    ])))
    watch.write_text(watch.read_text().replace('{{TOUR_VERSION}}', version)
                     .replace('{{TOUR_DURATION}}', f'{seconds // 60}분 {seconds % 60}초'))
