import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/bidi_normalizer.dart';
import 'package:morphpdf/core/ocr/ocr_coordinate_mapper.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';
import 'package:morphpdf/features/conversion/data/sovereign_pdf_to_word_converter.dart';
import 'package:morphpdf/features/conversion/domain/conversion_converter.dart';
import 'package:morphpdf/features/ocr/data/ocr_engines_mock.dart';
import 'package:morphpdf/features/ocr/domain/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 5.6: ONNX Models & Dictionaries Static Verification', () {
    test('models_manifest.json specifies verified PP-OCR models with hashes', () async {
      final manifestFile = File('assets/models/ocr/models_manifest.json');
      expect(await manifestFile.exists(), isTrue);

      final content = await manifestFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      expect(data['version'], '1.1.0');

      final models = data['models'] as Map<String, dynamic>;
      expect(models.containsKey('detection'), isTrue);
      expect(models.containsKey('recognition_latin'), isTrue);
      expect(models.containsKey('recognition_arabic'), isTrue);

      final det = models['detection'] as Map<String, dynamic>;
      expect(det['format'], contains('ONNX'));
      expect(det['input_name'], 'x');
      expect(det['output_name'], 'sigmoid_0.tmp_0');

      final recLatin = models['recognition_latin'] as Map<String, dynamic>;
      expect(recLatin['input_name'], 'x');
      expect(recLatin['output_name'], 'softmax_2.tmp_0');
      expect(recLatin['vocabulary_size'], 97);

      final recArabic = models['recognition_arabic'] as Map<String, dynamic>;
      expect(recArabic['input_name'], 'x');
      expect(recArabic['output_name'], 'softmax_2.tmp_0');
      expect(recArabic['vocabulary_size'], 163);
    });

    test('Real ONNX model binaries exist on disk with valid sizes', () async {
      final detFile = File('assets/models/ocr/detection/ch_PP-OCRv4_det_infer.onnx');
      final latinRecFile = File('assets/models/ocr/recognition/latin/en_PP-OCRv4_rec_infer.onnx');
      final arabicRecFile = File('assets/models/ocr/recognition/arabic/arabic_PP-OCRv3_rec_infer.onnx');

      expect(await detFile.exists(), isTrue, reason: 'Detection model must exist');
      expect(await latinRecFile.exists(), isTrue, reason: 'Latin Rec model must exist');
      expect(await arabicRecFile.exists(), isTrue, reason: 'Arabic Rec model must exist');

      final detSize = await detFile.length();
      final latinSize = await latinRecFile.length();
      final arabicSize = await arabicRecFile.length();

      expect(detSize, greaterThan(4 * 1024 * 1024)); // ~4.7 MB
      expect(latinSize, greaterThan(7 * 1024 * 1024)); // ~7.3 MB
      expect(arabicSize, greaterThan(8 * 1024 * 1024)); // ~8.5 MB

      // Verify tensor names are present in binary protobuf definitions
      final detBytes = await detFile.readAsBytes();
      final latinBytes = await latinRecFile.readAsBytes();
      final arabicBytes = await arabicRecFile.readAsBytes();

      expect(latinBytes.contains(120), isTrue); // ASCII 'x'
      expect(utf8.decode(detBytes, allowMalformed: true), contains('sigmoid_0.tmp_0'));
      expect(utf8.decode(latinBytes, allowMalformed: true), contains('softmax_2.tmp_0'));
      expect(utf8.decode(arabicBytes, allowMalformed: true), contains('softmax_2.tmp_0'));
    });

    test('Real dictionaries exist and match character counts', () async {
      final enDict = File('assets/models/ocr/dictionaries/en_dict.txt');
      final arDict = File('assets/models/ocr/dictionaries/arabic_dict.txt');

      expect(await enDict.exists(), isTrue);
      expect(await arDict.exists(), isTrue);

      final enLines = (await enDict.readAsLines()).where((l) => l.isNotEmpty).toList();
      final arLines = (await arDict.readAsLines()).where((l) => l.isNotEmpty).toList();

      expect(enLines.length, 95); // 95 chars (including space) + blank (0) + CTC space fallback = 97
      expect(arLines.length, 161); // 161 chars + blank (0) + space = 163
    });
  });

  group('Phase 5.6: PDFium -> OCR Decision Pipeline & Coordinate Mapping', () {
    late PdfiumEngine pdfEngine;
    const nativePdfPath = 'test/fixtures/doc_french.pdf';

    setUp(() {
      pdfEngine = PdfiumEngine();
    });

    tearDown(() {
      pdfEngine.dispose();
    });

    test('extractTextFromPdfPage preserves native PDF text without invoking OCR', () async {
      bool ocrInvoked = false;
      final mockEngine = PaddleOcrEngineMock();
      final service = OcrService(mockEngine);

      final blocks = await service.extractTextFromPdfPage(
        pdfEngine: pdfEngine,
        pdfPath: nativePdfPath,
        pageIndex: 1,
        mode: OcrMode.auto,
      );

      expect(blocks, isNotEmpty);
      expect(ocrInvoked, isFalse, reason: 'OCR must not trigger when native text is available');
      expect(blocks.first.pageNumber, 1);
    });

    test('extractTextFromPdfPage correctly falls back to OCR when page has no native text', () async {
      final mockEngine = PaddleOcrEngineMock();
      final service = OcrService(mockEngine);

      // Create an empty synthetic 1-page PDF file with 0 text operators
      final tempDir = Directory.systemTemp;
      final scannedPdf = File('${tempDir.path}/scanned_synthetic.pdf');
      await scannedPdf.writeAsString(
        '%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'
        '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'
        '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R >>\nendobj\n'
        '4 0 obj\n<< /Length 0 >>\nstream\nendstream\nendobj\n'
        'xref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n'
        '0000000115 00000 n \n0000000206 00000 n \n'
        'trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n256\n%%EOF\n',
      );

      try {
        final progressEvents = <OcrProgress>[];
        final blocks = await service.extractTextFromPdfPage(
          pdfEngine: pdfEngine,
          pdfPath: scannedPdf.path,
          pageIndex: 1,
          dpi: 150,
          mode: OcrMode.arabic,
          onProgress: (p) => progressEvents.add(p),
        );

        expect(blocks, isNotEmpty, reason: 'OCR fallback must extract text from raster/scanned page');
        expect(progressEvents, isNotEmpty);
        expect(blocks.first.pageNumber, 1);
        expect(blocks.first.x, greaterThanOrEqualTo(0));
        expect(blocks.first.y, greaterThanOrEqualTo(0));
      } finally {
        if (await scannedPdf.exists()) {
          await scannedPdf.delete();
        }
      }
    });

    test('Cancellation token halts extractTextFromPdfPage before execution', () async {
      final mockEngine = PaddleOcrEngineMock();
      final service = OcrService(mockEngine);
      final token = OcrCancellationToken()..cancel();

      expect(
        () => service.extractTextFromPdfPage(
          pdfEngine: pdfEngine,
          pdfPath: nativePdfPath,
          pageIndex: 1,
          cancellationToken: token,
        ),
        throwsA(isA<OcrCancelledException>()),
      );
    });
  });

  group('Phase 5.6: Multilingual BiDi & Arabic/French Text Normalization', () {
    test('BidiNormalizer preserves logical Arabic and mixed French tokens without reversal', () {
      const arabicPhrase = 'الجمهورية الجزائرية الديمقراطية';
      expect(BidiNormalizer.containsArabic(arabicPhrase), isTrue);
      expect(BidiNormalizer.isPredominantlyArabic(arabicPhrase), isTrue);

      final normalized = BidiNormalizer.normalizeText(arabicPhrase);
      expect(normalized, arabicPhrase, reason: 'Logical Unicode order must not be naively reversed');

      const mixedPhrase = 'Facture N 1042 لمؤسسة الأمل';
      expect(BidiNormalizer.containsArabic(mixedPhrase), isTrue);
      final normalizedMixed = BidiNormalizer.normalizeText(mixedPhrase);
      expect(normalizedMixed, mixedPhrase);
    });

    test('OcrCoordinateMapper accurately transforms pixel BBoxes to PDF Point Space', () {
      const pageResult = OcrPageResult(
        pageIndex: 1,
        imageWidth: 1240,
        imageHeight: 1754,
        processingTimeMs: 120,
        engineUsed: 'PaddleOCR',
        isRightToLeft: false,
        blocks: [
          OcrBlock(
            id: 'block_1',
            text: 'Titre Document',
            confidence: 0.99,
            boundingBox: OcrBoundingBox(left: 124, top: 175, width: 400, height: 50),
            language: 'fr',
            lines: [],
          ),
        ],
      );

      final pdfBlocks = OcrCoordinateMapper.toTextBlocks(
        pageResult: pageResult,
        pageHeightPt: 842.0,
        pageWidthPt: 595.0,
        dpi: 150,
      );

      expect(pdfBlocks.length, 1);
      final block = pdfBlocks.first;
      expect(block.text, 'Titre Document');
      expect(block.pageNumber, 1);
      expect(block.x, closeTo(124.0 * (72.0 / 150.0), 0.5));
      expect(block.width, closeTo(400.0 * (72.0 / 150.0), 0.5));
      expect(block.confidence, 0.99);
    });
  });

  group('Phase 5.6: Sovereign Word Converter OCR Integration', () {
    late PdfiumEngine pdfEngine;
    late SovereignPdfToWordConverter converter;

    setUp(() {
      pdfEngine = PdfiumEngine();
      final mockOcr = PaddleOcrEngineMock();
      final ocrService = OcrService(mockOcr);
      converter = SovereignPdfToWordConverter(
        pdfEngine: pdfEngine,
        ocrService: ocrService,
      );
    });

    tearDown(() {
      pdfEngine.dispose();
    });

    test('SovereignPdfToWordConverter converts native PDF without invoking OCR', () async {
      final tempDir = Directory.systemTemp;
      final outPath = '${tempDir.path}/out_native.docx';

      final result = await converter.convertPdfToWord(
        'test/fixtures/doc_french.pdf',
        outPath,
        options: const ConversionOptions(ocrScannedPages: false),
      );

      expect(result, outPath);
      final outFile = File(outPath);
      expect(await outFile.exists(), isTrue);

      final bytes = await outFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.findFile('word/document.xml'), isNotNull);

      await outFile.delete();
    });

    test('SovereignPdfToWordConverter handles scanned PDF with ocrScannedPages enabled', () async {
      final tempDir = Directory.systemTemp;
      final scannedPdf = File('${tempDir.path}/scanned_empty.pdf');
      final outPath = '${tempDir.path}/out_scanned.docx';

      await scannedPdf.writeAsString(
        '%PDF-1.4\n1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n'
        '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n'
        '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R >>\nendobj\n'
        '4 0 obj\n<< /Length 0 >>\nstream\nendstream\nendobj\n'
        'xref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n'
        '0000000115 00000 n \n0000000206 00000 n \n'
        'trailer\n<< /Size 5 /Root 1 0 R >>\nstartxref\n256\n%%EOF\n',
      );

      try {
        final result = await converter.convertPdfToWord(
          scannedPdf.path,
          outPath,
          options: const ConversionOptions(
            ocrScannedPages: true,
            ocrMode: OcrMode.arabic,
          ),
        );

        expect(result, outPath);
        final outFile = File(outPath);
        expect(await outFile.exists(), isTrue);

        final bytes = await outFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        final docXml = archive.findFile('word/document.xml');
        expect(docXml, isNotNull);

        await outFile.delete();
      } finally {
        if (await scannedPdf.exists()) {
          await scannedPdf.delete();
        }
      }
    });
  });
}
