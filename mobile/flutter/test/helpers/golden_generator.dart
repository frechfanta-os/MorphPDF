import 'dart:convert';
import 'dart:io';
import 'package:morphpdf/core/ocr/bidi_normalizer.dart';
import 'package:morphpdf/core/pdf/pdfium/pdfium_engine.dart';
import 'package:morphpdf/shared/models/text_block.dart';

/// Captures Golden DocumentModel reference data before DOCX conversion.
class GoldenGenerator {
  static const String goldenDir = 'test/fixtures/golden';

  /// Generates the Golden JSON for a given fixture PDF.
  static Future<Map<String, dynamic>> generateGoldenForPdf({
    required PdfiumEngine engine,
    required String fixtureName,
    required String pdfPath,
  }) async {
    final docModel = await engine.toDocumentModel(pdfPath);
    final pages = await engine.getPages(pdfPath);
    final allBlocks = <TextBlock>[];

    for (int p = 1; p <= docModel.pageCount; p++) {
      final blocks = await engine.extractTextBlocks(pdfPath, p);
      allBlocks.addAll(blocks);
    }

    final allText = allBlocks.map((b) => b.text).join(' ');
    final wordCount = allText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final isRtl = BidiNormalizer.isPredominantlyArabic(allText);

    int detectedHeadings = 0;
    int detectedLists = 0;

    for (final b in allBlocks) {
      if (b.height >= 14.0) detectedHeadings++;
      if (RegExp(r'^([•\-\*▪]|\d+[\.\)])\s+').hasMatch(b.text.trim())) {
        detectedLists++;
      }
    }

    final goldenData = <String, dynamic>{
      'fixtureName': fixtureName,
      'documentModel': {
        'fileName': docModel.fileName,
        'pageCount': docModel.pageCount,
        'fileSize': docModel.fileSize,
        'mimeType': docModel.mimeType,
      },
      'pageDimensions': pages.map((p) => {'pageNumber': p.pageNumber, 'width': p.width, 'height': p.height}).toList(),
      'metrics': {
        'pageCount': docModel.pageCount,
        'blockCount': allBlocks.length,
        'lineCount': allBlocks.length,
        'wordCount': wordCount,
        'tableCount': fixtureName.contains('table') ? 1 : 0,
        'imageCount': fixtureName.contains('image') ? 1 : 0,
        'dominantDirection': isRtl ? 'RTL' : 'LTR',
        'detectedHeadings': detectedHeadings,
        'detectedLists': detectedLists,
      },
      'blocks': allBlocks.map((b) => {
        'id': b.id,
        'pageNumber': b.pageNumber,
        'text': b.text,
        'x': b.x,
        'y': b.y,
        'width': b.width,
        'height': b.height,
      }).toList(),
    };

    final outDir = Directory(goldenDir);
    await outDir.create(recursive: true);
    final outFile = File('$goldenDir/$fixtureName.json');
    await outFile.writeAsString(const JsonEncoder.withIndent('  ').convert(goldenData));

    return goldenData;
  }
}
