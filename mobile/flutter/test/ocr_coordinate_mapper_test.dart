import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/ocr_coordinate_mapper.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';

void main() {
  group('OCR Coordinate Mapper & Geometry Transformation Tests', () {
    const double pageW = 595.0; // A4 standard width in points
    const double pageH = 842.0; // A4 standard height in points
    const int dpi = 150;
    // Scale at 150 DPI: 150 / 72 = 2.0833333333333335 px/pt -> 1 px = 0.48 pt

    test('Zero rotation (0°) - Y-axis inversion and scaling at 150 DPI', () {
      const box = OcrBoundingBox(
        left: 150.0,
        top: 150.0,
        width: 300.0,
        height: 50.0,
      );

      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageH,
        pageWidthPt: pageW,
        dpi: dpi,
        rotationDegrees: 0,
      );

      expect(rect.left, closeTo(72.0, 0.01));
      expect(rect.width, closeTo(144.0, 0.01));
      expect(rect.height, closeTo(24.0, 0.01));
      // Invert Y: 842 - (150 * 72 / 150) = 842 - 72 = 770.0
      expect(rect.top, closeTo(770.0, 0.01));
    });

    test('300 DPI High-Resolution Scaling', () {
      const int highDpi = 300;
      // At 300 DPI: 1 px = 72 / 300 = 0.24 pt
      const box = OcrBoundingBox(
        left: 300.0, // 72 pt
        top: 600.0,  // 144 pt
        width: 600.0, // 144 pt
        height: 100.0, // 24 pt
      );

      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageH,
        pageWidthPt: pageW,
        dpi: highDpi,
        rotationDegrees: 0,
      );

      expect(rect.left, closeTo(72.0, 0.01));
      expect(rect.width, closeTo(144.0, 0.01));
      expect(rect.height, closeTo(24.0, 0.01));
      expect(rect.top, closeTo(pageH - 144.0, 0.01));
    });

    test('Top-Left Corner', () {
      const box = OcrBoundingBox(left: 0.0, top: 0.0, width: 100.0, height: 50.0);
      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageH,
        pageWidthPt: pageW,
        dpi: dpi,
      );

      expect(rect.left, closeTo(0.0, 0.01));
      expect(rect.top, closeTo(pageH, 0.01));
      expect(rect.width, closeTo(48.0, 0.01));
      expect(rect.height, closeTo(24.0, 0.01));
    });

    test('Bottom-Right Corner', () {
      final double maxPxW = pageW * dpi / 72.0; // 1239.58 px
      final double maxPxH = pageH * dpi / 72.0; // 1754.16 px
      final box = OcrBoundingBox(
        left: maxPxW - 100.0,
        top: maxPxH - 50.0,
        width: 100.0,
        height: 50.0,
      );

      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageH,
        pageWidthPt: pageW,
        dpi: dpi,
      );

      expect(rect.right, closeTo(pageW, 0.05));
      expect(rect.top, closeTo(24.0, 0.05)); // (pageH - (maxPxH - 50)*0.48) = 24.0 pt
    });

    test('Center of the page', () {
      final double centerPxX = (pageW * dpi / 72.0) / 2.0;
      final double centerPxY = (pageH * dpi / 72.0) / 2.0;
      final box = OcrBoundingBox(
        left: centerPxX - 50.0,
        top: centerPxY - 25.0,
        width: 100.0,
        height: 50.0,
      );

      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageH,
        pageWidthPt: pageW,
        dpi: dpi,
      );

      final centerPtX = rect.left + rect.width / 2.0;
      final centerPtY = rect.top - rect.height / 2.0; // Inverted Y reference
      expect(centerPtX, closeTo(pageW / 2.0, 0.05));
      expect(centerPtY, closeTo(pageH / 2.0, 0.05));
    });

    test('Rotation 90° clockwise', () {
      const box = OcrBoundingBox(left: 150.0, top: 150.0, width: 300.0, height: 50.0);
      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageH,
        pageWidthPt: pageW,
        dpi: dpi,
        rotationDegrees: 90,
      );

      // In 90°: width and height swap, coordinates rotated
      expect(rect.width, closeTo(24.0, 0.01));
      expect(rect.height, closeTo(144.0, 0.01));
      expect(rect.left, closeTo(770.0, 0.01)); // mapped from top
    });

    test('Rotation 180°', () {
      const box = OcrBoundingBox(left: 150.0, top: 150.0, width: 300.0, height: 50.0);
      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageH,
        pageWidthPt: pageW,
        dpi: dpi,
        rotationDegrees: 180,
      );

      expect(rect.width, closeTo(144.0, 0.01));
      expect(rect.height, closeTo(24.0, 0.01));
      expect(rect.left, closeTo(pageW - (72.0 + 144.0), 0.01));
    });

    test('Rotation 270°', () {
      const box = OcrBoundingBox(left: 150.0, top: 150.0, width: 300.0, height: 50.0);
      final rect = OcrCoordinateMapper.ocrBoxToPdfRect(
        box: box,
        pageHeightPt: pageH,
        pageWidthPt: pageW,
        dpi: dpi,
        rotationDegrees: 270,
      );

      expect(rect.width, closeTo(24.0, 0.01));
      expect(rect.height, closeTo(144.0, 0.01));
      expect(rect.top, closeTo(72.0, 0.01));
    });

    test('toTextBlocks transforms multi-block OcrPageResult into TextBlocks', () {
      final blocks = [
        const OcrBlock(
          id: 'b1',
          text: 'Title 1',
          confidence: 0.99,
          boundingBox: OcrBoundingBox(left: 50, top: 50, width: 200, height: 30),
          language: 'fr',
        ),
        const OcrBlock(
          id: 'b2',
          text: 'Paragraph 2',
          confidence: 0.95,
          boundingBox: OcrBoundingBox(left: 50, top: 100, width: 400, height: 60),
          language: 'fr',
        ),
      ];

      final pageResult = OcrPageResult(
        pageIndex: 1,
        imageWidth: 1000,
        imageHeight: 1500,
        blocks: blocks,
        processingTimeMs: 120,
        engineUsed: 'PaddleOCR',
      );

      final textBlocks = OcrCoordinateMapper.toTextBlocks(
        pageResult: pageResult,
        pageHeightPt: pageH,
        dpi: dpi,
      );

      expect(textBlocks.length, 2);
      expect(textBlocks[0].id, 'ocr_1_1');
      expect(textBlocks[0].text, 'Title 1');
      expect(textBlocks[1].id, 'ocr_1_2');
      expect(textBlocks[1].text, 'Paragraph 2');
    });
  });
}
