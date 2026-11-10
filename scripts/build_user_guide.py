"""Build the Korean member guide from its maintained content file.

Run with the bundled Codex document Python runtime (python-docx).
Render the DOCX with the documents skill's render_docx.py and inspect every
page before distributing either the DOCX or its PDF export.
"""
import json
import re
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Mm, Pt, RGBColor
from docx.opc.constants import RELATIONSHIP_TYPE as RT
from embed_guide_fonts import embed_fonts

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/guide'
FONT = 'Noto Sans KR'
INK = '000000'
STYLE_COLORS = {'Title': '17365D', 'Heading 1': '365F91', 'Heading 2': '4F81BD', 'Subtitle': '4F81BD'}


def explicit_fonts(rpr):
    fonts = rpr.find(qn('w:rFonts'))
    if fonts is None:
        fonts = OxmlElement('w:rFonts'); rpr.insert(0, fonts)
    for key in list(fonts.attrib):
        if key.lower().endswith('theme'):
            del fonts.attrib[key]
    for key in ['ascii', 'hAnsi', 'eastAsia', 'cs']:
        fonts.set(qn(f'w:{key}'), FONT)


def explicit_color(rpr, value):
    color = rpr.find(qn('w:color'))
    if color is None:
        color = OxmlElement('w:color'); rpr.append(color)
    color.attrib.clear(); color.set(qn('w:val'), value)


def internal_link(paragraph, label, target):
    link = OxmlElement('w:hyperlink')
    link.set(qn('w:anchor'), 'guide_' + target)
    link.set(qn('w:history'), '1')
    run = OxmlElement('w:r')
    props = OxmlElement('w:rPr')
    explicit_fonts(props)
    color = OxmlElement('w:color'); color.set(qn('w:val'), '2541B2'); props.append(color)
    underline = OxmlElement('w:u'); underline.set(qn('w:val'), 'single'); props.append(underline)
    run.append(props)
    text = OxmlElement('w:t'); text.text = label; run.append(text)
    link.append(run); paragraph._p.append(link)


def bookmark(paragraph, name, number):
    start = OxmlElement('w:bookmarkStart')
    start.set(qn('w:id'), str(number)); start.set(qn('w:name'), 'guide_' + name)
    end = OxmlElement('w:bookmarkEnd'); end.set(qn('w:id'), str(number))
    paragraph._p.insert(1 if paragraph._p.pPr is not None else 0, start)
    paragraph._p.append(end)


def font(style, size, bold=False, color=INK):
    style.font.name = FONT
    style.font.size = Pt(size)
    style.font.bold = bold
    style.font.italic = False
    style.font.color.rgb = RGBColor.from_string(color)
    rpr = style.element.get_or_add_rPr()
    explicit_fonts(rpr)
    explicit_color(rpr, color)
    for name, value in [('szCs', str(round(size*2))), ('bCs', '1' if bold else '0'), ('iCs', '0')]:
        element = rpr.find(qn('w:'+name))
        if element is None:
            element = OxmlElement('w:'+name); rpr.append(element)
        element.set(qn('w:val'), value)


def rich(paragraph, value):
    position = 0
    for match in re.finditer(r'\*\*(.*?)\*\*|\[\[([a-z_0-9]+)\|([^\]]+)\]\]', value):
        if match.start() > position:
            paragraph.add_run(value[position:match.start()])
        if match.group(1) is not None:
            paragraph.add_run(match.group(1)).bold = True
        else:
            internal_link(paragraph, match.group(3), match.group(2))
        position = match.end()
    if position < len(value):
        paragraph.add_run(value[position:])
    return paragraph


def para(doc, text, style=None):
    p = doc.add_paragraph(style=style)
    rich(p, text)
    if style in STYLE_COLORS:
        # Explicit run values also survive importers that use linked character
        # styles differently from Word's paragraph styles.
        for run in p.runs:
            explicit_fonts(run._r.get_or_add_rPr())
            explicit_color(run._r.get_or_add_rPr(), STYLE_COLORS[style])
    p.paragraph_format.keep_together = True
    return p


