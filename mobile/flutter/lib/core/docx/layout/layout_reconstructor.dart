import 'dart:math';
import 'dart:typed_data';
import '../../ocr/bidi_normalizer.dart';
import '../../../shared/models/image_block.dart';
import '../../../shared/models/page_model.dart';
import '../../../shared/models/table_block.dart';
import '../../../shared/models/text_block.dart';
import '../ooxml_units.dart';
import 'docx_elements.dart';

/// Heuristic layout reconstructor transforming spatial document blocks
/// into semantic DOCX flow elements (paragraphs, headings, tables, images).
class LayoutReconstructor {
  /// Reconstructs a list of [DocxElement]s for a given page.
  static List<DocxElement> reconstructPage({
    required PageModel page,
    required List<TextBlock> textBlocks,
    List<ImageBlock> imageBlocks = const [],
    List<TableBlock> tableBlocks = const [],
  }) {
    final List<DocxElement> elements = [];

    // Separate text blocks that belong inside tables
    final tableBlockIds = <String>{};
    for (final tbl in tableBlocks) {
      final docxTable = _reconstructTable(tbl, textBlocks);
      elements.add(docxTable);

      // Collect IDs of text blocks consumed by this table
      final tblLeft = tbl.x;
      final tblRight = tbl.x + tbl.width;
      final tblBottom = tbl.y;
      final tblTop = tbl.y + tbl.height;

      for (final tb in textBlocks) {
        if (tb.x >= tblLeft - 5 &&
            (tb.x + tb.width) <= tblRight + 5 &&
            tb.y >= tblBottom - 5 &&
            (tb.y + tb.height) <= tblTop + 5) {
          tableBlockIds.add(tb.id);
        }
      }
    }

    // Filter out text blocks that are inside tables
    final nonTableBlocks = textBlocks.where((b) => !tableBlockIds.contains(b.id)).toList();

    // Check for multi-column layout
    final columns = _detectColumns(page.width, nonTableBlocks);

    for (final columnBlocks in columns) {
      final paragraphs = _reconstructParagraphs(columnBlocks, page.width);
      elements.addAll(paragraphs);
    }

    // Add standalone image blocks
    for (final img in imageBlocks) {
      elements.add(
        DocxImage(
          bytes: img.source.codeUnits.isNotEmpty
              ? Uint8List.fromList(img.source.codeUnits)
              : Uint8List(0),
          widthPt: img.width > 0 ? img.width : 200.0,
          heightPt: img.height > 0 ? img.height : 150.0,
          altText: 'Image ${img.id}',
        ),
      );
    }

    return elements;
  }

  /// Detects vertical columns on a page based on X-coordinates and white valleys.
  static List<List<TextBlock>> _detectColumns(double pageWidth, List<TextBlock> blocks) {
    if (blocks.length < 4) {
      return [blocks];
    }

    // Sort blocks by X coordinate
    final sortedByX = List<TextBlock>.from(blocks)
      ..sort((a, b) => a.x.compareTo(b.x));

    // Look for a significant vertical gutter (white valley) around page center
    final minGutterWidth = 20.0;
    final centerMin = pageWidth * 0.35;
    final centerMax = pageWidth * 0.65;

    double maxGutter = 0.0;
    double gutterSplitX = 0.0;

    for (int i = 0; i < sortedByX.length - 1; i++) {
      final currentRight = sortedByX[i].x + sortedByX[i].width;
      final nextLeft = sortedByX[i + 1].x;
      final gap = nextLeft - currentRight;

      if (gap >= minGutterWidth && currentRight >= centerMin && nextLeft <= centerMax) {
        if (gap > maxGutter) {
          maxGutter = gap;
          gutterSplitX = currentRight + gap / 2.0;
        }
      }
    }

    if (maxGutter >= minGutterWidth && gutterSplitX > 0) {
      final leftCol = <TextBlock>[];
      final rightCol = <TextBlock>[];

      for (final b in blocks) {
        if (b.x + b.width / 2.0 < gutterSplitX) {
          leftCol.add(b);
        } else {
          rightCol.add(b);
        }
      }

      // Check if document is predominantly Arabic (RTL reading order for columns)
      final allText = blocks.map((b) => b.text).join(' ');
      if (BidiNormalizer.isPredominantlyArabic(allText)) {
        return [rightCol, leftCol];
      } else {
        return [leftCol, rightCol];
      }
    }

    return [blocks];
  }

