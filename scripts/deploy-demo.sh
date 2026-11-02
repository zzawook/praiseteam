#!/usr/bin/env bash
# The demo has no hosted database, auth, push or paid runtime.
set -euo pipefail
cd "$(dirname "$0")/.."
for media in praiseteam-tour-ko.mp4 praiseteam-tour-ko.vtt praiseteam-tour-poster.jpg; do
  if [[ ! -f "output/demo/$media" ]]; then
    echo "Missing output/demo/$media. Render the tour or restore its release assets first." >&2
    exit 2
  fi
done
if [[ "${1:-}" != "--skip-build" ]]; then
  (cd app && flutter build web --release --dart-define=DEMO_MODE=true --output=build/demo)
fi
python3 demo/prepare_web.py
cp demo/web/*.html app/build/demo/
if [[ -f output/demo/praiseteam-tour-ko.mp4 ]]; then
  cp output/demo/praiseteam-tour-ko.mp4 app/build/demo/
fi
if [[ -f output/demo/praiseteam-tour-ko.vtt ]]; then
  cp output/demo/praiseteam-tour-ko.vtt app/build/demo/
fi
if [[ -f output/demo/praiseteam-tour-poster.jpg ]]; then
  cp output/demo/praiseteam-tour-poster.jpg app/build/demo/
fi
firebase deploy --only hosting --project praiseteam-sg-demo --config firebase.demo.json --non-interactive
