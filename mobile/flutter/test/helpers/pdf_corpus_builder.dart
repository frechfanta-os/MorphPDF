import 'dart:convert';
import 'dart:io';

/// Builder to create minimal, valid, deterministic PDF-1.4 files for the Phase 5.3 corpus.
class PdfCorpusBuilder {
  /// A page definition containing text items with coordinates, font size, and optional custom dimensions.
  static String buildPdf({
    required List<List<PdfTextItem>> pages,
    double width = 595.0,
    double height = 842.0,
  }) {
    final buffer = StringBuffer();
    final offsets = <int>[];

    void write(String s) {
      buffer.write(s);
    }

    int getOffset() => utf8.encode(buffer.toString()).length;

    write('%PDF-1.4\n%\xE2\xE3\xCF\xD3\n');

    // 1 0 obj: Catalog
    offsets.add(getOffset());
    write('1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n');

    // 2 0 obj: Pages
    offsets.add(getOffset());
    final pageCount = pages.length;
    final kids = List.generate(pageCount, (i) => '${5 + i * 2} 0 R').join(' ');
    write('2 0 obj\n<< /Type /Pages /Kids [$kids] /Count $pageCount >>\nendobj\n');

    // 3 0 obj: Font
    offsets.add(getOffset());
    write('3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n');

    // 4 0 obj: ProcSet
    offsets.add(getOffset());
    write('4 0 obj\n[ /PDF /Text /ImageC ]\nendobj\n');

    // Page objects & Content streams
    for (int i = 0; i < pageCount; i++) {
      final pageObjNum = 5 + i * 2;
      final contentObjNum = pageObjNum + 1;
      final items = pages[i];

      // Build content stream
      final streamBuf = StringBuffer();
      streamBuf.write('BT\n');
      for (final item in items) {
        streamBuf.write('/F1 ${item.fontSize} Tf\n');
        streamBuf.write('${item.x} ${item.y} Td\n');
        // Escape parentheses in PDF string literal
        final escaped = item.text.replaceAll('\\', '\\\\').replaceAll('(', '\\(').replaceAll(')', '\\)');
        streamBuf.write('($escaped) Tj\n');
      }
      streamBuf.write('ET\n');
      final streamBytes = utf8.encode(streamBuf.toString());

      // Page obj
      offsets.add(getOffset());
      write('$pageObjNum 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${width.toInt()} ${height.toInt()}] /Resources << /Font << /F1 3 0 R >> /ProcSet 4 0 R >> /Contents $contentObjNum 0 R >>\nendobj\n');

      // Content stream obj
      offsets.add(getOffset());
      write('$contentObjNum 0 obj\n<< /Length ${streamBytes.length} >>\nstream\n');
      write(streamBuf.toString());
      write('endstream\nendobj\n');
    }

    // xref table
    final xrefOffset = getOffset();
    final totalObjects = 5 + pageCount * 2;
    write('xref\n0 $totalObjects\n');
    write('0000000000 65535 f \n');
    for (final off in offsets) {
      write('${off.toString().padLeft(10, '0')} 00000 n \n');
    }

    // trailer
    write('trailer\n<< /Size $totalObjects /Root 1 0 R >>\n');
    write('startxref\n$xrefOffset\n%%EOF\n');

    return buffer.toString();
  }

  /// Writes the generated PDF to the specified output file path.
  static Future<File> writePdfFile(String filePath, String pdfContent) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    final bytes = utf8.encode(pdfContent);
    return file.writeAsBytes(bytes, flush: true);
  }
}

/// A text item to render in the PDF stream.
class PdfTextItem {
  final String text;
  final double x;
  final double y;
  final double fontSize;

  const PdfTextItem({
    required this.text,
    required this.x,
    required this.y,
    this.fontSize = 12.0,
  });
}
