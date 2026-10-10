// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';
import 'package:morphpdf/features/conversion/data/sovereign_pdf_to_word_converter.dart';
import 'package:morphpdf/features/conversion/domain/conversion_converter.dart';
import 'helpers/real_pdf_corpus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Batch convert all 15 reference corpus PDFs to DOCX for Phase 6 validation', () async {
    final outputDir = Directory('/tmp/morph_e2e_docx');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final corpusPaths = await RealPdfCorpus.ensureCorpusGenerated();
    final pdfEngine = PdfiumEngine();
    final converter = SovereignPdfToWordConverter(pdfEngine: pdfEngine);

    print('Converting ${corpusPaths.length} reference corpus PDFs to DOCX...');

    for (final entry in corpusPaths.entries) {
      final pdfPath = entry.value;
      final docxPath = '${outputDir.path}/${entry.key}.docx';
      final sw = Stopwatch()..start();
      await converter.convertPdfToWord(
        pdfPath,
        docxPath,
        options: const ConversionOptions(ocrScannedPages: false),
      );
      sw.stop();
      print('  - [OK] ${entry.key}.docx (${sw.elapsedMilliseconds} ms, ${File(docxPath).lengthSync()} bytes)');
      expect(File(docxPath).existsSync(), isTrue);
      expect(File(docxPath).lengthSync(), greaterThan(1000));
    }

    pdfEngine.dispose();
    print('Conversion complete! All DOCX files written to ${outputDir.path}');
  });
}
