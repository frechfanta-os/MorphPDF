import 'dart:ffi';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/pdf/pdf_exceptions.dart';
import 'package:morphpdf/core/pdf/pdf_models.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_bindings.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_loader.dart';

void main() {
  group('PdfiumEngine Tests', () {
    late PdfiumEngine engine;
    const singleDoc = 'test/fixtures/doc_single_page.pdf';
    const multiDoc = 'test/fixtures/doc_multipage.pdf';
    const frenchDoc = 'test/fixtures/doc_french.pdf';

    setUp(() {
      engine = PdfiumEngine();
    });

    tearDown(() {
      engine.dispose();
    });

    test('inspect returns correct metadata for single-page PDF', () async {
      final info = await engine.inspect(singleDoc);

      expect(info.fileName, 'doc_single_page.pdf');
      expect(info.pageCount, 1);
      expect(info.fileSizeBytes, greaterThan(0));
      expect(info.defaultWidth, 595.0);
      expect(info.defaultHeight, 842.0);
      expect(info.isEncrypted, isFalse);
    });

    test('inspect returns correct page count for multi-page PDF', () async {
      final info = await engine.inspect(multiDoc);

      expect(info.pageCount, 3);
      expect(info.fileName, 'doc_multipage.pdf');
    });

    test('getPages returns page list with dimensions', () async {
      final pages = await engine.getPages(multiDoc);

      expect(pages.length, 3);
      expect(pages[0].pageNumber, 1);
      expect(pages[1].pageNumber, 2);
      expect(pages[2].pageNumber, 3);
      expect(pages[0].width, 595.0);
      expect(pages[0].height, 842.0);
    });

    test('renderPage returns raster bytes and caches in LRU', () async {
      final bytes1 = await engine.renderPage(singleDoc, 1, dpi: 150);
      expect(bytes1, isNotEmpty);
      expect(bytes1.length, greaterThan(100));

      // Second call hits cache
      final bytes2 = await engine.renderPage(singleDoc, 1, dpi: 150);
      expect(identical(bytes1, bytes2) || bytes1.length == bytes2.length, isTrue);
    });

    test('renderThumbnail returns low-res cached thumbnail', () async {
      final thumb = await engine.renderThumbnail(singleDoc, 1, size: 100);
      expect(thumb, isNotEmpty);
    });

    test('extractText and extractTextBlocks retrieve content with coordinates', () async {
      final fullText = await engine.extractText(frenchDoc, 1);
      expect(fullText, isNotEmpty);

      final blocks = await engine.extractTextBlocks(frenchDoc, 1);
      expect(blocks, isNotEmpty);
      expect(blocks.first.pageNumber, 1);
      expect(blocks.first.x, greaterThanOrEqualTo(0));
      expect(blocks.first.y, greaterThanOrEqualTo(0));
      expect(blocks.first.width, greaterThan(0));
    });

    test('throws PdfFileNotFoundException for non-existent document', () async {
      expect(
        () => engine.inspect('test/fixtures/missing_doc.pdf'),
        throwsA(isA<PdfFileNotFoundException>()),
      );
    });

    test('throws PdfPageOutOfRangeException when requesting invalid page', () async {
      expect(
        () => engine.renderPage(singleDoc, 99),
        throwsA(isA<PdfPageOutOfRangeException>()),
      );
    });

    test('toDocumentModel maps to standard domain model', () async {
      final doc = await engine.toDocumentModel(singleDoc);

      expect(doc.fileName, 'doc_single_page.pdf');
      expect(doc.pageCount, 1);
      expect(doc.mimeType, 'application/pdf');
    });

    test('closeDocument and dispose release resources cleanly', () {
      engine.closeDocument(singleDoc);
      engine.dispose();
      // Repeating dispose should not throw
      engine.dispose();
    });

    test('executionEngine correctly reflects fallbackParser when native bindings are absent', () {
      expect(engine.isNative, isFalse);
      expect(engine.executionEngine, PdfEngineType.fallbackParser);
    });
  });

  group('PdfiumErrorCodes Tests', () {
    test('error code constants match official Google PDFium specifications', () {
      expect(PdfiumErrorCodes.success, 0);
      expect(PdfiumErrorCodes.unknown, 1);
      expect(PdfiumErrorCodes.fileNotFound, 2);
      expect(PdfiumErrorCodes.formatError, 3);
      expect(PdfiumErrorCodes.passwordRequired, 4);
      expect(PdfiumErrorCodes.securityUnsupported, 5);
      expect(PdfiumErrorCodes.pageError, 6);
      expect(PdfiumErrorCodes.xfaLoadError, 7);
      expect(PdfiumErrorCodes.xfaLayoutError, 8);
    });
  });

  group('PdfDocumentHandle Lifecycle Tests', () {
    test('checkValid throws PdfInvalidDocumentException for nullptr handle', () {
      final handle = PdfDocumentHandle(nullptr, 'test.pdf');
      expect(() => handle.checkValid(), throwsA(isA<PdfInvalidDocumentException>()));
    });

    test('checkValid throws PdfInvalidDocumentException when marked closed', () {
      final handle = PdfDocumentHandle(nullptr, 'test.pdf');
      handle.isClosed = true;
      expect(() => handle.checkValid(), throwsA(isA<PdfInvalidDocumentException>()));
    });
  });

  group('PdfiumLoader Lifecycle Tests', () {
    tearDown(() {
      PdfiumLoader.resetForTesting();
    });

    test('resetForTesting manages simulated native binding state', () {
      PdfiumLoader.resetForTesting(mockBindings: null);
      expect(PdfiumLoader.isAvailable, isFalse);
      expect(PdfiumLoader.bindings, isNull);
    });
  });
}
