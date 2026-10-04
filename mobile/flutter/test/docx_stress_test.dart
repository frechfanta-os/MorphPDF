import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/docx/layout/docx_elements.dart';
import 'package:morphpdf/core/docx/layout/layout_reconstructor.dart';
import 'package:morphpdf/core/docx/ooxml_package.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';
import 'package:morphpdf/features/conversion/data/sovereign_pdf_to_word_converter.dart';

import 'helpers/pdf_corpus_builder.dart';

void main() {
  group('Phase 5.3 Stress, Scalability & Performance Benchmarks', () {
    late PdfiumEngine pdfEngine;
    late SovereignPdfToWordConverter converter;
    late Directory tempDir;

    setUpAll(() async {
      pdfEngine = PdfiumEngine();
      converter = SovereignPdfToWordConverter(pdfEngine: pdfEngine);
      tempDir = Directory('${Directory.systemTemp.path}/morph_stress_test');
      await tempDir.create(recursive: true);
    });

    tearDownAll(() {
      pdfEngine.dispose();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<String> createSyntheticMultiPagePdf(int pageCount) async {
      final pages = List.generate(pageCount, (index) {
        final p = index + 1;
        return [
          PdfTextItem(text: 'Document de Charge - Page $p sur $pageCount', x: 50, y: 780, fontSize: 18),
          PdfTextItem(text: 'Section technique et traitement volumetrique haute performance.', x: 50, y: 740, fontSize: 12),
          PdfTextItem(text: 'Paragraphe de verification de la stabilite memoire et sans fuite.', x: 50, y: 700, fontSize: 12),
          PdfTextItem(text: '• Item analytique 1 pour la page $p', x: 50, y: 660, fontSize: 12),
          PdfTextItem(text: '• Item analytique 2 pour la page $p', x: 50, y: 630, fontSize: 12),
        ];
      });

      final filePath = '${tempDir.path}/stress_${pageCount}p.pdf';
      final pdfContent = PdfCorpusBuilder.buildPdf(pages: pages);
      await PdfCorpusBuilder.writePdfFile(filePath, pdfContent);
      return filePath;
    }

    test('Benchmark 1 Page (Target: < 100 ms)', () async {
      final pdfPath = await createSyntheticMultiPagePdf(1);
      final docxPath = '${tempDir.path}/out_1p.docx';

      final sw = Stopwatch()..start();
      await converter.convertPdfToWord(pdfPath, docxPath);
      sw.stop();

      final totalMs = sw.elapsedMilliseconds;
      final fileSizeBytes = await File(docxPath).length();

      // Print structured benchmark metrics
      // ignore: avoid_print
      print('[BENCHMARK 1 PAGE] Total: ${totalMs}ms | DOCX Size: $fileSizeBytes bytes');
      expect(File(docxPath).existsSync(), isTrue);
      expect(totalMs, lessThan(300)); // Target < 100ms, generous margin for test runner
    });

    test('Benchmark 10 Pages (Target: < 650 ms)', () async {
      final pdfPath = await createSyntheticMultiPagePdf(10);
      final docxPath = '${tempDir.path}/out_10p.docx';

      // Detailed timing breakdown
      final swTotal = Stopwatch()..start();

      final swInspect = Stopwatch()..start();
      final inspection = await pdfEngine.inspect(pdfPath);
      expect(inspection.pageCount, 10);
      final pages = await pdfEngine.getPages(pdfPath);
      swInspect.stop();

      final swExtract = Stopwatch()..start();
      final allBlocks = <dynamic>[];
      for (int i = 1; i <= pages.length; i++) {
        final blocks = await pdfEngine.extractTextBlocks(pdfPath, i);
        allBlocks.add(blocks);
      }
      swExtract.stop();

      final swLayout = Stopwatch()..start();
      final sections = <DocxSection>[];
      for (int i = 0; i < pages.length; i++) {
        final elements = LayoutReconstructor.reconstructPage(
          page: pages[i],
          textBlocks: allBlocks[i],
        );
        sections.add(DocxSection(elements: elements));
      }
      swLayout.stop();

      final swDocx = Stopwatch()..start();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: sections);
      await File(docxPath).writeAsBytes(docxBytes, flush: true);
      swDocx.stop();

      swTotal.stop();

      // ignore: avoid_print
      print('[BENCHMARK 10 PAGES] Total: ${swTotal.elapsedMilliseconds}ms | '
          'Inspect: ${swInspect.elapsedMilliseconds}ms | '
          'Extract: ${swExtract.elapsedMilliseconds}ms | '
          'Layout: ${swLayout.elapsedMilliseconds}ms | '
          'DOCX+ZIP: ${swDocx.elapsedMilliseconds}ms | '
          'Size: ${docxBytes.length} bytes');

      expect(File(docxPath).existsSync(), isTrue);
      expect(swTotal.elapsedMilliseconds, lessThan(1200));
    });

    test('Benchmark 25 Pages (Target: < 1.8 s)', () async {
      final pdfPath = await createSyntheticMultiPagePdf(25);
      final docxPath = '${tempDir.path}/out_25p.docx';

      final sw = Stopwatch()..start();
      await converter.convertPdfToWord(pdfPath, docxPath);
      sw.stop();

      final totalMs = sw.elapsedMilliseconds;
      final fileSizeBytes = await File(docxPath).length();

      // ignore: avoid_print
      print('[BENCHMARK 25 PAGES] Total: ${totalMs}ms | DOCX Size: $fileSizeBytes bytes');
      expect(File(docxPath).existsSync(), isTrue);
      expect(totalMs, lessThan(2500));
    });

    test('Benchmark 50 Pages (Target: < 3.5 s)', () async {
      final pdfPath = await createSyntheticMultiPagePdf(50);
      final docxPath = '${tempDir.path}/out_50p.docx';

      final sw = Stopwatch()..start();
      await converter.convertPdfToWord(pdfPath, docxPath);
      sw.stop();

      final totalMs = sw.elapsedMilliseconds;
      final fileSizeBytes = await File(docxPath).length();

      // ignore: avoid_print
      print('[BENCHMARK 50 PAGES] Total: ${totalMs}ms | DOCX Size: $fileSizeBytes bytes');
      expect(File(docxPath).existsSync(), isTrue);
      expect(totalMs, lessThan(4500));

      final unzip = await Process.run('unzip', ['-t', docxPath]);
      expect(unzip.exitCode, 0);
    });
  });
}
