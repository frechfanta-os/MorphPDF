import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/ocr_coordinate_mapper.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';

void main() {
  group('OCR Coordinate Mapper Tests', () {
    test('Pixels to PDF Rect at 150 DPI', () {
      // At 150 DPI: 1 pt = 150 / 72 = 2.08333 pixels
      // 1 pixel = 72 / 150 = 0.48 pt
      // Page height = 842 pt (A4) = 1754.16 pixels
      const box = OcrBoundingBox(
        left: 150, // 150 * 72 / 150 = 72 pt
        top: 150,  // top in pixels from top-left
        width: 300, // 300 * 72 / 150 = 144 pt
        height: 50, // 50 * 72 / 150 = 24 pt
      );

      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: 842.0,
        dpi: 150,
      );

      expect(rect.left, closeTo(72.0, 0.1));
      expect(rect.width, closeTo(144.0, 0.1));
      expect(rect.height, closeTo(24.0, 0.1));
      // Invert Y axis: topInPdf = pageHeightPt - (top / scale) = 842 - 72 = 770.0
      expect(rect.top, closeTo(770.0, 0.1));
    });

    test('toTextBlocks transforms OcrPageResult into TextBlocks', () {
      const box = OcrBoundingBox(left: 100, top: 100, width: 200, height: 40);
      final block = OcrBlock(
        id: 'block_1',
        text: 'MorphPDF Section',
        confidence: 0.96,
        boundingBox: box,
        language: 'en',
      );

      final pageResult = OcrPageResult(
        pageIndex: 1,
        imageWidth: 1000,
        imageHeight: 1500,
        blocks: [block],
        processingTimeMs: 100,
        engineUsed: 'PaddleOCR',
      );

      final textBlocks = OcrCoordinateMapper.toTextBlocks(
        pageResult: pageResult,
        pageHeightPt: 842.0,
        dpi: 150,
      );

      expect(textBlocks.length, 1);
      expect(textBlocks.first.id, 'ocr_1_1');
      expect(textBlocks.first.pageNumber, 1);
      expect(textBlocks.first.text, 'MorphPDF Section');
      expect(textBlocks.first.confidence, 0.96);
      expect(textBlocks.first.width, closeTo(96.0, 0.1));
    });
  });
}
