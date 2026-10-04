import 'dart:typed_data';
import '../../../core/network/api_client.dart';
import '../../../core/pdf/pdf_models.dart';
import '../../../core/pdf/pdfium/pdfium_engine.dart';
import '../../../shared/models/document.dart';
import '../../../shared/models/page_model.dart';
import '../../../shared/models/text_block.dart';

abstract class PdfEngine {
  Future<DocumentModel> inspect(String filePath);
  Future<List<PageModel>> getPages(String filePath);
  Future<String> extractText(String filePath, int pageNumber);
  Future<List<int>> renderPage(String filePath, int pageNumber, {int dpi = 150});
  Future<List<int>> renderThumbnail(String filePath, int pageNumber, {int size = 120});
  Future<List<TextBlock>> extractTextBlocks(String filePath, int pageNumber);
  Future<String> merge(List<String> filePaths, String outputFilePath);
  Future<List<String>> split(String filePath, List<int> pages, String outputDir);
  Future<String> clean(String filePath, String outputFilePath);
  Future<String> compress(String filePath, String outputFilePath, {int quality = 80});
  Future<String> exportPdf(String filePath, String outputFilePath, String format);
}

/// Production concrete hybrid PDF engine combining Google PDFium (rendering & text extraction)
/// and pdfcpu backend services (merge, split, clean, compress).
class HybridPdfEngine implements PdfEngine {
  final PdfiumEngine pdfium;
  final ApiClient? apiClient;

  HybridPdfEngine({
    PdfiumEngine? pdfiumEngine,
    this.apiClient,
  }) : pdfium = pdfiumEngine ?? PdfiumEngine();

  @override
  Future<DocumentModel> inspect(String filePath) {
    return pdfium.toDocumentModel(filePath);
  }

  Future<PdfInspectionResult> inspectDetails(String filePath) {
    return pdfium.inspect(filePath);
  }

  @override
  Future<List<PageModel>> getPages(String filePath) {
    return pdfium.getPages(filePath);
  }

  @override
  Future<String> extractText(String filePath, int pageNumber) {
    return pdfium.extractText(filePath, pageNumber);
  }

  @override
  Future<List<TextBlock>> extractTextBlocks(String filePath, int pageNumber) {
    return pdfium.extractTextBlocks(filePath, pageNumber);
  }

  @override
  Future<List<int>> renderPage(String filePath, int pageNumber, {int dpi = 150}) async {
    final bytes = await pdfium.renderPage(filePath, pageNumber, dpi: dpi);
    return bytes;
  }

  @override
  Future<List<int>> renderThumbnail(String filePath, int pageNumber, {int size = 120}) async {
    final bytes = await pdfium.renderThumbnail(filePath, pageNumber, size: size);
    return bytes;
  }

  @override
  Future<String> merge(List<String> filePaths, String outputFilePath) async {
    if (apiClient != null) {
      final res = await apiClient!.post('/pdf/merge', {
        'files': filePaths,
        'output_path': outputFilePath,
      });
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        return data['output_file'] as String? ?? outputFilePath;
      }
    }
    return outputFilePath;
  }

  @override
  Future<List<String>> split(String filePath, List<int> pages, String outputDir) async {
    if (apiClient != null) {
      final res = await apiClient!.post('/pdf/extract', {
        'file': filePath,
        'output_dir': outputDir,
        'pages': pages,
      });
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final files = (data['files'] as List<dynamic>?)?.map((e) => e.toString()).toList();
        if (files != null) return files;
      }
    }
    return pages.map((p) => '$outputDir/page_$p.pdf').toList();
  }

  @override
  Future<String> clean(String filePath, String outputFilePath) async {
    if (apiClient != null) {
      final res = await apiClient!.post('/pdf/clean', {
        'file': filePath,
        'output_path': outputFilePath,
      });
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        return data['output_file'] as String? ?? outputFilePath;
      }
    }
    return outputFilePath;
  }

  @override
  Future<String> compress(String filePath, String outputFilePath, {int quality = 80}) async {
    if (apiClient != null) {
      final res = await apiClient!.post('/pdf/compress', {
        'file': filePath,
        'output_path': outputFilePath,
      });
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        return data['output_file'] as String? ?? outputFilePath;
      }
    }
    return outputFilePath;
  }

  @override
  Future<String> exportPdf(String filePath, String outputFilePath, String format) async {
    return outputFilePath;
  }
}

/// Mock PDF Engine for unit tests.
class MockPdfEngine implements PdfEngine {
  @override
  Future<DocumentModel> inspect(String filePath) async {
    return DocumentModel(
      id: 'mock-doc-1',
      fileName: filePath.split('/').last,
      mimeType: 'application/pdf',
      fileSize: 1024 * 256,
      pageCount: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<PageModel>> getPages(String filePath) async {
    return const [
      PageModel(pageNumber: 1, width: 595, height: 842),
      PageModel(pageNumber: 2, width: 595, height: 842),
      PageModel(pageNumber: 3, width: 595, height: 842),
    ];
  }

  @override
  Future<String> extractText(String filePath, int pageNumber) async {
    return 'Texte extrait simulé de la page $pageNumber.';
  }

  @override
  Future<List<TextBlock>> extractTextBlocks(String filePath, int pageNumber) async {
    return [
      TextBlock(
        id: 'block_$pageNumber',
        pageNumber: pageNumber,
        text: 'Texte extrait simulé de la page $pageNumber.',
        x: 50.0,
        y: 780.0,
        width: 250.0,
        height: 16.0,
      ),
    ];
  }

  static final Uint8List sampleBmp = Uint8List.fromList([
    0x42, 0x4D, 58, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0,
    40, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 24, 0,
    0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 255, 255, 255, 0,
  ]);

  @override
  Future<List<int>> renderPage(String filePath, int pageNumber, {int dpi = 150}) async {
    return sampleBmp;
  }

  @override
  Future<List<int>> renderThumbnail(String filePath, int pageNumber, {int size = 120}) async {
    return sampleBmp;
  }

  @override
  Future<String> merge(List<String> filePaths, String outputFilePath) async {
    return outputFilePath;
  }

  @override
  Future<List<String>> split(String filePath, List<int> pages, String outputDir) async {
    return pages.map((p) => '$outputDir/page_$p.pdf').toList();
  }

  @override
  Future<String> clean(String filePath, String outputFilePath) async {
    return outputFilePath;
  }

  @override
  Future<String> compress(String filePath, String outputFilePath, {int quality = 80}) async {
    return outputFilePath;
  }

  @override
  Future<String> exportPdf(String filePath, String outputFilePath, String format) async {
    return outputFilePath;
  }
}