  /// Groups spatial text blocks into coherent paragraphs and runs.
  static List<DocxParagraph> _reconstructParagraphs(List<TextBlock> blocks, double pageWidth) {
    if (blocks.isEmpty) return const [];

    // Sort top-to-bottom:
    // In PDF point coordinates, higher Y is top of page.
    final sorted = List<TextBlock>.from(blocks)..sort((a, b) {
      final diffY = (b.y - a.y).abs();
      if (diffY > 4.0) {
        return b.y.compareTo(a.y); // Higher Y first
      }
      return a.x.compareTo(b.x); // Left-to-right on same line
    });

    final List<DocxParagraph> paragraphs = [];
    final List<TextBlock> currentParagraphBlocks = [sorted.first];

    for (int i = 1; i < sorted.length; i++) {
      final prev = currentParagraphBlocks.last;
      final curr = sorted[i];

      // Estimate line height
      final estHeight = max(prev.height, 10.0);
      final deltaY = prev.y - curr.y;

      // Check if current block continues the previous paragraph
      final isSameParagraph = deltaY >= -2.0 && deltaY <= estHeight * 1.6;

      if (isSameParagraph) {
        currentParagraphBlocks.add(curr);
      } else {
        paragraphs.add(_buildParagraph(currentParagraphBlocks, pageWidth));
        currentParagraphBlocks.clear();
        currentParagraphBlocks.add(curr);
      }
    }

    if (currentParagraphBlocks.isNotEmpty) {
      paragraphs.add(_buildParagraph(currentParagraphBlocks, pageWidth));
    }

    return paragraphs;
  }

  /// Builds a [DocxParagraph] from clustered [TextBlock]s.
  static DocxParagraph _buildParagraph(List<TextBlock> blocks, double pageWidth) {
    final fullText = blocks.map((b) => b.text).join(' ').trim();
    final isArabic = BidiNormalizer.containsArabic(fullText);
    final isPredominantlyArabic = BidiNormalizer.isPredominantlyArabic(fullText);

    // Calculate average font size and dimensions
    double totalH = 0.0;
    double minX = double.infinity;
    double maxX = 0.0;

    for (final b in blocks) {
      totalH += b.height;
      if (b.x < minX) minX = b.x;
      if (b.x + b.width > maxX) maxX = b.x + b.width;
    }

    final avgHeight = blocks.isNotEmpty ? totalH / blocks.length : 12.0;
    final spanWidth = maxX - minX;

    // Heading detection
    String styleId = 'Normal';
    bool isHeading = false;
    if (fullText.length <= 90 && blocks.length <= 2) {
      if (avgHeight >= 18.0) {
        styleId = 'Heading1';
        isHeading = true;
      } else if (avgHeight >= 14.0) {
        styleId = 'Heading2';
        isHeading = true;
      } else if (avgHeight >= 12.5 && !fullText.endsWith('.')) {
        styleId = 'Heading3';
        isHeading = true;
      }
    }

    // Alignment detection
    DocxAlignment alignment;
    final centerTolerance = 25.0;
    final blockCenterX = minX + spanWidth / 2.0;
    final pageCenterX = pageWidth / 2.0;

    if (isHeading && (blockCenterX - pageCenterX).abs() < centerTolerance) {
      alignment = DocxAlignment.center;
    } else if (isPredominantlyArabic) {
      alignment = DocxAlignment.right;
    } else if (spanWidth > pageWidth * 0.70) {
      alignment = DocxAlignment.justify;
    } else {
      alignment = DocxAlignment.left;
    }

    // List detection
    bool isList = false;
    int indentTwips = 0;
    final listPattern = RegExp(r'^([•\-\*▪]|\d+[\.\)]|[a-zA-Z][\.\)]|[٠-٩]+[\.\-])\s+');
    if (listPattern.hasMatch(fullText)) {
      isList = true;
      indentTwips = 360; // 0.25 inch hanging indent
    }

    // Construct runs with Arabic / BiDi support
    final List<DocxRun> runs = [];
    final tokens = fullText.split(' ');

    // Group adjacent words with same language/script
    String currentSegment = '';
    bool currentSegmentIsArabic = false;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final tokenIsArabic = BidiNormalizer.containsArabic(token);

      if (currentSegment.isEmpty) {
        currentSegment = token;
        currentSegmentIsArabic = tokenIsArabic;
      } else if (currentSegmentIsArabic == tokenIsArabic) {
        currentSegment += ' $token';
      } else {
        // Emit run
        runs.add(
          _createRun(
            text: currentSegment,
            isArabic: currentSegmentIsArabic,
            fontSizePt: avgHeight,
            isBold: isHeading,
          ),
        );
        currentSegment = ' $token';
        currentSegmentIsArabic = tokenIsArabic;
      }
    }