def list_numbering(doc, kind):
    root = doc.part.numbering_part.element
    abstract_id = max([int(n.get(qn('w:abstractNumId'))) for n in root.findall(qn('w:abstractNum'))] + [-1]) + 1
    num_id = max([int(n.get(qn('w:numId'))) for n in root.findall(qn('w:num'))] + [0]) + 1
    abstract = OxmlElement('w:abstractNum')
    abstract.set(qn('w:abstractNumId'), str(abstract_id))
    lvl = OxmlElement('w:lvl'); lvl.set(qn('w:ilvl'), '0')
    for name, value in [('start', '1'), ('numFmt', kind), ('lvlText', '%1.' if kind == 'decimal' else '•'), ('lvlJc', 'left')]:
        element = OxmlElement(f'w:{name}'); element.set(qn('w:val'), value); lvl.append(element)
    ppr = OxmlElement('w:pPr')
    ind = OxmlElement('w:ind'); ind.set(qn('w:left'), '300'); ind.set(qn('w:hanging'), '300'); ppr.append(ind)
    lvl.append(ppr); abstract.append(lvl); root.append(abstract)
    marker_fonts = OxmlElement('w:rPr')
    explicit_fonts(marker_fonts)
    lvl.append(marker_fonts)
    num = OxmlElement('w:num'); num.set(qn('w:numId'), str(num_id))
    ref = OxmlElement('w:abstractNumId'); ref.set(qn('w:val'), str(abstract_id)); num.append(ref); root.append(num)
    return num_id


def add_list(doc, values, kind):
    num_id = list_numbering(doc, kind)
    for value in values:
        p = para(doc, value)
        ppr = p._p.get_or_add_pPr()
        numpr = OxmlElement('w:numPr')
        level = OxmlElement('w:ilvl'); level.set(qn('w:val'), '0')
        num = OxmlElement('w:numId'); num.set(qn('w:val'), str(num_id))
        numpr.extend([level, num]); ppr.append(numpr)
        p.paragraph_format.left_indent = Mm(5.3)
        p.paragraph_format.first_line_indent = Mm(-5.3)


def table(doc, spec):
    t = doc.add_table(rows=1, cols=2)
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    t.autofit = False
    widths = [Mm(43), Mm(129)]
    for col, width in zip(t.columns, widths): col.width = width
    header = OxmlElement('w:tblHeader'); t.rows[0]._tr.get_or_add_trPr().append(header)
    for i, row_values in enumerate([spec['headers'], *spec['rows']]):
        row = t.rows[0] if i == 0 else t.add_row()
        row._tr.get_or_add_trPr().append(OxmlElement('w:cantSplit'))
        for j, value in enumerate(row_values):
            cell = row.cells[j]; cell.width = widths[j]
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            tcpr = cell._tc.get_or_add_tcPr()
            borders = OxmlElement('w:tcBorders')
            for edge in ['top', 'left', 'bottom', 'right']:
                el = OxmlElement(f'w:{edge}')
                for key, val in [('val', 'single'), ('sz', '4'), ('color', 'D9D9D9')]: el.set(qn(f'w:{key}'), val)
                borders.append(el)
            tcpr.append(borders)
            margins = OxmlElement('w:tcMar')
            for edge, width in [('top', '65'), ('bottom', '65'), ('left', '100'), ('right', '100')]:
                el = OxmlElement(f'w:{edge}'); el.set(qn('w:w'), width); el.set(qn('w:type'), 'dxa'); margins.append(el)
            tcpr.append(margins)
            shade = OxmlElement('w:shd')
            shade.set(qn('w:fill'), '243B60' if i == 0 else ('F3F5F8' if i % 2 == 0 else 'FFFFFF'))
            tcpr.append(shade)
            p = cell.paragraphs[0]; rich(p, value)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = Pt(15)
            p.paragraph_format.keep_together = True
            if i == 0: p.paragraph_format.keep_with_next = True
            for run in p.runs:
                run.font.size = Pt(10)
                if i == 0:
                    run.bold = True
                    run.font.color.rgb = RGBColor(255, 255, 255)
    p = doc.add_paragraph(); p.paragraph_format.space_after = Pt(0); p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.line_spacing = Pt(3); p.add_run().font.size = Pt(1)


