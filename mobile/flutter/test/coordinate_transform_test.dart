import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/pdf/pdf_models.dart';

void main() {
  group('CoordinateConverter Tests', () {
    test('pointsToPixels and pixelsToPoints at various DPIs', () {
      // 72 DPI: 1 point = 1 pixel
      expect(CoordinateConverter.pointsToPixels(72.0, 72), 72.0);
      expect(CoordinateConverter.pixelsToPoints(72.0, 72), 72.0);

      // 144 DPI: 1 point = 2 pixels
      expect(CoordinateConverter.pointsToPixels(100.0, 144), 200.0);
      expect(CoordinateConverter.pixelsToPoints(200.0, 144), 100.0);

      // 150 DPI: scale = 150/72 = 2.083333...
      final px150 = CoordinateConverter.pointsToPixels(72.0, 150);
      expect(px150, 150.0);
      expect(CoordinateConverter.pixelsToPoints(150.0, 150), 72.0);

      // 300 DPI: scale = 300/72
      final px300 = CoordinateConverter.pointsToPixels(595.0, 300);
      expect((px300 - 2479.16).abs() < 0.1, isTrue);
      expect((CoordinateConverter.pixelsToPoints(px300, 300) - 595.0).abs() < 0.001, isTrue);
    });

    test('pdfRectToPixelRect inverts Y axis correctly', () {
      const pageHeightPoints = 842.0;
      const dpi = 150;
      // In PDF (bottom-left origin):
      // A rectangle near top of page: x=50, y=780, w=200, h=30
      // In PDF, top edge is at y + h = 810 (or top is y)
      const pdfRect = Rect.fromLTWH(50.0, 800.0, 200.0, 30.0);

      final pixelRect = CoordinateConverter.pdfRectToPixelRect(pdfRect, pageHeightPoints, dpi);

      // Pixel X should scale by 150/72
      expect(pixelRect.left, (50.0 * 150.0 / 72.0));
      expect(pixelRect.width, (200.0 * 150.0 / 72.0));
      expect(pixelRect.height, (30.0 * 150.0 / 72.0));

      // Screen Y top = (pageHeight - pdfTop) * scale = (842 - 800) * 150/72 = 42 * 2.08333...
      expect((pixelRect.top - 87.5).abs() < 0.1, isTrue);

      // Roundtrip test
      final roundtrip = CoordinateConverter.pixelRectToPdfRect(pixelRect, pageHeightPoints, dpi);
      expect((roundtrip.left - pdfRect.left).abs() < 0.001, isTrue);
      expect((roundtrip.top - pdfRect.top).abs() < 0.001, isTrue);
      expect((roundtrip.width - pdfRect.width).abs() < 0.001, isTrue);
      expect((roundtrip.height - pdfRect.height).abs() < 0.001, isTrue);
    });
  });
}
