import 'dart:io';

import '../../../core/docx/layout/docx_elements.dart';
import '../../../core/docx/layout/layout_reconstructor.dart';
import '../../../core/docx/ooxml_package.dart';
import '../../../core/pdf/pdf_exceptions.dart';
import '../../../core/pdf/pdfium/pdfium_engine.dart';
import '../../../shared/models/text_block.dart';
import '../domain/conversion_converter.dart';

/// Production sovereign PDF to Word (.docx) converter generating valid ECMA-376 packages
/// directly from native PDFium text extractions and spatial layout reconstruction.
class SovereignPdfToWordConverter implements PdfToWordConverter {
  final PdfiumEngine _pdfEngine;

  SovereignPdfToWordConverter({PdfiumEngine? pdfEngine})
      : _pdfEngine = pdfEngine ?? PdfiumEngine();

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

    for (int i = 0; i < pages.length; i++) {
      final pageNum = i + 1;
      final page = pages[i];

      List<TextBlock> textBlocks = const [];
      try {
        textBlocks = await _pdfEngine.extractTextBlocks(pdfPath, pageNum);
      } catch (_) {
        textBlocks = const [];
      }

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