def main():
    source = ROOT / 'docs/guide/steps.ko.json'
    data = json.loads(source.read_text())
    required = [ROOT / 'docs/guide/step-images' / step['image']['file']
                for topic in data['topics'] for step in topic['steps']]
    missing = [str(path) for path in required if not path.exists()]
    if missing:
        raise SystemExit('Finish prepare_guide_step_images.cjs before building: ' + ', '.join(missing))
    doc = Document()
    sec = doc.sections[0]
    sec.page_width, sec.page_height = Mm(210), Mm(297)
    sec.top_margin, sec.bottom_margin = Mm(17), Mm(17)
    sec.left_margin = sec.right_margin = Mm(19)
    sec.footer_distance = Mm(8)
    normal = doc.styles['Normal']; font(normal, 11)
    normal.paragraph_format.line_spacing = Pt(16.5)
    normal.paragraph_format.space_after = Pt(4)
    for name, size in [('Title', 24), ('Subtitle', 11), ('Heading 1', 19), ('Heading 2', 12)]:
        s = doc.styles[name]; font(s, size, bold=name != 'Subtitle', color=STYLE_COLORS[name])
        linked = {'Title': 'Title Char', 'Subtitle': 'Subtitle Char', 'Heading 1': 'Heading 1 Char', 'Heading 2': 'Heading 2 Char'}[name]
        if linked in doc.styles:
            font(doc.styles[linked], size, bold=name != 'Subtitle', color=STYLE_COLORS[name])
        s.paragraph_format.space_before = Pt(9 if name == 'Heading 2' else 0)
        s.paragraph_format.space_after = Pt(5)
        s.paragraph_format.keep_with_next = True
        s.paragraph_format.line_spacing = Pt(size * 1.4)
        ppr = s.element.get_or_add_pPr()
        for border in list(ppr.findall(qn('w:pBdr'))): ppr.remove(border)
    defaults = doc.styles.element.find(qn('w:docDefaults')).find(qn('w:rPrDefault')).find(qn('w:rPr'))
    explicit_fonts(defaults)
    for name in ['Footer', 'Footer Char']:
        if name in doc.styles:
            font(doc.styles[name], 8.5)
    doc.core_properties.title = data['title']
    doc.core_properties.subject = '찬양팀 가입과 콘티 로타 연습 라이브 사용 안내'
    doc.core_properties.author = 'PraiseTeam'
    doc.core_properties.keywords = '찬양팀, 콘티, 악보, 로타, 라이브, 사용 가이드'
    footer = sec.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    internal_link(footer, '목차로', 'contents')
    run = footer.add_run(f'    {data["title"]}  |  ')
    run.font.size = Pt(8.5)
    field = OxmlElement('w:fldSimple'); field.set(qn('w:instr'), 'PAGE'); footer._p.append(field)
    para(doc, data['title'], 'Title')
    heading = para(doc, '필요한 부분 찾기', 'Heading 1')
    bookmark(heading, 'contents', 1)
    para(doc, '항목을 누르면 해당 사용법으로 이동합니다. 각 단계의 설명 바로 아래 사진을 보며 따라 하세요.')
    p = doc.add_paragraph(); p.add_run('앱 열기  ').bold = True
    link = OxmlElement('w:hyperlink')
    link.set(qn('r:id'), doc.part.relate_to(data['app_url'], RT.HYPERLINK, is_external=True))
    run = OxmlElement('w:r'); props = OxmlElement('w:rPr')
    color = OxmlElement('w:color'); color.set(qn('w:val'), '2541B2'); props.append(color); run.append(props)
    txt = OxmlElement('w:t'); txt.text = data['app_url']; run.append(txt); link.append(run); p._p.append(link)
    topics = {topic['id']: topic for topic in data['topics']}
    contents_bullets = list_numbering(doc, 'bullet')
    for group in data['contents_groups']:
        p = para(doc, group['title'], 'Heading 2')
        p.paragraph_format.space_before = Pt(7); p.paragraph_format.space_after = Pt(3)
        for key in group['items']:
            p = doc.add_paragraph(); internal_link(p, topics[key]['title'], key)
            numpr = OxmlElement('w:numPr')
            level = OxmlElement('w:ilvl'); level.set(qn('w:val'), '0')
            num = OxmlElement('w:numId'); num.set(qn('w:val'), str(contents_bullets))
            numpr.extend([level, num]); p._p.get_or_add_pPr().append(numpr)
            p.paragraph_format.left_indent = Mm(5.3)
            p.paragraph_format.first_line_indent = Mm(-5.3)
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.line_spacing = Pt(17)
    p = para(doc, '사진 속 팀·이름·코드·날짜는 예시입니다. 우리 팀의 초대 코드와 일정을 사용하세요.')
    p.paragraph_format.space_before = Pt(8)
    for run in p.runs: run.font.size = Pt(9)

    for index, topic in enumerate(data['topics'], 1):
        heading = para(doc, f'{index}  {topic["title"]}', 'Heading 1')
        heading.paragraph_format.page_break_before = True
        heading.paragraph_format.space_before = Pt(0)
        bookmark(heading, topic['id'], index + 1)
        p = para(doc, topic['audience'], 'Subtitle')
        p.paragraph_format.space_after = Pt(5); p.paragraph_format.keep_with_next = True
        p = para(doc, topic['intro']); p.paragraph_format.keep_with_next = True
        if topic.get('path'):
            p = para(doc, topic['path']); p.paragraph_format.keep_with_next = True
            for run in p.runs: run.font.size = Pt(9.5)
        if topic['steps']:
            num_id = list_numbering(doc, 'decimal')
        for number, step in enumerate(topic['steps'], 1):
            p = para(doc, step['text'])
            p.paragraph_format.page_break_before = step.get('new_page', False)
            p.paragraph_format.left_indent = Mm(5.3)
            p.paragraph_format.first_line_indent = Mm(-5.3)
            p.paragraph_format.keep_with_next = True
            p.paragraph_format.space_after = Pt(4)
            numpr = OxmlElement('w:numPr')
            level = OxmlElement('w:ilvl'); level.set(qn('w:val'), '0')
            num = OxmlElement('w:numId'); num.set(qn('w:val'), str(num_id))
            numpr.extend([level, num]); p._p.get_or_add_pPr().append(numpr)
            image = ROOT / 'docs/guide/step-images' / step['image']['file']
            pic = doc.add_paragraph()
            pic.paragraph_format.left_indent = Mm(5.3)
            pic.paragraph_format.line_spacing = 1.0
            pic.paragraph_format.keep_together = True
            pic.paragraph_format.space_after = Pt(10)
            width = 104 * step['image']['crop'][2] / 412
            shape = pic.add_run().add_picture(str(image), width=Mm(width))
            shape._inline.docPr.set('descr', f'{topic["title"]} {number}단계 ' + re.sub(r'\*\*', '', step['text']))
        for section in topic['notes']:
            para(doc, section['title'], 'Heading 2')
            if 'table' in section: table(doc, section['table'])
            if 'text' in section: para(doc, section['text'])
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / 'PraiseTeam_사용가이드.docx'
    doc.save(path)
    embed_fonts(path)
    print(path)


if __name__ == '__main__':
    main()
