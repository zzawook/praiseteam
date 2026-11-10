"""Verify screenshot placement and real Word/PDF navigation destinations."""
import json
import re
from pathlib import Path
from zipfile import ZipFile

import pdfplumber
from lxml import etree
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / 'docs/guide/steps.ko.json').read_text())
DOCX = ROOT / 'output/guide/PraiseTeam_사용가이드.docx'
PDF = ROOT / 'output/guide/qa-stepwise/PraiseTeam_사용가이드.pdf'
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
      'wp': 'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing'}


def main():
    with ZipFile(DOCX) as archive:
        document = etree.fromstring(archive.read('word/document.xml'))
        footer = etree.fromstring(archive.read('word/footer1.xml'))
    names = set(document.xpath('//w:bookmarkStart/@w:name', namespaces=NS))
    links = document.xpath('//w:hyperlink/@w:anchor', namespaces=NS) + footer.xpath('//w:hyperlink/@w:anchor', namespaces=NS)
    assert links and all(name in names for name in links), 'Every Word link must resolve'
    numbered = document.xpath('//w:body/w:p[w:pPr/w:numPr]', namespaces=NS)
    count = sum(len(topic['steps']) for topic in DATA['topics'])
    assert len(numbered) == count
    for p in numbered:
        image = p.getnext()
        assert image is not None and len(image.xpath('.//wp:inline', namespaces=NS)) == 1, 'Each step must be immediately followed by one screenshot'
        assert p.xpath('./w:pPr/w:keepNext', namespaces=NS), 'Keep instruction and screenshot together'
    assert len(document.xpath('//wp:inline', namespaces=NS)) == count

    reader = PdfReader(PDF)
    pages = {page.indirect_reference.idnum: i for i, page in enumerate(reader.pages)}
    def destination(annotation):
        return annotation.get('/Dest') or annotation.get('/A', {}).get('/D')
    def target(annotation):
        d = destination(annotation)
        assert isinstance(d, list) and len(d) >= 4
        return pages[d[0].idnum], float(d[3])
    toc = [a.get_object() for a in reader.pages[0].get('/Annots', [])]
    toc = sorted([a for a in toc if destination(a) and float(a['/Rect'][1]) > 60], key=lambda a: float(a['/Rect'][3]), reverse=True)
    keys = [key for group in DATA['contents_groups'] for key in group['items']]
    topics = {topic['id']: topic for topic in DATA['topics']}
    assert len(toc) == len(keys) == len(topics)
    report = []
    with pdfplumber.open(PDF) as rendered:
        # Check the exported layout, not just the Word XML: the full instruction
        # must occur on the same page immediately above its screenshot.
        expected_steps = iter(step for topic in DATA['topics'] for step in topic['steps'])
        def normalized(value):
            value = re.sub(r'\[\[[a-z_0-9]+\|([^\]]+)\]\]', r'\1', value)
            return re.sub(r'[\W_]+', '', value).casefold()
        seen = 0
        for page in rendered.pages:
            previous_bottom = 0
            for image in sorted(page.images, key=lambda item: item['top']):
                step = next(expected_steps)
                above = page.crop((0, previous_bottom, page.width, image['top'])).extract_text() or ''
                assert normalized(step['text']) in normalized(above), f'Instruction separated from screenshot: {step["text"]}'
                previous_bottom = image['bottom']
                seen += 1
        assert seen == count
        assert next(expected_steps, None) is None
        first = rendered.pages[0]
        for annotation, key in zip(toc, keys):
            x0, y0, x1, y1 = map(float, annotation['/Rect'])
            label = first.crop((x0, first.height-y1, x1, first.height-y0)).extract_text() or ''
            wanted = topics[key]['title']
            assert ''.join(label.split()) == ''.join(wanted.split()), (key, label)
            page_number, top = target(annotation)
            hits = rendered.pages[page_number].search(re.escape(wanted))
            assert hits, (key, page_number)
            assert min(abs(top - (rendered.pages[page_number].height-hit['top'])) for hit in hits) < 35, 'Link must land on its heading, not merely somewhere on its page'
            report.append({'topic': key, 'label': wanted, 'pdf_page': page_number+1})
        for i, page in enumerate(reader.pages):
            internal = [a.get_object() for a in page.get('/Annots', []) if destination(a.get_object())]
            assert all(0 <= target(a)[0] < len(reader.pages) for a in internal)
            back = [a for a in internal if float(a['/Rect'][3]) < 65]
            assert len(back) == 1 and target(back[0])[0] == 0, f'Page {i+1} must link back to the contents'
    text = '\n'.join(page.extract_text() for page in reader.pages)
    assert '[[' not in text
    assert not re.search(r'\d+\s*[~–-]?\s*\d*쪽', text), 'Use links instead of stale page references'
    output = {'pages': len(reader.pages), 'steps_with_immediate_screenshots': count,
              'word_links_resolved': len(links), 'toc_destinations': report,
              'back_links': len(reader.pages)}
    (ROOT/'output/guide/stepwise-verification.json').write_text(json.dumps(output, ensure_ascii=False, indent=2)+'\n')
    print(f'PASS: {count} steps each immediately followed by a screenshot; {len(toc)} contents links reach their headings; {len(reader.pages)} return links work.')


if __name__ == '__main__':
    main()
