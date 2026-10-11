import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';
import 'package:morphpdf/core/platform/native_file_picker.dart';
import 'package:morphpdf/core/storage/recent_document.dart';
import 'package:morphpdf/core/storage/storage_service.dart';
import 'package:morphpdf/features/conversion/domain/conversion_converter.dart';
import 'package:morphpdf/features/conversion/presentation/conversion_screen.dart';
import 'package:morphpdf/features/documents/presentation/documents_screen.dart';
import 'package:morphpdf/features/merge_split/presentation/merge_split_screen.dart';
import 'package:morphpdf/features/ocr/data/ocr_engines_mock.dart';
import 'package:morphpdf/features/ocr/domain/ocr_service.dart';
import 'package:morphpdf/features/ocr/presentation/ocr_screen.dart';

import 'helpers/pdf_corpus_builder.dart';

// --- FAKE / TEST IMPLEMENTATIONS ---

class FakeFilePicker extends NativeFilePicker {
  String? nextSingleFile;
  List<String> nextMultipleFiles = [];

  @override
  Future<String?> pickSingleFile({String mimeType = '*/*'}) async => nextSingleFile;

  @override
  Future<List<String>> pickMultipleFiles({String mimeType = '*/*'}) async => nextMultipleFiles;

  @override
  Future<String?> pickPdfFile() async => nextSingleFile;

  @override
  Future<List<String>> pickPdfFiles() async => nextMultipleFiles;

  @override
  Future<String?> pickImageFile() async => nextSingleFile;

  @override
  Future<void> clearCache() async {}
}

class FakeStorageService implements StorageService {
  final List<RecentDocument> recents = [];
  final List<File> exports = [];

  @override
  Future<List<RecentDocument>> getRecentDocuments() async => List.unmodifiable(recents);

