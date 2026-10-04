import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/features/conversion/data/mock_converter.dart';
import 'package:morphpdf/features/conversion/domain/conversion_service.dart';

void main() {
  group('Word Conversion Abstraction Tests', () {
    test('MockPdfToWordConverter through ConversionService', () async {
      final converter = MockPdfToWordConverter();
      final service = ConversionService(converter);

      expect(service.converterName, 'Mock DOCX Converter');

      final result = await service.convert('/input.pdf', '/output.docx');
      expect(result, '/output.docx');
    });
  });
}
