import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' show PdfPageFormat;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart';

import 'models.dart';

/// A sheet ready to upload: one PDF plus its page sizes.
class PreparedSheet {
  const PreparedSheet(this.pdf, this.pageSizes);
  final Uint8List pdf;
  final List<PageSize> pageSizes;
}

/// Lets the user pick one PDF, or several photos that become one PDF
/// (one page per photo, in the order picked). Returns null if cancelled.
///
/// Every sheet is stored as PDF so the viewer and the annotation layer have
/// a single page model.
Future<PreparedSheet?> pickSheet() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
  );
  if (files.isEmpty) return null;

  final pdfs = files.where((f) => (f.extension ?? '').toLowerCase() == 'pdf').toList();
  final Uint8List pdf;
  if (pdfs.isNotEmpty) {
    pdf = await pdfs.first.readAsBytes();
  } else {
    pdf = await imagesToPdf([for (final f in files) await f.readAsBytes()]);
  }
  return PreparedSheet(pdf, await readPageSizes(pdf));
}

/// Longest side of an embedded photo; enough for reading a chart on a
/// tablet while keeping a page around a few hundred KB.
const _maxImageSide = 2000;

Future<Uint8List> imagesToPdf(List<Uint8List> images) async {
  final doc = pw.Document();
  for (final bytes in images) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) continue;
    final scaled = decoded.width >= decoded.height
        ? (decoded.width > _maxImageSide ? img.copyResize(decoded, width: _maxImageSide) : decoded)
        : (decoded.height > _maxImageSide ? img.copyResize(decoded, height: _maxImageSide) : decoded);
    final jpeg = img.encodeJpg(scaled, quality: 80);
    // Page in the photo's own aspect ratio, width of an A4 page.
    final width = PdfPageFormat.a4.width;
    final height = width * scaled.height / scaled.width;
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(width, height),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Image(pw.MemoryImage(jpeg), fit: pw.BoxFit.fill),
      ),
    );
  }
  return doc.save();
}

Future<List<PageSize>> readPageSizes(Uint8List pdf) async {
  await pdfrxFlutterInitialize();
  final document = await PdfDocument.openData(pdf);
  try {
    return [for (final page in document.pages) (width: page.width, height: page.height)];
  } finally {
    await document.dispose();
  }
}
