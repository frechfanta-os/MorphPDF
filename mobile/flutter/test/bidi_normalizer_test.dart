import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/bidi_normalizer.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';

void main() {
  group('BiDi Normalizer Tests', () {
    test('Arabic detection', () {
      expect(BidiNormalizer.containsArabic('الجمهورية الجزائرية'), isTrue);
      expect(BidiNormalizer.containsArabic('Hello World'), isFalse);
      expect(BidiNormalizer.containsArabic('Facture 2024'), isFalse);
      expect(BidiNormalizer.containsArabic('Doc رقم 123'), isTrue);

      expect(BidiNormalizer.isPredominantlyArabic('الجمهورية الجزائرية'), isTrue);
      expect(BidiNormalizer.isPredominantlyArabic('Hello World 123'), isFalse);
    });

    test('Non-destructive text normalization', () {
      final arabicText = 'الجمهورية الجزائرية الديمقراطية';
      final normalized = BidiNormalizer.normalizeText(arabicText);
      expect(normalized, arabicText);

      final mixed = 'MorphPDF وثيقة رسمية 2026';
      final normMixed = BidiNormalizer.normalizeText(mixed);
      expect(normMixed, contains('MorphPDF'));
      expect(normMixed, contains('وثيقة'));
      expect(normMixed, contains('2026'));
    });

    test('Preserves geometry during block and page normalization', () {
      const box = OcrBoundingBox(left: 100, top: 200, width: 300, height: 40);
      final block = OcrBlock(
        id: 'b1',
        text: 'وزارة العدل',
        confidence: 0.97,
        boundingBox: box,
        language: 'ar',
        lines: [
          const OcrLine(
            text: 'وزارة العدل',
            confidence: 0.97,
            boundingBox: box,
            words: [
              OcrWord(
                text: 'وزارة',
                confidence: 0.98,
                boundingBox: OcrBoundingBox(left: 100, top: 200, width: 140, height: 40),
              ),
              OcrWord(
                text: 'العدل',
                confidence: 0.96,
                boundingBox: OcrBoundingBox(left: 250, top: 200, width: 150, height: 40),
              ),
            ],
          ),
        ],
      );

      final page = OcrPageResult(
        pageIndex: 1,
        imageWidth: 1000,
        imageHeight: 1500,
        blocks: [block],
        processingTimeMs: 120,
        engineUsed: 'PaddleOCR',
        isRightToLeft: false,
      );

      final normalizedPage = BidiNormalizer.normalizePage(page);

      expect(normalizedPage.isRightToLeft, isTrue);
      expect(normalizedPage.blocks.first.boundingBox.left, 100);
      expect(normalizedPage.blocks.first.boundingBox.top, 200);
      expect(normalizedPage.blocks.first.boundingBox.width, 300);
      expect(normalizedPage.blocks.first.lines.first.words.length, 2);
      expect(normalizedPage.blocks.first.lines.first.words.first.boundingBox.left, 100);
    });
  });
}
