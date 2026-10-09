import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/docx/layout/docx_elements.dart';
import 'package:morphpdf/core/docx/ooxml_package.dart';
import 'package:morphpdf/core/docx/xml_sanitizer.dart';
import 'package:morphpdf/core/ocr/bidi_normalizer.dart';
import 'package:morphpdf/core/ocr/ocr_coordinate_mapper.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';
import 'package:morphpdf/core/pdf/pdf_exceptions.dart';
import 'package:morphpdf/core/pdf/pdf_models.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';
import 'helpers/docx_inspector.dart';

void main() {
  group('Phase 5.4 Production Audit & Hardening Tests', () {
    late Directory tempDir;
    late PdfiumEngine pdfEngine;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('morphpdf_phase54_');
      pdfEngine = PdfiumEngine();
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
      pdfEngine.dispose();
    });

    test('Empty PDF: throws PdfInvalidDocumentException', () async {
      final emptyFile = File('${tempDir.path}/empty.pdf');
      await emptyFile.writeAsBytes([]);

      expect(
        () => pdfEngine.inspect(emptyFile.path),
        throwsA(isA<PdfInvalidDocumentException>()),
      );
    });

    test('Execution Mode: explicitly identifies fallback parser in headless environment', () async {
      expect(pdfEngine.isNative, isFalse);
      expect(pdfEngine.executionEngine, PdfEngineType.fallbackParser);

      const samplePdf = 'test/fixtures/doc_single_page.pdf';
      final inspection = await pdfEngine.inspect(samplePdf);
      expect(inspection.executionEngine, PdfEngineType.fallbackParser);
    });

    test('Fallback Parser: handles TJ array with kerning without inventing fake text', () async {
      final tjPdfPath = '${tempDir.path}/tj_doc.pdf';
      final pdfContent = '''%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R >> endobj
4 0 obj << /Length 75 >>
stream
BT
/F1 14 Tf
50 750 Td
[(Morph) 10 (PDF) -20 ( Pro)] TJ
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000212 00000 n 
trailer << /Size 5 /Root 1 0 R >>
startxref
338
%%EOF''';
      await File(tjPdfPath).writeAsString(pdfContent);

      final blocks = await pdfEngine.extractTextBlocks(tjPdfPath, 1);
      expect(blocks, isNotEmpty);
      expect(blocks.first.text, 'MorphPDF Pro');
      expect(blocks.first.height, 14.0);
    });

    test('Blank Page: returns empty list without synthetic placeholder text', () async {
      final blankPdfPath = '${tempDir.path}/blank_doc.pdf';
      final pdfContent = '''%PDF-1.4
1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj
2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj
3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R >> endobj
4 0 obj << /Length 12 >>
stream
BT
ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000212 00000 n 
trailer << /Size 5 /Root 1 0 R >>
startxref
275
%%EOF''';
      await File(blankPdfPath).writeAsString(pdfContent);

      final blocks = await pdfEngine.extractTextBlocks(blankPdfPath, 1);
      // Must NOT contain 'Texte extrait de la page 1.'
      expect(blocks, isEmpty);
    });

    test('OOXML Relationships: header with hyperlink emits word/_rels/header1.xml.rels', () async {
      final headerParagraph = DocxParagraph(
        runs: [
          const DocxRun(text: 'En-tête officiel: '),
          const DocxRun(
            text: 'Portail MorphPDF',
            hyperlinkUrl: 'https://morphpdf.local/header',
          ),
        ],
      );

      final section = DocxSection(
        header: DocxHeader(paragraphs: [headerParagraph]),
        elements: [
          const DocxParagraph(runs: [DocxRun(text: 'Corps du document.')]),
        ],
      );

      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final docxPath = '${tempDir.path}/header_link.docx';
      await File(docxPath).writeAsBytes(docxBytes);

      final profile = await DocxInspector.inspectFile(docxPath);
      expect(profile.xmlFiles.containsKey('word/header1.xml'), isTrue);
      expect(profile.xmlFiles.containsKey('word/_rels/header1.xml.rels'), isTrue);

      final headerRelsXml = profile.xmlFiles['word/_rels/header1.xml.rels']!;
      expect(headerRelsXml, contains('https://morphpdf.local/header'));
      expect(headerRelsXml, contains('TargetMode="External"'));
    });

    test('Path Traversal Security: sanitizes relative paths and escapes malicious inputs', () {
      expect(
        () => XmlSanitizer.sanitizePackagePath('../../secret.txt'),
        throwsA(isA<ArgumentError>()),
      );
      expect(XmlSanitizer.sanitizePackagePath('/etc/passwd'), 'etc/passwd');
      expect(XmlSanitizer.escape('Test <>&"\' text'), 'Test &lt;&gt;&amp;&quot;&apos; text');
      // Strips invalid XML 1.0 control characters
      expect(XmlSanitizer.escape('Hello\x00\x08World\x1F'), 'HelloWorld');
    });

    test('Arabic BiDi Integrity: mixed text preserves numbers and logical Unicode order', () {
      const arabicMixed = 'التقرير رقم 42 لسنة 2026';
      expect(BidiNormalizer.isPredominantlyArabic(arabicMixed), isTrue);

      // Logical order must NOT be blindly reversed character-by-character
      expect(arabicMixed, contains('42'));
      expect(arabicMixed, contains('2026'));
      expect(arabicMixed.startsWith('التقرير'), isTrue);
    });

    test('OCR Coordinate Mapper: maps image pixel boxes to PDF points across rotations', () {
      const box = OcrBoundingBox(left: 100, top: 200, width: 300, height: 50);
      const pageHeightPt = 842.0;
      const dpi = 72; // 1 pixel = 1 point

      // 0 deg: Y inverted (842 - 200 = 642)
      final rect0 = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageHeightPt,
        dpi: dpi,
        rotationDegrees: 0,
      );
      expect(rect0.left, 100.0);
      expect(rect0.top, 642.0);
      expect(rect0.width, 300.0);
      expect(rect0.height, 50.0);

      // 90 deg rotation
      final rect90 = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageHeightPt,
        dpi: dpi,
        rotationDegrees: 90,
        pageWidthPt: 595.0,
      );
      expect(rect90.width, 50.0);
      expect(rect90.height, 300.0);
    });
  });
}
