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

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/guide'
FONT = 'Noto Sans CJK KR'
INK = '000000'


def font(style, size, bold=False):
    style.font.name = FONT
    style.font.size = Pt(size)
    style.font.bold = bold
    style.font.italic = False
    style.font.color.rgb = RGBColor.from_string(INK)
    rpr = style.element.get_or_add_rPr()
    fonts = rpr.find(qn('w:rFonts'))
    if fonts is None:
        fonts = OxmlElement('w:rFonts')
        rpr.append(fonts)
    for key in ['ascii', 'hAnsi', 'eastAsia', 'cs']:
        fonts.set(qn(f'w:{key}'), FONT)
    for key in ['asciiTheme', 'hAnsiTheme', 'eastAsiaTheme', 'cstheme']:
        fonts.attrib.pop(qn(f'w:{key}'), None)


def rich(paragraph, value):
    for index, part in enumerate(re.split(r'\*\*(.*?)\*\*', value)):
        if part:
            run = paragraph.add_run(part)
            if index % 2 == 1:
                run.bold = True
    return paragraph


def para(doc, text, style=None):
    p = doc.add_paragraph(style=style)
    rich(p, text)
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
    source = ROOT / 'docs/guide/walkthrough.ko.json'
    if not source.exists():
        source = ROOT / 'docs/guide/content.ko.json'
    data = json.loads(source.read_text())
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
        s = doc.styles[name]; font(s, size, bold=name != 'Subtitle')
        s.paragraph_format.space_before = Pt(9 if name == 'Heading 2' else 0)
        s.paragraph_format.space_after = Pt(5)
        s.paragraph_format.keep_with_next = True
        s.paragraph_format.line_spacing = Pt(size * 1.4)
        ppr = s.element.get_or_add_pPr()
        for border in list(ppr.findall(qn('w:pBdr'))): ppr.remove(border)
    doc.core_properties.title = data['title']
    doc.core_properties.subject = '찬양팀 가입과 콘티 로타 연습 라이브 사용 안내'
    doc.core_properties.author = 'PraiseTeam'
    doc.core_properties.keywords = '찬양팀, 콘티, 악보, 로타, 라이브, 사용 가이드'
    footer = sec.footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = footer.add_run(f'{data["title"]}  |  {data["updated"]}  |  ')
    run.font.size = Pt(8)
    field = OxmlElement('w:fldSimple'); field.set(qn('w:instr'), 'PAGE'); footer._p.append(field)
    for index, page in enumerate(data['pages'], 1):
        if index == 1:
            para(doc, data['title'], 'Title')
        heading = para(doc, f'{index}  {page["title"]}', 'Heading 1')
        heading.paragraph_format.page_break_before = index > 1
        p = para(doc, page['audience'], 'Subtitle'); p.paragraph_format.space_after = Pt(6)
        para(doc, page['intro'])
        if index == 1:
            p = doc.add_paragraph()
            p.add_run('앱 열기  ').bold = True
            link = OxmlElement('w:hyperlink')
            link.set(qn('r:id'), doc.part.relate_to(data['app_url'], RT.HYPERLINK, is_external=True))
            r = OxmlElement('w:r'); props = OxmlElement('w:rPr')
            color = OxmlElement('w:color'); color.set(qn('w:val'), '2541B2'); props.append(color); r.append(props)
            txt = OxmlElement('w:t'); txt.text = data['app_url']; r.append(txt); link.append(r); p._p.append(link)
        if page.get('path'):
            p = para(doc, page['path'])
            p.paragraph_format.space_after = Pt(6)
            for run in p.runs:
                run.font.size = Pt(9.5)
        if page.get('visuals'):
            p = doc.add_paragraph()
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            p.paragraph_format.line_spacing = 1.0
            p.paragraph_format.space_after = Pt(2)
            p.paragraph_format.keep_with_next = True
            p.paragraph_format.keep_together = True
            width = page.get('image_width_mm', 76)
            for j, figure in enumerate(page['visuals'], 1):
                if j > 1:
                    spacer = p.add_run('   ')
                    spacer.font.size = Pt(16)
                image = ROOT / f'docs/guide/screenshots/page-{index:02}-{j}.png'
                shape = p.add_run().add_picture(str(image), width=Mm(width))
                shape._inline.docPr.set('descr', figure['caption'])
            caption = doc.add_paragraph()
            caption.paragraph_format.line_spacing = Pt(12)
            caption.paragraph_format.space_after = Pt(4)
            caption.alignment = WD_ALIGN_PARAGRAPH.CENTER
            labels = [f'{chr(65+j)}  {figure["caption"]}' for j,figure in enumerate(page['visuals'])]
            run = caption.add_run('     |     '.join(labels)); run.font.size = Pt(8.5)
        for section in page['sections']:
            para(doc, section['title'], 'Heading 2')
            if 'steps' in section: add_list(doc, section['steps'], 'decimal')
            if 'bullets' in section: add_list(doc, section['bullets'], 'bullet')
            if 'table' in section: table(doc, section['table'])
            if 'text' in section: para(doc, section['text'])
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / 'PraiseTeam_사용가이드.docx'
    doc.save(path)
    print(path)


if __name__ == '__main__':
    main()
