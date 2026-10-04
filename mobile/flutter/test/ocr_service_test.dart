import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/ocr/ocr_models.dart';
import 'package:morphpdf/features/ocr/data/ocr_engines_mock.dart';
import 'package:morphpdf/features/ocr/domain/ocr_service.dart';

void main() {
  group('OcrService Sequential & Cancellation Tests', () {
    test('Sequential processing N=1 with progress updates', () async {
      final engine = PaddleOcrEngineMock();
      final service = OcrService(engine);

      final progressList = <OcrProgress>[];
      final pages = ['/tmp/page1.png', '/tmp/page2.png', '/tmp/page3.png'];

      final results = await service.processDocument(
        pageImagePaths: pages,
        mode: OcrMode.auto,
        onProgress: (p) => progressList.add(p),
      );

      expect(results.length, 3);
      expect(results[0].pageIndex, 1);
      expect(results[1].pageIndex, 2);
      expect(results[2].pageIndex, 3);
      expect(progressList, isNotEmpty);
      expect(progressList.last.percentage, 100);
    });

    test('Cancellation token halts sequential document processing', () async {
      final engine = PaddleOcrEngineMock();
      final service = OcrService(engine);

      final token = OcrCancellationToken();
      final pages = ['/tmp/p1.png', '/tmp/p2.png', '/tmp/p3.png'];

      expect(
        () => service.processDocument(
          pageImagePaths: pages,
          cancellationToken: token,
          onProgress: (p) {
            if (p.currentPage == 1) {
              token.cancel();
            }
          },
        ),
        throwsA(isA<OcrCancelledException>()),
      );
    });

    test('mapToPdfTextBlocks converts OcrPageResult to TextBlocks', () async {
      final engine = PaddleOcrEngineMock();
      final service = OcrService(engine);

      final pageResult = await service.processPage(
        imagePath: '/tmp/arabic_doc.png',
        pageIndex: 1,
        mode: OcrMode.arabic,
      );

      final textBlocks = service.mapToPdfTextBlocks(
        pageResult,
        pageHeightPt: 842.0,
        dpi: 150,
      );

      expect(textBlocks, isNotEmpty);
      expect(textBlocks.first.pageNumber, 1);
      expect(textBlocks.first.language, 'ar');
    });
  });
}
