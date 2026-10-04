import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';

void main() {
  group('OCR Models, Enums & Typed Exceptions Tests', () {
    test('OcrMode enumeration values', () {
      expect(OcrMode.values, contains(OcrMode.auto));
      expect(OcrMode.values, contains(OcrMode.arabic));
      expect(OcrMode.values, contains(OcrMode.latin));
      expect(OcrMode.values.length, 3);
    });

    test('OcrBoundingBox serialization and properties', () {
      const box = OcrBoundingBox(
        left: 10.0,
        top: 20.0,
        width: 100.0,
        height: 50.0,
        polygonPoints: [
          [10.0, 20.0],
          [110.0, 20.0],
          [110.0, 70.0],
          [10.0, 70.0],
        ],
      );

      expect(box.right, 110.0);
      expect(box.bottom, 70.0);

      final json = box.toJson();
      final fromJson = OcrBoundingBox.fromJson(json);

      expect(fromJson.left, 10.0);
      expect(fromJson.top, 20.0);
      expect(fromJson.width, 100.0);
      expect(fromJson.height, 50.0);
      expect(fromJson.polygonPoints?.length, 4);
      expect(fromJson.polygonPoints?[0], [10.0, 20.0]);
    });

    test('OcrWord and OcrLine serialization', () {
      const word = OcrWord(
        text: 'MorphPDF',
        confidence: 0.99,
        boundingBox: OcrBoundingBox(left: 10, top: 10, width: 60, height: 20),
      );

      final wordJson = word.toJson();
      final wordFromJson = OcrWord.fromJson(wordJson);
      expect(wordFromJson.text, 'MorphPDF');
      expect(wordFromJson.confidence, 0.99);

      final line = OcrLine(
        text: 'MorphPDF App',
        confidence: 0.98,
        boundingBox: const OcrBoundingBox(left: 10, top: 10, width: 120, height: 20),
        words: [word],
      );

      final lineJson = line.toJson();
      final lineFromJson = OcrLine.fromJson(lineJson);
      expect(lineFromJson.text, 'MorphPDF App');
      expect(lineFromJson.words.length, 1);
    });

    test('OcrBlock and OcrPageResult serialization', () {
      final block = OcrBlock(
        id: 'blk_1',
        text: 'Line 1\nLine 2',
        confidence: 0.95,
        boundingBox: const OcrBoundingBox(left: 10, top: 10, width: 200, height: 100),
        language: 'en',
      );

      final page = OcrPageResult(
        pageIndex: 1,
        imageWidth: 800,
        imageHeight: 1200,
        blocks: [block],
        processingTimeMs: 150,
        engineUsed: 'PaddleOCR',
        isRightToLeft: false,
      );

      expect(page.fullText, 'Line 1\nLine 2');

      final pageJson = page.toJson();
      final pageFromJson = OcrPageResult.fromJson(pageJson);

      expect(pageFromJson.pageIndex, 1);
      expect(pageFromJson.imageWidth, 800);
      expect(pageFromJson.imageHeight, 1200);
      expect(pageFromJson.blocks.length, 1);
      expect(pageFromJson.blocks.first.text, 'Line 1\nLine 2');
      expect(pageFromJson.isRightToLeft, isFalse);
    });

    test('OcrProgress calculation and boundary clamping', () {
      const progress = OcrProgress(
        currentPage: 2,
        totalPages: 4,
        fraction: 0.5,
        statusMessage: 'Page 2/4',
      );

      expect(progress.percentage, 50);
      expect(progress.statusMessage, 'Page 2/4');

      const clampedUnder = OcrProgress(currentPage: 0, totalPages: 1, fraction: -0.2, statusMessage: 'Init');
      expect(clampedUnder.percentage, 0);

      const clampedOver = OcrProgress(currentPage: 1, totalPages: 1, fraction: 1.5, statusMessage: 'Done');
      expect(clampedOver.percentage, 100);
    });

    test('OcrCancellationToken can cancel and hold state', () {
      final token = OcrCancellationToken();
      expect(token.isCancelled, isFalse);
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('Typed OcrExceptions formatting and properties', () {
      const cancelled = OcrCancelledException();
      expect(cancelled.toString(), contains('annulé'));
      expect(cancelled.message, contains('annulé'));

      const tooLarge = OcrImageTooLargeException(width: 5000, height: 3000, maxAllowed: 4096);
      expect(tooLarge.width, 5000);
      expect(tooLarge.height, 3000);
      expect(tooLarge.maxAllowed, 4096);
      expect(tooLarge.toString(), contains('5000x3000'));
      expect(tooLarge.toString(), contains('4096x4096'));

      const modelNotFound = OcrModelNotFoundException('Model missing', 'assets/model.onnx');
      expect(modelNotFound.message, 'Model missing');
      expect(modelNotFound.details, 'assets/model.onnx');
      expect(modelNotFound.toString(), contains('assets/model.onnx'));

      const inferenceFailed = OcrInferenceFailedException('Inference error', 'Native error code 12');
      expect(inferenceFailed.toString(), contains('Inference error'));
      expect(inferenceFailed.toString(), contains('Native error code 12'));

      const unsupported = OcrUnsupportedLanguageException('Language xy not supported', 'Supported: ar, en');
      expect(unsupported.toString(), contains('xy'));
      expect(unsupported.toString(), contains('Supported: ar, en'));
    });
  });
}