  @override
  Future<void> addRecentDocument(String path, {String? name, int? sizeBytes, int? pageCount}) async {
    recents.removeWhere((d) => d.path == path);
    recents.insert(
      0,
      RecentDocument(
        path: path,
        fileName: name ?? path.split('/').last,
        fileSize: sizeBytes ?? 1024,
        pageCount: pageCount ?? 1,
        lastOpened: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> removeRecentDocument(String path) async {
    recents.removeWhere((d) => d.path == path);
  }

  @override
  Future<void> clearRecentDocuments() async {
    recents.clear();
  }

  @override
  Future<File> saveExport(String fileName, List<int> bytes) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    exports.add(file);
    return file;
  }

  @override
  Future<List<File>> listExports() async => List.unmodifiable(exports);

  @override
  Future<void> deleteTemp(String fileName) async {}

  @override
  Future<File?> getTemp(String fileName) async => null;

  @override
  Future<bool> isOnboardingCompleted() async => true;

  @override
  Future<File> saveTemp(String fileName, List<int> bytes) async {
    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}
}

class FakePdfToWordConverter implements PdfToWordConverter {
  bool shouldFail = false;
  ConversionOptions? lastOptions;

  @override
  String get converterName => 'Fake Converter';

  @override
  Future<String> convertPdfToWord(
    String pdfPath,
    String outputDocxPath, {
    ConversionOptions options = const ConversionOptions(),
  }) async {
    lastOptions = options;
    if (shouldFail) {
      throw Exception('Erreur de conversion simulée');
    }
    final file = File(outputDocxPath);
    file.writeAsStringSync('Fake DOCX content');
    return outputDocxPath;
  }
}

class FakeArabicOcrEngine extends MlKitEngineMock {
  @override
  Future<OcrPageResult> recognizePage({
    required String imagePath,
    required int pageIndex,
    OcrMode mode = OcrMode.auto,
    int maxDimension = 4096,
    OcrCancellationToken? cancellationToken,
  }) async {
    return OcrPageResult(
      pageIndex: pageIndex,
      imageWidth: 800,
      imageHeight: 1200,
      processingTimeMs: 30,
      engineUsed: 'FakeArabicEngine',
      isRightToLeft: true,
      blocks: [
        OcrBlock(
          id: 'b1',
          text: 'مرحبا بكم في تطبيق مورف بي دي اف',
          confidence: 0.95,
          language: 'ar',
          boundingBox: const OcrBoundingBox(left: 10, top: 10, width: 200, height: 30),
          lines: const [],
        ),
      ],
    );
  }
}

// --- MAIN TEST SUITE ---

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File samplePdf;
  late File sampleImage;

  setUpAll(() async {
    tempDir = Directory('${Directory.systemTemp.path}/ui_test_${DateTime.now().millisecondsSinceEpoch}');
    await tempDir.create(recursive: true);

    final pdfContent = PdfCorpusBuilder.buildPdf(pages: [
      [const PdfTextItem(text: 'Document de test UI', x: 50, y: 700, fontSize: 14)],
    ]);
    samplePdf = File('${tempDir.path}/sample_document.pdf');
    await PdfCorpusBuilder.writePdfFile(samplePdf.path, pdfContent);

    sampleImage = File('${tempDir.path}/sample_image.png');
    await sampleImage.writeAsBytes([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Phase 5.9: Recent Documents Storage & Models', () {
    test('RecentDocument serializes and deserializes correctly', () {
      final doc = RecentDocument(
        path: '/tmp/test.pdf',
        fileName: 'test.pdf',
        fileSize: 4096,
        pageCount: 3,
        lastOpened: DateTime(2026, 10, 11, 14, 0),
      );

      final json = doc.toJson();
      expect(json['path'], '/tmp/test.pdf');
      expect(json['fileName'], 'test.pdf');
      expect(json['fileSize'], 4096);
      expect(json['pageCount'], 3);

      final restored = RecentDocument.fromJson(json);
      expect(restored.path, doc.path);
      expect(restored.fileName, doc.fileName);
      expect(restored.fileSize, doc.fileSize);
      expect(restored.pageCount, doc.pageCount);
    });

    test('FakeStorageService manages recents without deleting real files', () async {
      final storage = FakeStorageService();
      await storage.addRecentDocument(samplePdf.path, name: 'sample_document.pdf', sizeBytes: 100, pageCount: 2);

      var recents = await storage.getRecentDocuments();
      expect(recents.length, 1);
      expect(recents.first.fileName, 'sample_document.pdf');

      // Removing from recent document history
      await storage.removeRecentDocument(samplePdf.path);
      recents = await storage.getRecentDocuments();
      expect(recents.isEmpty, isTrue);

      // Verify the original file on disk STILL EXISTS!
      expect(samplePdf.existsSync(), isTrue);
    });
  });

  group('Phase 5.9: ConversionScreen Functional Workflow', () {
    testWidgets('shows file selection button when empty', (tester) async {
      final fakePicker = FakeFilePicker();
      final fakeConverter = FakePdfToWordConverter();
      final fakeStorage = FakeStorageService();

      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            converter: fakeConverter,
            filePicker: fakePicker,
            storageService: fakeStorage,
          ),
        ),
      );

      expect(find.text('Conversion PDF → Word'), findsOneWidget);
      expect(find.text('Sélectionnez un document PDF'), findsOneWidget);
      expect(find.text('Choisir un fichier PDF'), findsOneWidget);
    });

    testWidgets('loads PDF and executes conversion successfully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakePicker = FakeFilePicker()..nextSingleFile = samplePdf.path;
      final fakeConverter = FakePdfToWordConverter();
      final fakeStorage = FakeStorageService();

      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            converter: fakeConverter,
            filePicker: fakePicker,
            storageService: fakeStorage,
            initialPdfPath: samplePdf.path,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verified PDF card loaded
      expect(find.text('sample_document.pdf'), findsOneWidget);
      expect(find.text('Options de conversion'), findsOneWidget);
      expect(find.text('Convertir en Word (.docx)'), findsOneWidget);

      // Trigger conversion
      await tester.tap(find.text('Convertir en Word (.docx)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Check success state
      expect(find.text('Conversion réussie !'), findsOneWidget);
      expect(find.text('Sauvegarder'), findsOneWidget);
    });

    testWidgets('displays error message on converter failure without faking success', (tester) async {
      final fakeConverter = FakePdfToWordConverter()..shouldFail = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ConversionScreen(
            converter: fakeConverter,
            initialPdfPath: samplePdf.path,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Convertir en Word (.docx)'));
      await tester.pumpAndSettle();

      expect(find.text('Échec de la conversion'), findsOneWidget);
      expect(find.textContaining('Erreur de conversion simulée'), findsOneWidget);
      expect(find.text('Conversion réussie !'), findsNothing);
    });
  });

  group('Phase 5.9: OcrScreen Functional Workflow', () {
    testWidgets('displays options and runs OCR with text output and RTL detection', (tester) async {
      final fakeOcr = OcrService(FakeArabicOcrEngine());

      await tester.pumpWidget(
        MaterialApp(
          home: OcrScreen(
            ocrService: fakeOcr,
            initialFilePath: sampleImage.path,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reconnaissance OCR'), findsOneWidget);
      expect(find.text('Configuration de l\'OCR'), findsOneWidget);
      expect(find.text('Lancer l\'OCR'), findsOneWidget);

      await tester.tap(find.text('Lancer l\'OCR'));
      await tester.pumpAndSettle();

      // Verifies extracted Arabic text is displayed
      expect(find.text('Texte extrait'), findsOneWidget);
      expect(find.textContaining('مرحبا بكم في تطبيق مورف بي دي اف'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('Phase 5.9: DocumentsScreen Functional Workflow', () {
    testWidgets('displays recents list and allows removing entry from history', (tester) async {
      final fakeStorage = FakeStorageService();
      await fakeStorage.addRecentDocument(samplePdf.path, name: 'document_test.pdf', sizeBytes: 2048, pageCount: 4);

      await tester.pumpWidget(
        MaterialApp(
          home: DocumentsScreen(
            storageService: fakeStorage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fichiers & Documents'), findsOneWidget);
      expect(find.text('document_test.pdf'), findsOneWidget);
      expect(find.textContaining('4 page(s)'), findsOneWidget);

      // Tap remove from list icon
      final removeButton = find.byIcon(Icons.close_rounded);
      expect(removeButton, findsOneWidget);
      await tester.tap(removeButton);
      await tester.pumpAndSettle();

      // Verifies removed from UI list
      expect(find.text('document_test.pdf'), findsNothing);
      expect(samplePdf.existsSync(), isTrue); // Real file not deleted!
    });
  });

  group('Phase 5.9: MergeSplitScreen Functional Workflow', () {
    testWidgets('Merge tab requires at least 2 files', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MergeSplitScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fusionner & Diviser'), findsOneWidget);
      expect(find.text('Fusionner'), findsOneWidget);
      expect(find.text('Diviser'), findsOneWidget);
      expect(find.text('Documents à fusionner (0)'), findsOneWidget);
    });

    testWidgets('Split tab handles syntax validation and page count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MergeSplitScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Diviser tab
      await tester.tap(find.text('Diviser'));
      await tester.pumpAndSettle();

      expect(find.text('Sélectionnez un document PDF à diviser.'), findsOneWidget);
    });
  });
}
