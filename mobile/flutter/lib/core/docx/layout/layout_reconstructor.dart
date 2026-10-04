import 'dart:math';
import 'dart:typed_data';
import '../../ocr/bidi_normalizer.dart';
import '../../../shared/models/image_block.dart';
import '../../../shared/models/page_model.dart';
import '../../../shared/models/table_block.dart';
import '../../../shared/models/text_block.dart';
import '../ooxml_units.dart';
import 'docx_elements.dart';

/// Detection result for repetitive headers and footers across multi-page documents.
class HeaderFooterDetectionResult {
  final DocxHeader? header;
  final DocxFooter? footer;
  final List<List<TextBlock>> filteredPagesBlocks;

  const HeaderFooterDetectionResult({
    this.header,
    this.footer,
    required this.filteredPagesBlocks,
  });
}

/// Heuristic layout reconstructor transforming spatial document blocks
/// into semantic DOCX flow elements (paragraphs, headings, tables, images, lists, columns).
class LayoutReconstructor {
  /// Detects repetitive headers and footers across multiple pages.
  static HeaderFooterDetectionResult detectHeadersAndFooters({
    required List<PageModel> pages,
    required List<List<TextBlock>> pagesBlocks,
  }) {
    if (pages.length < 2 || pagesBlocks.length < 2) {
      return HeaderFooterDetectionResult(
        header: null,
        footer: null,
        filteredPagesBlocks: pagesBlocks,
      );
    }

    // Top threshold (top 8% in PDF coordinates where Y=height is top)
    // Bottom threshold (bottom 8% in PDF coordinates where Y=0 is bottom)
    final candidateHeaderTexts = <String, int>{};
    final candidateFooterTexts = <String, int>{};
    final headerBlockIds = <String>{};
    final footerBlockIds = <String>{};

    for (int i = 0; i < pages.length; i++) {
      final pageH = pages[i].height;
      final topYThreshold = pageH * 0.92;
      final bottomYThreshold = pageH * 0.08;
      final blocks = pagesBlocks[i];

      for (final b in blocks) {
        final trimmed = b.text.trim();
        if (trimmed.isEmpty) continue;

        if (b.y >= topYThreshold) {
          candidateHeaderTexts[trimmed] = (candidateHeaderTexts[trimmed] ?? 0) + 1;
        } else if (b.y <= bottomYThreshold) {
          // Normalize page numbers e.g. "Page 1" -> "Page N" or "1" -> "N"
          final isPageNum = RegExp(r'^(page\s+)?\d+(\s*/\s*\d+)?$', caseSensitive: false).hasMatch(trimmed);
          final key = isPageNum ? '__PAGE_NUM__' : trimmed;
          candidateFooterTexts[key] = (candidateFooterTexts[key] ?? 0) + 1;
        }
      }
    }

    // Check if any candidate appears in >= 2 pages
    String? detectedHeaderText;
    for (final entry in candidateHeaderTexts.entries) {
      if (entry.value >= 2) {
        detectedHeaderText = entry.key;
        break;
      }
    }

    String? detectedFooterText;
    bool footerIsPageNum = false;
    for (final entry in candidateFooterTexts.entries) {
      if (entry.value >= 2) {
        if (entry.key == '__PAGE_NUM__') {
          footerIsPageNum = true;
          detectedFooterText = 'Page';
        } else {
          detectedFooterText = entry.key;
        }
        break;
      }
    }

    // Mark blocks to filter out from body
    final filtered = <List<TextBlock>>[];
    for (int i = 0; i < pages.length; i++) {
      final pageH = pages[i].height;
      final topYThreshold = pageH * 0.92;
      final bottomYThreshold = pageH * 0.08;
      final pageFiltered = <TextBlock>[];

      for (final b in pagesBlocks[i]) {
        final trimmed = b.text.trim();
        if (detectedHeaderText != null && b.y >= topYThreshold && trimmed == detectedHeaderText) {
          headerBlockIds.add(b.id);
          continue;
        }
        if (detectedFooterText != null && b.y <= bottomYThreshold) {
          final isPageNum = RegExp(r'^(page\s+)?\d+(\s*/\s*\d+)?$', caseSensitive: false).hasMatch(trimmed);
          if (footerIsPageNum && isPageNum) {
            footerBlockIds.add(b.id);
            continue;
          } else if (trimmed == detectedFooterText) {
            footerBlockIds.add(b.id);
            continue;
          }
        }
        pageFiltered.add(b);
      }
      filtered.add(pageFiltered);
    }

    DocxHeader? header;
    if (detectedHeaderText != null) {
      final isAr = BidiNormalizer.containsArabic(detectedHeaderText);
      header = DocxHeader(
        paragraphs: [
          DocxParagraph(
            runs: [
              DocxRun(
                text: BidiNormalizer.normalizeText(detectedHeaderText),
                isRtl: isAr,
                fontSizePt: 9.0,
                colorHex: '7F7F7F',
                csFontFamily: isAr ? 'Traditional Arabic' : null,
              ),
            ],
            styleId: 'Header',
            alignment: isAr ? DocxAlignment.right : DocxAlignment.center,
            isRtl: isAr,
            spacingAfterTwips: 0,
          ),
        ],
      );
    }

    DocxFooter? footer;
    if (detectedFooterText != null) {
      final isAr = BidiNormalizer.containsArabic(detectedFooterText);
      footer = DocxFooter(
        paragraphs: [
          DocxParagraph(
            runs: [
              DocxRun(
                text: footerIsPageNum ? 'Page 1' : BidiNormalizer.normalizeText(detectedFooterText),
                isRtl: isAr,
                fontSizePt: 9.0,
                colorHex: '7F7F7F',
                csFontFamily: isAr ? 'Traditional Arabic' : null,
              ),
            ],
            styleId: 'Footer',
            alignment: DocxAlignment.center,
            isRtl: isAr,
            spacingAfterTwips: 0,
          ),
        ],
      );
    }

    return HeaderFooterDetectionResult(
      header: header,
      footer: footer,
      filteredPagesBlocks: filtered,
    );
  }

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

