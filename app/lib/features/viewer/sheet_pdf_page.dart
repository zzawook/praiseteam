import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

/// Keeps the PDF alive while annotation settings and save status change.
/// pdfrx replaces its listener when documentRef identity changes; removing
/// the last listener disposes the document and clears the rendered page.
class SheetPdfPage extends StatefulWidget {
  const SheetPdfPage({
    super.key,
    required this.data,
    required this.sourceName,
    required this.pageNumber,
  });

  final Uint8List data;
  final String sourceName;
  final int pageNumber;

  @override
  State<SheetPdfPage> createState() => _SheetPdfPageState();
}

class _SheetPdfPageState extends State<SheetPdfPage> {
  late PdfDocumentRefData _documentRef = _reference();

  PdfDocumentRefData _reference() =>
      PdfDocumentRefData(widget.data, sourceName: widget.sourceName);

  @override
  void didUpdateWidget(covariant SheetPdfPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data) ||
        oldWidget.sourceName != widget.sourceName) {
      _documentRef = _reference();
    }
  }

  @override
  Widget build(BuildContext context) => PdfDocumentViewBuilder(
    documentRef: _documentRef,
    builder: (context, document) => PdfPageView(
      document: document,
      pageNumber: widget.pageNumber,
      backgroundColor: Colors.white,
    ),
  );
}
