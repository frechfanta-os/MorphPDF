import 'dart:ffi';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/pdf/pdf_exceptions.dart';
import 'package:morphpdf/core/pdf/pdf_models.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_bindings.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 4: Real Native PDFium FFI Execution Tests', () {
    late PdfiumBindings bindings;
    late PdfiumEngine nativeEngine;
    final bool nativeLibraryPresent = File('/tmp/libpdfium.so').existsSync();

    setUpAll(() {
      if (nativeLibraryPresent) {
        final lib = DynamicLibrary.open('/tmp/libpdfium.so');
        bindings = PdfiumBindings(lib);
        bindings.initLibrary(nullptr);
      }
    });

    setUp(() {
      if (nativeLibraryPresent) {
        nativeEngine = PdfiumEngine(bindings: bindings);
      }
    });

    tearDown(() {
      if (nativeLibraryPresent) {
        nativeEngine.dispose();
      }
    });

    tearDownAll(() {
      if (nativeLibraryPresent) {
        bindings.destroyLibrary();
      }
    });

    test('Native Library Load Verification', () {
      expect(nativeLibraryPresent, isTrue, reason: '/tmp/libpdfium.so must exist for native FFI tests');
      expect(nativeEngine.isNative, isTrue);
      expect(nativeEngine.executionEngine, PdfEngineType.nativePdfium);
    });

    test('Category A: Textual PDF real native inspection and extraction', () async {
      const pdfPath = 'test/fixtures/doc_french.pdf';
      final inspection = await nativeEngine.inspect(pdfPath);

      // Verify native inspection
      expect(inspection.executionEngine, PdfEngineType.nativePdfium);
      expect(inspection.pageCount, 2);
      expect(inspection.defaultWidth, 595.0);
      expect(inspection.defaultHeight, 842.0);

      // Verify native text extraction
      final blocks = await nativeEngine.extractTextBlocks(pdfPath, 1);
      expect(blocks, isNotEmpty);
      expect(blocks.first.text, contains('MorphPDF'));

      // Verify coordinate sanity
      for (final b in blocks) {
        expect(b.x, greaterThanOrEqualTo(0.0));
        expect(b.y, greaterThanOrEqualTo(0.0));
        expect(b.width, greaterThan(0.0));
        expect(b.height, greaterThan(0.0));
      }
    });

    test('Category B: Scanned / Raster PDF native detection & bitmap rendering', () async {
      // Create empty PDF without text operators
      final tempDir = Directory.systemTemp;
      final scannedPdf = File('${tempDir.path}/scanned_no_text.pdf');
      await scannedPdf.writeAsString(
        '%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'
        '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'
        '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R >>\nendobj\n'
        '4 0 obj\n<< /Length 0 >>\nstream\nendstream\nendobj\n'
        'xref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n'
        '0000000115 00000 n \n0000000206 00000 n \n'
        'trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n256\n%%EOF\n',
      );

      try {
        final inspection = await nativeEngine.inspect(scannedPdf.path);
        expect(inspection.pageCount, 1);

        // Native extraction yields 0 blocks (absence of text detected)
        final blocks = await nativeEngine.extractTextBlocks(scannedPdf.path, 1);
        expect(blocks, isEmpty, reason: 'Scanned page must yield 0 text blocks from PDFium');

        // Render page with native PDFium rasterizer (FPDF_RenderPageBitmap)
        final renderedBmp = await nativeEngine.renderPage(scannedPdf.path, 1, dpi: 72);
        expect(renderedBmp, isNotEmpty);
        expect(renderedBmp.length, greaterThan(1000));
        // Verify BMP magic header 'BM' (0x42, 0x4D)
        expect(renderedBmp[0], 0x42);
        expect(renderedBmp[1], 0x4D);
      } finally {
        if (await scannedPdf.exists()) await scannedPdf.delete();
      }
    });

    test('Category C: Multipage PDF real page order and counts', () async {
      const multipagePdf = 'test/fixtures/doc_multipage.pdf';
      final inspection = await nativeEngine.inspect(multipagePdf);
      expect(inspection.pageCount, 3);

      final pages = await nativeEngine.getPages(multipagePdf);
      expect(pages.length, 3);
      expect(pages[0].pageNumber, 1);
      expect(pages[1].pageNumber, 2);
      expect(pages[2].pageNumber, 3);

      final page1Blocks = await nativeEngine.extractTextBlocks(multipagePdf, 1);
      final page2Blocks = await nativeEngine.extractTextBlocks(multipagePdf, 2);
      final page3Blocks = await nativeEngine.extractTextBlocks(multipagePdf, 3);

      expect(page1Blocks, isNotEmpty);
      expect(page2Blocks, isNotEmpty);
      expect(page3Blocks, isNotEmpty);

      // Verify no cross-page block duplication
      final text1 = page1Blocks.map((b) => b.text).join(' ');
      final text2 = page2Blocks.map((b) => b.text).join(' ');
      expect(text1, isNot(equals(text2)));
    });

    test('Error Handling: Empty and Invalid PDFs', () async {
      final tempDir = Directory.systemTemp;
      final emptyFile = File('${tempDir.path}/zero_byte.pdf');
      await emptyFile.writeAsBytes([]);

      try {
        await expectLater(
          () => nativeEngine.inspect(emptyFile.path),
          throwsA(isA<PdfInvalidDocumentException>()),
        );
      } finally {
        if (await emptyFile.exists()) await emptyFile.delete();
      }
    });
  });
}
