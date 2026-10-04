import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';

void main() {
  group('PDF Engine Benchmark Foundation', () {
    late PdfiumEngine engine;
    const multiDoc = 'test/fixtures/doc_multipage.pdf';
    const singleDoc = 'test/fixtures/doc_single_page.pdf';

    setUp(() {
      engine = PdfiumEngine();
    });

    tearDown(() {
      engine.dispose();
    });

    test('Measures real PDF inspection and open performance', () async {
      final stopwatch = Stopwatch()..start();
      final info = await engine.inspect(multiDoc);
      stopwatch.stop();

      final openTimeMs = stopwatch.elapsedMilliseconds;
      // print to test output for records
      // ignore: avoid_print
      print('[BENCHMARK] Document Inspect Time: ${openTimeMs}ms (pages: ${info.pageCount})');
      expect(openTimeMs, lessThan(500));
    });

    test('Measures first-page and cached render times', () async {
      // 1. Cold render
      final sw1 = Stopwatch()..start();
      final bytes1 = await engine.renderPage(multiDoc, 1, dpi: 150);
      sw1.stop();
      final coldRenderMs = sw1.elapsedMilliseconds;

      // 2. Warm cached render
      final sw2 = Stopwatch()..start();
      final bytes2 = await engine.renderPage(multiDoc, 1, dpi: 150);
      sw2.stop();
      final warmRenderMs = sw2.elapsedMilliseconds;

      // ignore: avoid_print
      print('[BENCHMARK] Cold Page Render: ${coldRenderMs}ms (size: ${bytes1.length} bytes)');
      // ignore: avoid_print
      print('[BENCHMARK] Warm Cached Page Render: ${warmRenderMs}ms (size: ${bytes2.length} bytes)');

      expect(bytes1, isNotEmpty);
      expect(warmRenderMs, lessThanOrEqualTo(coldRenderMs));
    });

    test('Measures text extraction and thumbnail generation times', () async {
      final swText = Stopwatch()..start();
      final blocks = await engine.extractTextBlocks(singleDoc, 1);
      swText.stop();

      final swThumb = Stopwatch()..start();
      final thumb = await engine.renderThumbnail(singleDoc, 1, size: 100);
      swThumb.stop();

      // ignore: avoid_print
      print('[BENCHMARK] Text Extraction Time: ${swText.elapsedMilliseconds}ms (${blocks.length} blocks)');
      // ignore: avoid_print
      print('[BENCHMARK] Thumbnail Generation Time: ${swThumb.elapsedMilliseconds}ms (${thumb.length} bytes)');

      expect(blocks, isNotEmpty);
      expect(thumb, isNotEmpty);
    });
  });
}
