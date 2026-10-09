import 'dart:io';

import '../../../core/docx/layout/docx_elements.dart';
import '../../../core/docx/layout/layout_reconstructor.dart';
import '../../../core/docx/ooxml_package.dart';
import '../../../core/pdf/pdf_exceptions.dart';
import '../../../core/pdf/pdfium/pdfium_engine.dart';
import '../../../shared/models/text_block.dart';
import '../../ocr/domain/ocr_service.dart';
import '../domain/conversion_converter.dart';

/// Production sovereign PDF to Word (.docx) converter generating valid ECMA-376 packages
/// directly from native PDFium text extractions and spatial layout reconstruction.
class SovereignPdfToWordConverter implements PdfToWordConverter {
  final PdfiumEngine _pdfEngine;
  final OcrService? ocrService;

  SovereignPdfToWordConverter({
    PdfiumEngine? pdfEngine,
    this.ocrService,
  })  : _pdfEngine = pdfEngine ?? PdfiumEngine();

  @override
  String get converterName => 'MorphPDF Sovereign OOXML Converter';

  @override
  Future<String> convertPdfToWord(
    String pdfPath,
    String outputDocxPath, {
    ConversionOptions options = const ConversionOptions(),
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      throw PdfFileNotFoundException(pdfPath);
    }

    final inspection = await _pdfEngine.inspect(pdfPath);
    final pages = await _pdfEngine.getPages(pdfPath);
    final sections = <DocxSection>[];

    // Extract raw text blocks per page
    final allPagesBlocks = <List<TextBlock>>[];
    for (int i = 0; i < pages.length; i++) {
      final pageNum = i + 1;
      List<TextBlock> textBlocks = const [];
      try {
        textBlocks = await _pdfEngine.extractTextBlocks(pdfPath, pageNum);
      } catch (_) {
        textBlocks = const [];
      }

      // If page is scanned / image-only (0 native text blocks) and OCR is requested:
      final activeOcr = ocrService;
      if (textBlocks.isEmpty && options.ocrScannedPages && activeOcr != null) {
        try {
          textBlocks = await activeOcr.extractTextFromPdfPage(
            pdfEngine: _pdfEngine,
            pdfPath: pdfPath,
            pageIndex: pageNum,
            dpi: 150,
            mode: options.ocrMode,
          );
        } catch (_) {
          textBlocks = const [];
        }
      }

      allPagesBlocks.add(textBlocks);
    }

    // Detect repetitive headers & footers across multi-page document
    final headerFooterResult = LayoutReconstructor.detectHeadersAndFooters(
      pages: pages,
      pagesBlocks: allPagesBlocks,
    );

    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final textBlocks = headerFooterResult.filteredPagesBlocks[i];

      final elements = LayoutReconstructor.reconstructPage(
        page: page,
        textBlocks: textBlocks,
      );

      final isLandscape = page.width > page.height;
      sections.add(
        DocxSection(
          pageWidthPt: page.width,
          pageHeightPt: page.height,
          isLandscape: isLandscape,
          header: headerFooterResult.header,
          footer: headerFooterResult.footer,
          elements: elements,
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        DocxSection(
          pageWidthPt: inspection.defaultWidth,
          pageHeightPt: inspection.defaultHeight,
          elements: const [],
        ),
      );
    }

    await OoxmlPackage.saveDocxToFile(
      sections: sections,
      outputPath: outputDocxPath,
    );

    return outputDocxPath;
  }
}
