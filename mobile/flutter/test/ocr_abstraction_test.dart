import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/features/ocr/data/ocr_engines_mock.dart';
import 'package:morphpdf/features/ocr/domain/ocr_service.dart';

void main() {
  group('OCR Abstraction Tests', () {
    test('MlKitEngineMock extraction', () async {
      final engine = MlKitEngineMock();
      final service = OcrService(engine);

      expect(service.currentEngineName, contains('ML Kit'));
      expect(service.supportedLanguages, contains('fr'));

      final blocks = await service.processImage('/dummy/path/doc.jpg', lang: 'fr');
      expect(blocks, isNotEmpty);
      expect(blocks.first.text, contains('ML Kit'));
    });

    test('PaddleOcrEngineMock extraction with Arabic', () async {
      final engine = PaddleOcrEngineMock();
      final service = OcrService(engine);

      expect(service.currentEngineName, contains('PaddleOCR'));
      expect(service.supportedLanguages, contains('ar'));

      final blocks = await service.processImage('/dummy/path/arabic.jpg', lang: 'ar');
      expect(blocks, isNotEmpty);
      expect(blocks.first.language, 'ar');
    });
  });
}
