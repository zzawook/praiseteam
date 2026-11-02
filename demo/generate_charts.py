"""Original, clearly labeled practice charts for the public sample release."""
from pathlib import Path
import json
import shutil
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'output/pdf'
ASSETS = ROOT / 'app/assets/demo'
OUTPUT.mkdir(parents=True, exist_ok=True)
pdfmetrics.registerFont(TTFont('GowunDemo', str(ROOT / 'app/assets/fonts/GowunBatang-Bold-subset.ttf')))
reference = json.loads((ASSETS / 'reference.json').read_text())
blue, ink, muted = map(HexColor, ['#2541B2', '#1D2433', '#667085'])
width, height = A4


def page(c, title, key, bpm, page_number, pages, alternate=False):
    c.setFillColor(blue)
    c.rect(42, height - 65, 5, 25, fill=1, stroke=0)
    c.setFont('GowunDemo', 26)
    c.drawString(60, height - 61, title)
    c.setFont('GowunDemo', 11)
    c.setFillColor(muted)
    c.drawString(44, height - 87, 'PraiseTeam - 화면 시연용 연습 차트')
    c.setFillColor(ink)
    c.setFont('Helvetica-Bold', 13)
    c.drawString(44, height - 119, f'KEY {key}     {bpm} BPM     4/4')
    c.setStrokeColor(HexColor('#D9DFE9'))
    c.line(44, height - 135, width - 44, height - 135)
    c.setFont('Helvetica', 12)
    c.drawString(44, height - 157, 'I - V1 - C - V2 - C - B - C - O' if not alternate else 'B - C - C - O')
    chords = ['G', 'D/F#', 'Em7', 'Cadd9'] if key == 'G' else ['A', 'E/G#', 'F#m7', 'Dadd9']
    labels = [('INTRO', '함께 호흡을 맞추며'), ('VERSE', '멜로디가 잘 들리도록'), ('CHORUS', '충분히 열어 주기'), ('BRIDGE', '인도자의 큐를 확인해요')]
    if alternate:
        labels = [('BRIDGE', '한 번 더 반복'), ('CHORUS', '다 함께'), ('CHORUS', '작게 시작해 크게'), ('ENDING', '마지막 코드를 충분히')]
    top = height - 201
    cell = (width - 88) / 4
    for row, (label, note) in enumerate(labels):
        y = top - row * 108
        c.setFont('Helvetica-Bold', 12)
        c.setFillColor(blue)
        c.drawString(44, y, label)
        c.setFont('GowunDemo', 10)
        c.setFillColor(muted)
        c.drawRightString(width - 44, y, note)
        c.setStrokeColor(HexColor('#CED5DF'))
        c.setLineWidth(0.8)
        c.rect(44, y - 69, width - 88, 54, fill=0, stroke=1)
        for col, chord in enumerate(chords):
            x = 44 + col * cell
            if col:
                c.line(x, y - 69, x, y - 15)
            c.setFillColor(ink)
            c.setFont('Helvetica-Bold', 22)
            c.drawCentredString(x + cell / 2, y - 49, chord)
    c.setFillColor(muted)
    c.setFont('GowunDemo', 9)
    c.drawString(44, 64, '앱 기능을 보여주기 위해 만든 예시입니다. 실제 곡의 악보가 아닙니다.')
    c.setFont('Helvetica', 9)
    c.drawString(44, 47, 'Original demonstration chart - no lyrics or musical score reproduced.')
    c.drawRightString(width - 44, 47, f'{page_number} / {pages}')
    c.showPage()


for number, song_index, key, pages in [(1, 0, 'G', 2), (2, 0, 'A', 1), (3, 1, 'G', 1)]:
    target = OUTPUT / f'demo-chart-{number}.pdf'
    c = canvas.Canvas(str(target), pagesize=A4)
    song = reference['songs'][song_index]
    c.setTitle(f"{song['title']} - demonstration practice chart")
    c.setAuthor('PraiseTeam Demo')
    for index in range(pages):
        page(c, song['title'], key, (song['bpm'] or 72) + (4 if number == 2 else 0), index + 1, pages, index > 0)
    c.save()
    shutil.copyfile(target, ASSETS / target.name)
    print(target.name, target.stat().st_size)
