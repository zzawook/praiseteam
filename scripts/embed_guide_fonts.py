"""Embed the guide's full OpenType faces using ECMA-376 font obfuscation.

The original licensed font bytes are retained (no glyph subsetting), so Korean
text added while editing can use the same embedded font.
"""
import hashlib
import struct
import uuid
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

from lxml import etree

ROOT = Path(__file__).resolve().parents[1]
W = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'
R = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
PKG = 'http://schemas.openxmlformats.org/package/2006/relationships'
CT = 'http://schemas.openxmlformats.org/package/2006/content-types'
FONT = 'Noto Sans KR'


def obfuscate(data, key):
    key_bytes = uuid.UUID(key.strip('{}')).bytes[::-1]
    result = bytearray(data)
    for i in range(32):
        result[i] ^= key_bytes[i % 16]
    return bytes(result)


def embed_fonts(docx):
    with ZipFile(docx) as source:
        files = {name: source.read(name) for name in source.namelist()}
    table = etree.fromstring(files['word/fontTable.xml'])
    entries = table.xpath('./w:font[@w:name="Noto Sans KR"]', namespaces={'w': W})
    entry = entries[0] if entries else etree.SubElement(table, f'{{{W}}}font', {f'{{{W}}}name': FONT})
    rel_path = 'word/_rels/fontTable.xml.rels'
    rels = etree.fromstring(files[rel_path]) if rel_path in files else etree.Element(f'{{{PKG}}}Relationships', nsmap={None: PKG})
    types = etree.fromstring(files['[Content_Types].xml'])
    if not types.xpath('./c:Default[@Extension="odttf"]', namespaces={'c': CT}):
        etree.SubElement(types, f'{{{CT}}}Default', Extension='odttf', ContentType='application/vnd.openxmlformats-officedocument.obfuscatedFont')
    for face in ['Regular', 'Bold']:
        data = (ROOT / f'docs/guide/fonts/NotoSansKR-{face}.otf').read_bytes()
        assert data[:4] == b'OTTO', 'Expected a standalone OpenType face'
        records = [struct.unpack_from('>4sIII', data, 12+i*16) for i in range(struct.unpack_from('>H', data, 4)[0])]
        os2 = next(offset for tag, checksum, offset, length in records if tag == b'OS/2')
        assert struct.unpack_from('>H', data, os2+8)[0] == 0, 'Use fonts that allow unrestricted embedding'
        key = '{' + str(uuid.uuid5(uuid.NAMESPACE_URL, hashlib.sha256(data).hexdigest())).upper() + '}'
        filename = f'NotoSansKR-{face}.odttf'
        relation = f'rIdGuideFont{face}'
        for old in entry.findall(f'{{{W}}}embed{face}'):
            entry.remove(old)
        etree.SubElement(entry, f'{{{W}}}embed{face}', {f'{{{R}}}id': relation, f'{{{W}}}fontKey': key, f'{{{W}}}subsetted': 'false'})
        for old in rels.xpath('./p:Relationship[@Id=$id]', namespaces={'p': PKG}, id=relation):
            rels.remove(old)
        etree.SubElement(rels, f'{{{PKG}}}Relationship', Id=relation, Type=R+'/font', Target='fonts/'+filename)
        embedded = obfuscate(data, key)
        assert obfuscate(embedded, key) == data
        files['word/fonts/'+filename] = embedded
    settings = etree.fromstring(files['word/settings.xml'])
    for name, value in [('embedTrueTypeFonts', 'true'), ('embedSystemFonts', 'true'), ('saveSubsetFonts', 'false')]:
        element = settings.find(f'{{{W}}}{name}')
        if element is None:
            element = etree.Element(f'{{{W}}}{name}')
            # These settings precede defaultTabStop in the Word settings schema.
            anchor = settings.find(f'{{{W}}}defaultTabStop')
            settings.insert(settings.index(anchor) if anchor is not None else 0, element)
        element.set(f'{{{W}}}val', value)
    for name, element in [('word/fontTable.xml', table), (rel_path, rels), ('[Content_Types].xml', types), ('word/settings.xml', settings)]:
        files[name] = etree.tostring(element, xml_declaration=True, encoding='UTF-8', standalone=True)
    temporary = docx.with_suffix('.embedded.docx')
    with ZipFile(temporary, 'w', ZIP_DEFLATED, compresslevel=9) as output:
        for name, data in files.items():
            output.writestr(name, data)
    temporary.replace(docx)


if __name__ == '__main__':
    import sys
    embed_fonts(Path(sys.argv[1]))
