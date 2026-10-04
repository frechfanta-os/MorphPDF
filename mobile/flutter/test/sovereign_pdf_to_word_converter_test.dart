import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/features/conversion/data/mock_converter.dart';
import 'package:morphpdf/features/conversion/data/sovereign_pdf_to_word_converter.dart';
import 'package:morphpdf/features/conversion/domain/conversion_service.dart';

void main() {
  group('Sovereign PDF to Word Converter Integration Tests', () {
    final fixturePdf = 'test/fixtures/doc_french.pdf';
    final multiPagePdf = 'test/fixtures/doc_multipage.pdf';

    test('Converts native French PDF to real .docx package', () async {
      final converter = SovereignPdfToWordConverter();
      expect(converter.converterName, 'MorphPDF Sovereign OOXML Converter');

      final outputDocx = '${Directory.systemTemp.path}/french_converted.docx';
      final resultPath = await converter.convertPdfToWord(fixturePdf, outputDocx);

      expect(resultPath, outputDocx);
      final docxFile = File(resultPath);
      expect(await docxFile.exists(), isTrue);

      final bytes = await docxFile.readAsBytes();
      expect(bytes.length, greaterThan(100));

      // Test ZIP integrity
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, contains('[Content_Types].xml'));
      expect(names, contains('_rels/.rels'));
      expect(names, contains('word/document.xml'));
      expect(names, contains('word/styles.xml'));
      expect(names, contains('word/settings.xml'));
      expect(names, contains('word/_rels/document.xml.rels'));

      // Validate with unzip -t
      final unzipResult = await Process.run('unzip', ['-t', resultPath]);
      expect(unzipResult.exitCode, 0, reason: 'unzip -t failed: ${unzipResult.stderr}');
      expect(unzipResult.stdout.toString(), contains('No errors detected'));
    });

    test('Converts multipage PDF through ConversionService', () async {
      final service = ConversionService(); // Defaults to SovereignPdfToWordConverter
      expect(service.converterName, 'MorphPDF Sovereign OOXML Converter');

      final outputDocx = '${Directory.systemTemp.path}/multipage_converted.docx';
      final result = await service.convert(multiPagePdf, outputDocx);

      expect(result, outputDocx);
      final file = File(result);
      expect(await file.exists(), isTrue);

      final unzipResult = await Process.run('unzip', ['-t', result]);
      expect(unzipResult.exitCode, 0);
    });

    test('Mock converter remains functional for isolation testing', () async {
      final mock = MockPdfToWordConverter();
      final service = ConversionService(mock);

      expect(service.converterName, 'Mock DOCX Converter');
      final res = await service.convert('/dummy.pdf', '/dummy.docx');
      expect(res, '/dummy.docx');
    });
  });
}