    if (currentSegment.isNotEmpty) {
      runs.add(
        _createRun(
          text: currentSegment,
          isArabic: currentSegmentIsArabic,
          fontSizePt: avgHeight,
          isBold: isHeading,
        ),
      );
    }

    return DocxParagraph(
      runs: runs,
      alignment: alignment,
      isRtl: isArabic,
      styleId: styleId,
      isList: isList,
      indentTwips: indentTwips,
      spacingBeforeTwips: isHeading ? 180 : 0,
      spacingAfterTwips: isHeading ? 100 : 140,
    );
  }

  static DocxRun _createRun({
    required String text,
    required bool isArabic,
    required double fontSizePt,
    bool isBold = false,
  }) {
    return DocxRun(
      text: BidiNormalizer.normalizeText(text),
      isBold: isBold,
      fontSizePt: fontSizePt,
      isRtl: isArabic,
      fontFamily: isArabic ? 'Calibri' : 'Calibri',
      csFontFamily: isArabic ? 'Traditional Arabic' : null,
    );
  }

  /// Reconstructs a [DocxTable] from a [TableBlock] and internal text blocks.
  static DocxTable _reconstructTable(TableBlock tbl, List<TextBlock> allBlocks) {
    final tblLeft = tbl.x;
    final tblRight = tbl.x + tbl.width;
    final tblBottom = tbl.y;
    final tblTop = tbl.y + tbl.height;

    // Filter text blocks inside the table box
    final inside = allBlocks.where((b) {
      return b.x >= tblLeft - 5 &&
          (b.x + b.width) <= tblRight + 5 &&
          b.y >= tblBottom - 5 &&
          (b.y + b.height) <= tblTop + 5;
    }).toList();

    final numRows = max(1, tbl.rows);
    final numCols = max(1, tbl.columns);
    final colWidthPt = tbl.width / numCols;
    final colWidthTwips = OoxmlUnits.pointsToTwips(colWidthPt);

    final gridCols = List.filled(numCols, colWidthTwips);

    // Group blocks into cells based on coordinates
    final rowHeightPt = tbl.height / numRows;
    final matrix = List.generate(numRows, (_) => List.generate(numCols, (_) => <TextBlock>[]));

    for (final b in inside) {
      final relX = (b.x - tblLeft).clamp(0.0, tbl.width - 1.0);
      final relY = (tblTop - (b.y + b.height)).clamp(0.0, tbl.height - 1.0);

      final colIdx = (relX / colWidthPt).floor().clamp(0, numCols - 1);
      final rowIdx = (relY / rowHeightPt).floor().clamp(0, numRows - 1);

      matrix[rowIdx][colIdx].add(b);
    }

    final tableRows = <DocxTableRow>[];

    for (int r = 0; r < numRows; r++) {
      final cells = <DocxTableCell>[];
      for (int c = 0; c < numCols; c++) {
        final cellBlocks = matrix[r][c];
        final cellText = cellBlocks.map((cb) => cb.text).join(' ').trim();
        final isAr = BidiNormalizer.containsArabic(cellText);

        final p = DocxParagraph(
          runs: [
            DocxRun(
              text: cellText.isNotEmpty ? BidiNormalizer.normalizeText(cellText) : ' ',
              isRtl: isAr,
              csFontFamily: isAr ? 'Traditional Arabic' : null,
            ),
          ],
          alignment: isAr ? DocxAlignment.right : DocxAlignment.left,
          isRtl: isAr,
          spacingAfterTwips: 0,
        );

        cells.add(
          DocxTableCell(
            paragraphs: [p],
            widthTwips: colWidthTwips,
          ),
        );
      }
      tableRows.add(DocxTableRow(cells: cells, isHeader: r == 0));
    }

    return DocxTable(
      rows: tableRows,
      gridColTwips: gridCols,
      isRtl: tableRows.isNotEmpty && tableRows.first.cells.any((c) => c.paragraphs.any((p) => p.isRtl)),
      hasBorders: true,
    );
  }
}
