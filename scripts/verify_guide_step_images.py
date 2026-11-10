"""Check source pixels survive every screenshot crop outside the step marker."""
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    data = json.loads((ROOT / 'docs/guide/steps.ko.json').read_text())
    total = 0
    for topic in data['topics']:
        for step in topic['steps']:
            spec = step['image']
            x, y, w, h = spec['crop']
            with Image.open(ROOT / 'docs/guide/source-captures' / (spec['source'] + '.png')) as image:
                expected = np.asarray(image.convert('RGB').crop((x*2, y*2, (x+w)*2, (y+h)*2)))
            with Image.open(ROOT / 'docs/guide/step-images' / spec['file']) as image:
                actual = np.asarray(image.convert('RGB'))
            assert actual.shape == expected.shape, spec['file']
            compare = np.ones(actual.shape[:2], dtype=bool)
            def exclude(left, top, right, bottom):
                compare[max(0, math.floor(top*2)):min(h*2, math.ceil(bottom*2)),
                        max(0, math.floor(left*2)):min(w*2, math.ceil(right*2))] = False
            if box := spec.get('box'):
                left, top = box['x'] - x, box['y'] - y
                right, bottom = left + box['width'], top + box['height']
                for area in [(left-4, top-4, right+4, top+5), (left-4, bottom-5, right+4, bottom+4),
                             (left-4, top-4, left+5, bottom+4), (right-5, top-4, right+4, bottom+4)]:
                    exclude(*area)
                # Rounded corners and the numeric badge are the only overlays.
                for a, b in [(left, top), (right-8, top), (left, bottom-8), (right-8, bottom-8)]:
                    exclude(a-2, b-2, a+10, b+10)
                badge_x, badge_y = max(0, left-9), max(0, top-13)
                exclude(badge_x-2, badge_y-2, badge_x+25, badge_y+25)
            mismatch = float(np.any(actual != expected, axis=2)[compare].mean())
            assert mismatch < .002, f'{spec["file"]}: {mismatch:.2%} of source pixels changed outside the marker'
            total += 1
    print(f'PASS: all {total} crops retain their source screenshot pixels outside the numbered markers.')


if __name__ == '__main__':
    main()
