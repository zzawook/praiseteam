"""Export existing icons and render the store's vector feature artwork.

Run with the media Python environment (cairosvg installed). No source icon or
app screenshot is retouched; icon files are copied at their existing sizes.
"""
from pathlib import Path
import shutil
import cairosvg

root = Path(__file__).resolve().parents[1]
out = root / 'output/store/listing'
out.mkdir(parents=True, exist_ok=True)
shutil.copy2(root / 'app/web/icons/Icon-512.png', out / 'play-icon-512.png')
shutil.copy2(root / 'app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png', out / 'apple-icon-1024.png')
svg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="500" viewBox="0 0 1024 500">
<rect width="1024" height="500" fill="#F4F5F2"/>
<path d="M640 118H950M640 176H950M640 234H950M640 292H950M640 350H950" stroke="#DADDD6" stroke-width="2"/>
<path d="M690 380V172H824V322" fill="none" stroke="#2541B2" stroke-width="16" stroke-linejoin="round"/>
<ellipse cx="668" cy="378" rx="34" ry="24" fill="#2541B2" transform="rotate(-18 668 378)"/>
<ellipse cx="802" cy="320" rx="34" ry="24" fill="#2541B2" transform="rotate(-18 802 320)"/>
<path d="M884 254V104" stroke="#2541B2" stroke-width="12"/>
<ellipse cx="862" cy="254" rx="29" ry="21" fill="#2541B2" transform="rotate(-18 862 254)"/>
<text x="70" y="106" font-family="sans-serif" font-size="28" font-weight="bold" fill="#2541B2">PraiseTeam</text>
<text x="66" y="218" font-family="Noto Sans CJK KR,sans-serif" font-size="48" font-weight="bold" fill="#1D1F23">찬양팀의 준비를</text>
<text x="66" y="284" font-family="Noto Sans CJK KR,sans-serif" font-size="48" font-weight="bold" fill="#1D1F23">한곳에</text>
<text x="70" y="374" font-family="Noto Sans CJK KR,sans-serif" font-size="22" fill="#5B6068">예배 · 곡 · 로테이션 · 라이브</text>
</svg>'''
(out / 'play-feature-ko.svg').write_text(svg)
cairosvg.svg2png(bytestring=svg.encode(), write_to=str(out / 'play-feature-ko.png'))
print(out)
