import '../../../shared/models/document.dart';
import '../../../shared/models/page_model.dart';

abstract class PdfEngine {
  Future<DocumentModel> inspect(String filePath);
  Future<List<PageModel>> getPages(String filePath);
  Future<String> extractText(String filePath, int pageNumber);
  Future<List<int>> renderPage(String filePath, int pageNumber, {int dpi = 150});
  Future<String> merge(List<String> filePaths, String outputFilePath);
  Future<List<String>> split(String filePath, List<int> pages, String outputDir);
  Future<String> clean(String filePath, String outputFilePath);
  Future<String> compress(String filePath, String outputFilePath, {int quality = 80});
  Future<String> exportPdf(String filePath, String outputFilePath, String format);
}

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
  Future<List<int>> renderPage(String filePath, int pageNumber, {int dpi = 150}) async {
    return <int>[];
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
