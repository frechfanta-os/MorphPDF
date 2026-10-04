import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';
import 'package:morphpdf/features/ocr/data/paddle_ocr_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaddleOcrEngine Tests', () {
    test('Engine metadata and languages', () {
      final engine = PaddleOcrEngine();
      expect(engine.engineName, contains('PaddleOCR'));
      expect(engine.supportedLanguages, contains('ar'));
      expect(engine.supportedLanguages, contains('en'));
    });

    test('Cancellation token throws OcrCancelledException immediately', () async {
      final engine = PaddleOcrEngine();
      final token = OcrCancellationToken()..cancel();

      expect(
        () => engine.recognizePage(
          imagePath: '/dummy/page.png',
          pageIndex: 1,
          cancellationToken: token,
        ),
        throwsA(isA<OcrCancelledException>()),
      );
    });

    test('Headless fallback execution outside Android host', () async {
      final engine = PaddleOcrEngine();

      final result = await engine.recognizePage(
        imagePath: '/dummy/document.png',
        pageIndex: 1,
      );

      expect(result.pageIndex, 1);
      expect(result.blocks, isNotEmpty);
      expect(result.engineUsed, contains('PaddleOCR'));
    });

    test('recognizeText backward compatibility', () async {
      final engine = PaddleOcrEngine();

      final textBlocks = await engine.recognizeText('/dummy/document.png', lang: 'en');
      expect(textBlocks, isNotEmpty);
      expect(textBlocks.first.pageNumber, 1);
    });
  });
}
