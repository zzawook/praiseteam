"""Verify embedded fonts, consistent linked styles, and actual PDF colors."""
import argparse
import hashlib
import json
import re
from pathlib import Path
from zipfile import ZipFile

import pdfplumber
from lxml import etree

from build_user_guide import FONT, STYLE_COLORS
from embed_guide_fonts import obfuscate, W, R, PKG

ROOT = Path(__file__).resolve().parents[1]
NS = {'w': W, 'r': R}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--docx', type=Path, default=ROOT/'output/guide/PraiseTeam_사용가이드.docx')
    parser.add_argument('--pdf', type=Path, default=ROOT/'output/guide/qa-typography/PraiseTeam_사용가이드.pdf')
    args = parser.parse_args()
    with ZipFile(args.docx) as archive:
        styles = etree.fromstring(archive.read('word/styles.xml'))
        document = etree.fromstring(archive.read('word/document.xml'))
        table = etree.fromstring(archive.read('word/fontTable.xml'))
        rels = etree.fromstring(archive.read('word/_rels/fontTable.xml.rels'))
        entry = table.xpath('./w:font[@w:name=$name]', namespaces=NS, name=FONT)[0]
        for face in ['Regular', 'Bold']:
            embedded = entry.find(f'{{{W}}}embed{face}')
            assert embedded is not None
            rid = embedded.get(f'{{{R}}}id')
            relationship = rels.xpath('./p:Relationship[@Id=$id]', namespaces={'p': PKG}, id=rid)[0]
            data = archive.read('word/'+relationship.get('Target'))
            original = (ROOT/f'docs/guide/fonts/NotoSansKR-{face}.otf').read_bytes()
            assert obfuscate(data, embedded.get(f'{{{W}}}fontKey')) == original
            assert embedded.get(f'{{{W}}}subsetted') == 'false'
        for name, expected in STYLE_COLORS.items():
            style_id = name.replace(' ', '')
            paragraph = styles.xpath('//w:style[@w:styleId=$id]', namespaces=NS, id=style_id)[0]
            linked_id = paragraph.find('w:link', NS).get(f'{{{W}}}val')
            linked = styles.xpath('//w:style[@w:styleId=$id]', namespaces=NS, id=linked_id)[0]
            for style in [paragraph, linked]:
                rpr = style.find('w:rPr', NS)
                color = rpr.find('w:color', NS)
                assert color.attrib == {f'{{{W}}}val': expected}, (style_id, color.attrib)
                fonts = rpr.find('w:rFonts', NS)
                assert all(fonts.get(f'{{{W}}}{key}') == FONT for key in ['ascii','hAnsi','eastAsia','cs'])
                assert not any(key.lower().endswith('theme') for key in fonts.attrib)
                assert rpr.find('w:sz', NS).get(f'{{{W}}}val') == rpr.find('w:szCs', NS).get(f'{{{W}}}val')
            assert paragraph.find('w:rPr/w:sz', NS).get(f'{{{W}}}val') == linked.find('w:rPr/w:sz', NS).get(f'{{{W}}}val')
    wanted = []
    for p in document.xpath('//w:body/w:p', namespaces=NS):
        values = p.xpath('./w:pPr/w:pStyle/@w:val', namespaces=NS)
        if not values:
            continue
        name = {'Title':'Title','Heading1':'Heading 1','Heading2':'Heading 2'}.get(values[0])
        if name:
            text = ''.join(p.xpath('.//w:t/text()', namespaces=NS))
            wanted.append((text, STYLE_COLORS[name]))
    seen = []
    with pdfplumber.open(args.pdf) as pdf:
        for text, color in wanted:
            expected = tuple(int(color[i:i+2],16)/255 for i in [0,2,4])
            found = []
            for i,page in enumerate(pdf.pages):
                pattern = r'\s+'.join(re.escape(word) for word in text.split())
                for hit in page.search(pattern):
                    chars = [c for c in hit['chars'] if c['text'].strip()]
                    if chars and all(isinstance(c.get('non_stroking_color'),tuple) and
                                     len(c['non_stroking_color'])==3 and
                                     all(abs(a-b)<.005 for a,b in zip(c['non_stroking_color'],expected))
                                     for c in chars):
                        found.append(i+1)
            assert found, f'Heading does not have its requested blue color in the PDF: {text}'
            seen.append({'heading': text, 'color': color, 'pages': found})
        letter_fonts = {c['fontname'].split('+')[-1] for p in pdf.pages for c in p.chars
                        if re.search(r'[가-힣A-Za-z0-9]', c['text'])}
        assert letter_fonts and all(name.startswith('NotoSansKR-') for name in letter_fonts), letter_fonts
    report = {'embedded_faces': ['Regular','Bold'], 'fonts': sorted(letter_fonts),
              'blue_headings': seen, 'pdf_sha256': hashlib.sha256(args.pdf.read_bytes()).hexdigest()}
    (ROOT/'output/guide/typography-verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(f'PASS: two full embedded faces; matching paragraph/character styles; {len(seen)} blue headings; PDF text uses Noto Sans KR.')


if __name__ == '__main__':
    main()
