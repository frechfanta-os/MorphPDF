import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/bidi_normalizer.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';

void main() {
  group('BiDi Normalizer Logic Tests (BIDI LOGIC VERIFIED)', () {
    test('Pure Arabic detection and predominant language detection', () {
      expect(BidiNormalizer.containsArabic('الجمهورية الجزائرية الديمقراطية'), isTrue);
      expect(BidiNormalizer.isPredominantlyArabic('الجمهورية الجزائرية'), isTrue);

      expect(BidiNormalizer.containsArabic('MorphPDF Document Reader'), isFalse);
      expect(BidiNormalizer.isPredominantlyArabic('MorphPDF Document Reader'), isFalse);
    });

    test('Mixed Arabic and Latin detection', () {
      const mixed1 = 'Document officiel de la République: الجمهورية الجزائرية';
      expect(BidiNormalizer.containsArabic(mixed1), isTrue);
      // Latin rune count is higher than Arabic here
      expect(BidiNormalizer.isPredominantlyArabic(mixed1), isFalse);

      const mixed2 = 'وثيقة رسمية MorphPDF للتطبيق';
      expect(BidiNormalizer.containsArabic(mixed2), isTrue);
      expect(BidiNormalizer.isPredominantlyArabic(mixed2), isTrue);
    });

    test('Arabic with Western numbers (0-9)', () {
      const textWithWesternNums = 'قانون رقم 24 لسنة 2026';
      final normalized = BidiNormalizer.normalizeText(textWithWesternNums);
      expect(normalized, textWithWesternNums);
      expect(normalized, contains('24'));
      expect(normalized, contains('2026'));
      expect(normalized, contains('قانون'));
    });

    test('Arabic with Arabic-Indic digits (٠-٩)', () {
      const textWithIndicNums = 'المادة ٤٥ من الدستور ١٩٩٦';
      final normalized = BidiNormalizer.normalizeText(textWithIndicNums);
      expect(normalized, textWithIndicNums);
      expect(normalized, contains('٤٥'));
      expect(normalized, contains('١٩٩٦'));
    });

    test('Arabic with specialized punctuation (، ؛ ؟ . ! - « »)', () {
      const punctuatedText = '«الجمهورية الجزائرية»؛ وزارة العدل: هل تم التعديل؟ نعم!';
      final normalized = BidiNormalizer.normalizeText(punctuatedText);
      expect(normalized, punctuatedText);
      expect(normalized, contains('«'));
      expect(normalized, contains('»'));
      expect(normalized, contains('؛'));
      expect(normalized, contains('؟'));
    });

    test('Preservation of spatial coordinates across nested Word -> Line -> Block hierarchy', () {
      const wordBox1 = OcrBoundingBox(left: 100.0, top: 200.0, width: 80.0, height: 35.0);
      const wordBox2 = OcrBoundingBox(left: 190.0, top: 200.0, width: 90.0, height: 35.0);
      const lineBox = OcrBoundingBox(left: 100.0, top: 200.0, width: 180.0, height: 35.0);
      const blockBox = OcrBoundingBox(left: 100.0, top: 200.0, width: 180.0, height: 75.0);

      final word1 = const OcrWord(text: 'وزارة', confidence: 0.98, boundingBox: wordBox1);
      final word2 = const OcrWord(text: 'العدل', confidence: 0.97, boundingBox: wordBox2);
      final line = OcrLine(text: 'وزارة العدل', confidence: 0.975, boundingBox: lineBox, words: [word1, word2]);

      final block = OcrBlock(
        id: 'block_ar_deep',
        text: 'وزارة العدل',
        confidence: 0.975,
        boundingBox: blockBox,
        language: 'ar',
        lines: [line],
      );

      final page = OcrPageResult(
        pageIndex: 1,
        imageWidth: 1200,
        imageHeight: 1800,
        blocks: [block],
        processingTimeMs: 140,
        engineUsed: 'PaddleOCR',
        isRightToLeft: false,
      );

      final normalizedPage = BidiNormalizer.normalizePage(page);

      // Verify logical RTL flag
      expect(normalizedPage.isRightToLeft, isTrue);

      // Verify exact spatial preservation
      final normBlock = normalizedPage.blocks.first;
      expect(normBlock.boundingBox.left, 100.0);
      expect(normBlock.boundingBox.top, 200.0);
      expect(normBlock.boundingBox.width, 180.0);
      expect(normBlock.boundingBox.height, 75.0);

      final normLine = normBlock.lines.first;
      expect(normLine.boundingBox.left, 100.0);
      expect(normLine.boundingBox.width, 180.0);

      final normWord1 = normLine.words[0];
      final normWord2 = normLine.words[1];
      expect(normWord1.boundingBox.left, 100.0);
      expect(normWord1.boundingBox.width, 80.0);
      expect(normWord2.boundingBox.left, 190.0);
      expect(normWord2.boundingBox.width, 90.0);
    });

    test('Non-destructive behavior on purely Latin and alphanumeric text', () {
      const latinText = 'MorphPDF Studio 2026 - All Rights Reserved.';
      final normalized = BidiNormalizer.normalizeText(latinText);
      expect(normalized, latinText);
    });
  });
}