  /// Detects vertical columns on a page strictly avoiding false positives.
  static List<List<TextBlock>> _detectColumns(double pageWidth, List<TextBlock> blocks) {
    if (blocks.length < 4) {
      return [blocks];
    }

    // Sort blocks by X coordinate
    final sortedByX = List<TextBlock>.from(blocks)..sort((a, b) => a.x.compareTo(b.x));

    // Must find a significant continuous vertical white gutter (>= 20pt) in the middle 30% - 70% of page
    final minGutterWidth = 20.0;
    final centerMin = pageWidth * 0.30;
    final centerMax = pageWidth * 0.70;

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
      bool hasSpanningBlock = false;

      for (final b in blocks) {
        // If a block spans across the gutter, layout is not pure 2-column
        if (b.x < gutterSplitX - 5 && (b.x + b.width) > gutterSplitX + 5) {
          hasSpanningBlock = true;
          break;
        }

        if (b.x + b.width <= gutterSplitX + 5) {
          leftCol.add(b);
        } else if (b.x >= gutterSplitX - 5) {
          rightCol.add(b);
        }
      }

      // Hardening checks:
      // 1. No wide block spanning right across the gutter
      // 2. Both columns must have at least 2 distinct blocks
      // 3. Blocks in both columns must have width <= 55% of page width
      if (!hasSpanningBlock && leftCol.length >= 2 && rightCol.length >= 2) {
        final leftMaxWidth = leftCol.map((b) => b.width).reduce(max);
        final rightMaxWidth = rightCol.map((b) => b.width).reduce(max);

        if (leftMaxWidth <= pageWidth * 0.55 && rightMaxWidth <= pageWidth * 0.55) {
          // Check for vertical overlap between columns
          final leftMinY = leftCol.map((b) => b.y).reduce(min);
          final leftMaxY = leftCol.map((b) => b.y + b.height).reduce(max);
          final rightMinY = rightCol.map((b) => b.y).reduce(min);
          final rightMaxY = rightCol.map((b) => b.y + b.height).reduce(max);

          final overlapY = max(0.0, min(leftMaxY, rightMaxY) - max(leftMinY, rightMinY));
          final avgHeight = ((leftMaxY - leftMinY) + (rightMaxY - rightMinY)) / 2.0;

          if (overlapY >= avgHeight * 0.25) {
            // Check if document is predominantly Arabic (RTL reading order for columns)
            final allText = blocks.map((b) => b.text).join(' ');
            if (BidiNormalizer.isPredominantlyArabic(allText)) {
              return [rightCol, leftCol];
            } else {
              return [leftCol, rightCol];
            }
          }
        }
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

    // Heading detection (headings take precedence over list items based on font size)
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

    // List detection & prefix stripping (only if not a heading)
    bool isList = false;
    int? listNumId;
    int indentTwips = 0;
    String processedText = fullText;

    if (!isHeading) {
      final bulletPattern = RegExp(r'^([•\-\*▪◦▫–—])\s+');
      final decimalPattern = RegExp(r'^(\d+[\.\)])\s+');
      final letterPattern = RegExp(r'^([a-zA-Z][\.\)])\s+');
      final arabicNumPattern = RegExp(r'^([٠-٩]+[\.\-])\s+');

      if (bulletPattern.hasMatch(processedText)) {
        isList = true;
        listNumId = 1;
        indentTwips = 720;
        processedText = processedText.replaceFirst(bulletPattern, '');
      } else if (decimalPattern.hasMatch(processedText)) {
        isList = true;
        listNumId = 2;
        indentTwips = 720;
        processedText = processedText.replaceFirst(decimalPattern, '');
      } else if (letterPattern.hasMatch(processedText)) {
        isList = true;
        listNumId = 3;
        indentTwips = 720;
        processedText = processedText.replaceFirst(letterPattern, '');
      } else if (arabicNumPattern.hasMatch(processedText)) {
        isList = true;
        listNumId = 4;
        indentTwips = 720;
        processedText = processedText.replaceFirst(arabicNumPattern, '');
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
    } else if (!isList && spanWidth > pageWidth * 0.70) {
      alignment = DocxAlignment.justify;
    } else {
      alignment = DocxAlignment.left;
    }

    // Construct runs with Arabic / BiDi / Hyperlink support
    final List<DocxRun> runs = [];
    final tokens = processedText.split(' ');

    String currentSegment = '';
    bool currentSegmentIsArabic = false;

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.isEmpty) continue;

      // Hyperlink check (URL)
      final isUrl = token.startsWith('http://') || token.startsWith('https://') || token.startsWith('www.');

      if (isUrl) {
        // Flush previous text segment
        if (currentSegment.isNotEmpty) {
          runs.add(
            _createRun(
              text: currentSegment,
              isArabic: currentSegmentIsArabic,
              fontSizePt: avgHeight,
              isBold: isHeading,
            ),
          );
          currentSegment = '';
        }

        // Add hyperlink run
        final targetUrl = token.startsWith('http') ? token : 'https://$token';
        runs.add(
          DocxRun(
            text: token,
            hyperlinkUrl: targetUrl,
            fontSizePt: avgHeight,
            colorHex: '0563C1',
            isUnderline: true,
          ),
        );
        continue;
      }

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
      isRtl: isPredominantlyArabic,
      styleId: styleId,
      isList: isList,
      listNumId: listNumId,
      indentTwips: indentTwips,
      spacingBeforeTwips: isHeading ? 180 : 0,
      spacingAfterTwips: isHeading ? 100 : (isList ? 60 : 140),
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
      fontFamily: 'Calibri',
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

        List<DocxParagraph> paragraphs = [];
        if (cellText.isNotEmpty) {
          paragraphs.add(
            DocxParagraph(
              runs: [
                DocxRun(
                  text: BidiNormalizer.normalizeText(cellText),
                  isBold: r == 0,
                  isRtl: isAr,
                  csFontFamily: isAr ? 'Traditional Arabic' : null,
                ),
              ],
              alignment: isAr ? DocxAlignment.right : DocxAlignment.left,
              isRtl: isAr,
              spacingAfterTwips: 0,
            ),
          );
        }

        cells.add(
          DocxTableCell(
            paragraphs: paragraphs,
            widthTwips: colWidthTwips,
            cellMarginTopTwips: 100,
            cellMarginBottomTwips: 100,
            cellMarginLeftTwips: 150,
            cellMarginRightTwips: 150,
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
