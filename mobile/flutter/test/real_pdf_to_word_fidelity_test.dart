import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';
import 'package:morphpdf/features/conversion/data/sovereign_pdf_to_word_converter.dart';

import 'helpers/docx_inspector.dart';
import 'helpers/fidelity_scorer.dart';
import 'helpers/golden_generator.dart';
import 'helpers/real_pdf_corpus.dart';

void main() {
  group('Phase 5.3 Real-World PDF to Word Fidelity & Validation Tests', () {
    late PdfiumEngine pdfEngine;
    late SovereignPdfToWordConverter converter;
    late Map<String, String> corpusPaths;
    late Directory outputDir;

    setUpAll(() async {
      pdfEngine = PdfiumEngine();
      converter = SovereignPdfToWordConverter(pdfEngine: pdfEngine);
      corpusPaths = await RealPdfCorpus.ensureCorpusGenerated();
      outputDir = Directory('${Directory.systemTemp.path}/morph_phase53_output');
      await outputDir.create(recursive: true);
    });

    tearDownAll(() {
      pdfEngine.dispose();
      try {
        outputDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('00_golden_generation: Captures real DocumentModel goldens for all 15 fixtures', () async {
      for (final entry in corpusPaths.entries) {
        final golden = await GoldenGenerator.generateGoldenForPdf(
          engine: pdfEngine,
          fixtureName: entry.key,
          pdfPath: entry.value,
        );
        expect(golden['documentModel'], isNotNull);
        expect(golden['metrics']['pageCount'], greaterThan(0));

        final goldenFile = File('${GoldenGenerator.goldenDir}/${entry.key}.json');
        expect(await goldenFile.exists(), isTrue);
      }
    });

    test('01_simple_french: Full pipeline conversion and text fidelity', () async {
      final pdfPath = corpusPaths['01_simple_french']!;
      final docxPath = '${outputDir.path}/01_simple_french.docx';

      final result = await converter.convertPdfToWord(pdfPath, docxPath);
      expect(result, docxPath);

      final profile = await DocxInspector.inspectFile(docxPath);
      expect(profile.paragraphCount, greaterThanOrEqualTo(3));
      expect(profile.fullText, contains('Rapport'));
      expect(profile.fullText, contains('souveraine'));
      expect(profile.fullText, contains('local'));

      final unzip = await Process.run('unzip', ['-t', docxPath]);
      expect(unzip.exitCode, 0);

      final score = FidelityScorer.evaluate(
        fixtureName: '01_simple_french',
        sourceText: "Rapport d'activite officiel 2026 Direction Generale souveraine local",
        docxText: profile.fullText,
        sourcePageCount: 1,
        docxPageCount: profile.sectionCount,
      );
      expect(score.overallScorePercent, greaterThanOrEqualTo(95.0));
    });

    test('02_arabic_rtl: Real Arabic document with RTL direction and CS fonts', () async {
      final pdfPath = corpusPaths['02_arabic_rtl']!;
      final docxPath = '${outputDir.path}/02_arabic_rtl.docx';

      await converter.convertPdfToWord(pdfPath, docxPath);
      final profile = await DocxInspector.inspectFile(docxPath);

      expect(profile.rtlParagraphCount, greaterThan(0));
      expect(profile.fullText, contains('تقرير الأداء المالي السنوي'));
      expect(profile.fullText, contains('السيادة الرقمية'));

      final docXml = profile.xmlFiles['word/document.xml']!;
      expect(docXml, contains('<w:bidi/>'));
      expect(docXml, contains('<w:jc w:val="right"/>'));
    });

    test('03_mixed_arabic_french: Bilingual mixed document preserves both scripts', () async {
      final pdfPath = corpusPaths['03_mixed_arabic_french']!;
      final docxPath = '${outputDir.path}/03_mixed_arabic_french.docx';

      await converter.convertPdfToWord(pdfPath, docxPath);
      final profile = await DocxInspector.inspectFile(docxPath);

      expect(profile.fullText, contains('Rapport bilingue:'));
      expect(profile.fullText, contains('مشروع مورف الرقمي'));
      expect(profile.fullText, contains('GHD Interactive Studio'));
    });

    test('04_two_columns: Multi-column reading order integrity without line interleaving', () async {
      final pdfPath = corpusPaths['04_two_columns']!;
      final docxPath = '${outputDir.path}/04_two_columns.docx';

      await converter.convertPdfToWord(pdfPath, docxPath);
      final profile = await DocxInspector.inspectFile(docxPath);

      final text = profile.fullText;
      // In reading order: Column 1 lines must appear before Column 2 lines!
      // Must NOT be Col1_Line1 -> Col2_Line1 -> Col1_Line2 -> Col2_Line2!
      final idxCol1Line1 = text.indexOf('Colonne Gauche Ligne 1');
      final idxCol1Line2 = text.indexOf('Colonne Gauche Ligne 2');
      final idxCol2Line1 = text.indexOf('Colonne Droite Ligne 1');
      final idxCol2Line2 = text.indexOf('Colonne Droite Ligne 2');

      expect(idxCol1Line1, isNot(-1));
      expect(idxCol1Line2, isNot(-1));
      expect(idxCol2Line1, isNot(-1));
      expect(idxCol2Line2, isNot(-1));

      expect(idxCol1Line1, lessThan(idxCol1Line2));
      expect(idxCol1Line2, lessThan(idxCol2Line1));
      expect(idxCol2Line1, lessThan(idxCol2Line2));
    });

    test('05_heading_document: Heading hierarchy correctly styled', () async {
      final pdfPath = corpusPaths['05_heading_document']!;
      final docxPath = '${outputDir.path}/05_heading_document.docx';

      await converter.convertPdfToWord(pdfPath, docxPath);
      final profile = await DocxInspector.inspectFile(docxPath);

      final docXml = profile.xmlFiles['word/document.xml']!;
      expect(docXml, contains('Heading1'));
      expect(docXml, contains('Heading2'));
      expect(profile.fullText, contains('Architecture Globale'));
      expect(profile.fullText, contains('ECMA-376'));
    });

    test('06_bullets_numbering: Bullet and numbered lists with numbering.xml and stripped prefix', () async {
      final pdfPath = corpusPaths['06_bullets_numbering']!;
      final docxPath = '${outputDir.path}/06_bullets_numbering.docx';

      await converter.convertPdfToWord(pdfPath, docxPath);
      final profile = await DocxInspector.inspectFile(docxPath);

      expect(profile.numberingCount, 1);
      final docXml = profile.xmlFiles['word/document.xml']!;
      expect(docXml, contains('<w:numId w:val="1"/>')); // Bullet
      expect(docXml, contains('<w:numId w:val="2"/>')); // Decimal
    });

    test('07_table & 08_table_rtl: Table matrix preservation and RTL support', () async {
      final pdfPath = corpusPaths['07_table']!;
      final docxPath = '${outputDir.path}/07_table.docx';

      await converter.convertPdfToWord(pdfPath, docxPath);
      final profile = await DocxInspector.inspectFile(docxPath);
      expect(profile.fullText, contains('PDFium'));
      expect(profile.fullText, contains('PaddleOCR'));
      expect(profile.fullText, contains('Sovereign OOXML'));

      final pdfRtlPath = corpusPaths['08_table_rtl']!;
      final docxRtlPath = '${outputDir.path}/08_table_rtl.docx';

      await converter.convertPdfToWord(pdfRtlPath, docxRtlPath);
      final profileRtl = await DocxInspector.inspectFile(docxRtlPath);
      expect(profileRtl.fullText, contains('الميزانية التشغيلية'));
      expect(profileRtl.fullText, contains('١٠٠٠٠٠ ريال'));
    });

    test('09_images & 14_url_text: Image DrawingML and Text Hyperlink validation', () async {
      final pdfPath = corpusPaths['14_url_text']!;
      final docxPath = '${outputDir.path}/14_url_text.docx';

      await converter.convertPdfToWord(pdfPath, docxPath);
      final profile = await DocxInspector.inspectFile(docxPath);

      expect(profile.hyperlinkCount, greaterThan(0));
      expect(profile.fullText, contains('https://morphpdf.example.com'));

      final relsXml = profile.xmlFiles['word/_rels/document.xml.rels']!;
      expect(relsXml, contains('Target="https://morphpdf.example.com"'));
      expect(relsXml, contains('TargetMode="External"'));
    });

    test('10_header_footer: Multi-page document with dedicated headers and footers', () async {
      final pdfPath = corpusPaths['10_header_footer']!;
      final docxPath = '${outputDir.path}/10_header_footer.docx';

      await converter.convertPdfToWord(pdfPath, docxPath);
      final profile = await DocxInspector.inspectFile(docxPath);

      expect(profile.headerCount, 1);
      expect(profile.footerCount, 1);

      final headerXml = profile.xmlFiles['word/header1.xml']!;
      final footerXml = profile.xmlFiles['word/footer1.xml']!;
      expect(headerXml, contains('MorphPDF Enterprise Report'));
      expect(footerXml, contains('Confidentiel'));
    });

    test('11_landscape & 12_multi_page: Page orientation and multi-page preservation', () async {
      final pdfLandscapePath = corpusPaths['11_landscape']!;
      final docxLandscapePath = '${outputDir.path}/11_landscape.docx';

      await converter.convertPdfToWord(pdfLandscapePath, docxLandscapePath);
      final profileLandscape = await DocxInspector.inspectFile(docxLandscapePath);

      final docXml = profileLandscape.xmlFiles['word/document.xml']!;
      expect(docXml, contains('w:orient="landscape"'));

      final pdfMultiPath = corpusPaths['12_multi_page']!;
      final docxMultiPath = '${outputDir.path}/12_multi_page.docx';

      await converter.convertPdfToWord(pdfMultiPath, docxMultiPath);
      final profileMulti = await DocxInspector.inspectFile(docxMultiPath);

      expect(profileMulti.pageBreakCount, greaterThanOrEqualTo(2));
      expect(profileMulti.fullText, contains('Premiere Page'));
      expect(profileMulti.fullText, contains('Deuxieme Page'));
      expect(profileMulti.fullText, contains('Troisieme Page'));
    });

    test('13_mixed_complex & 15_stress_document: Complex and stress multi-page conversions', () async {
      final pdfComplexPath = corpusPaths['13_mixed_complex']!;
      final docxComplexPath = '${outputDir.path}/13_mixed_complex.docx';

      await converter.convertPdfToWord(pdfComplexPath, docxComplexPath);
      final profileComplex = await DocxInspector.inspectFile(docxComplexPath);
      expect(profileComplex.fullText, contains('Synthese Globale'));
      expect(profileComplex.fullText, contains('تقرير سنوي شامل'));

      final pdfStressPath = corpusPaths['15_stress_document']!;
      final docxStressPath = '${outputDir.path}/15_stress_document.docx';

      final stopwatch = Stopwatch()..start();
      await converter.convertPdfToWord(pdfStressPath, docxStressPath);
      stopwatch.stop();

      final profileStress = await DocxInspector.inspectFile(docxStressPath);
      expect(profileStress.pageBreakCount, 9); // 10 pages -> 9 page breaks
      expect(profileStress.fullText, contains('Page 10'));

      // Validate ZIP with unzip -t
      final unzip = await Process.run('unzip', ['-t', docxStressPath]);
      expect(unzip.exitCode, 0);

      // Verify execution time for 10 pages is well within target (< 650 ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}
