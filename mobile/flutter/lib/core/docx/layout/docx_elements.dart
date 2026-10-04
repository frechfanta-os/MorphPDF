import 'dart:typed_data';

/// Text alignment within a DOCX paragraph.
enum DocxAlignment {
  left,
  center,
  right,
  justify,
}

/// Base class for all document body flow elements.
abstract class DocxElement {
  const DocxElement();
}

/// A formatted fragment of text within a paragraph.
class DocxRun {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrike;
  final double? fontSizePt;
  final String? colorHex; // e.g. "1F497D"
  final String? fontFamily;
  final bool isRtl;
  final String? csFontFamily;
  final String? hyperlinkUrl; // If present, wraps in <w:hyperlink>

  const DocxRun({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrike = false,
    this.fontSizePt,
    this.colorHex,
    this.fontFamily,
    this.isRtl = false,
    this.csFontFamily,
    this.hyperlinkUrl,
  });

  DocxRun copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrike,
    double? fontSizePt,
    String? colorHex,
    String? fontFamily,
    bool? isRtl,
    String? csFontFamily,
    String? hyperlinkUrl,
  }) {
    return DocxRun(
      text: text ?? this.text,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrike: isStrike ?? this.isStrike,
      fontSizePt: fontSizePt ?? this.fontSizePt,
      colorHex: colorHex ?? this.colorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      isRtl: isRtl ?? this.isRtl,
      csFontFamily: csFontFamily ?? this.csFontFamily,
      hyperlinkUrl: hyperlinkUrl ?? this.hyperlinkUrl,
    );
  }
}

/// A paragraph of text containing one or more runs.
class DocxParagraph extends DocxElement {
  final List<DocxRun> runs;
  final DocxAlignment alignment;
  final bool isRtl;
  final String styleId; // e.g. 'Normal', 'Heading1', 'Heading2', 'Header', 'Footer'
  final bool isList;
  final int? listNumId; // 1 for bullets, 2 for ordered
  final int listLevel; // 0-based indentation level
  final int indentTwips;
  final int spacingBeforeTwips;
  final int spacingAfterTwips;

  const DocxParagraph({
    required this.runs,
    this.alignment = DocxAlignment.left,
    this.isRtl = false,
    this.styleId = 'Normal',
    this.isList = false,
    this.listNumId,
    this.listLevel = 0,
    this.indentTwips = 0,
    this.spacingBeforeTwips = 0,
    this.spacingAfterTwips = 160,
  });

  String get fullText => runs.map((r) => r.text).join();
}

/// A cell in a DOCX table.
class DocxTableCell {
  final List<DocxParagraph> paragraphs;
  final int widthTwips;
  final int colSpan;
  final int rowSpan;
  final String? shadingColorHex; // Cell background color e.g. "F2F2F2"
  final int? cellMarginTopTwips;
  final int? cellMarginBottomTwips;
  final int? cellMarginLeftTwips;
  final int? cellMarginRightTwips;

  const DocxTableCell({
    required this.paragraphs,
    required this.widthTwips,
    this.colSpan = 1,
    this.rowSpan = 1,
    this.shadingColorHex,
    this.cellMarginTopTwips,
    this.cellMarginBottomTwips,
    this.cellMarginLeftTwips,
    this.cellMarginRightTwips,
  });
}

/// A row in a DOCX table.
class DocxTableRow {
  final List<DocxTableCell> cells;
  final bool isHeader;

  const DocxTableRow({
    required this.cells,
    this.isHeader = false,
  });
}

/// A structured table element.
class DocxTable extends DocxElement {
  final List<DocxTableRow> rows;
  final List<int> gridColTwips;
  final bool isRtl;
  final bool hasBorders;

  const DocxTable({
    required this.rows,
    required this.gridColTwips,
    this.isRtl = false,
    this.hasBorders = true,
  });
}

/// An embedded raster image element.
class DocxImage extends DocxElement {
  final Uint8List bytes;
  final String extension; // 'png' or 'jpeg'
  final double widthPt;
  final double heightPt;
  final String altText;

  const DocxImage({
    required this.bytes,
    this.extension = 'png',
    required this.widthPt,
    required this.heightPt,
    this.altText = 'Image',
  });
}

/// Explicit page break element.
class DocxPageBreak extends DocxElement {
  const DocxPageBreak();
}

/// Document header element.
class DocxHeader {
  final List<DocxParagraph> paragraphs;
  const DocxHeader({required this.paragraphs});
}

/// Document footer element.
class DocxFooter {
  final List<DocxParagraph> paragraphs;
  const DocxFooter({required this.paragraphs});
}

/// Section defining page dimensions, margins, headers, footers and containing body elements.
class DocxSection {
  final double pageWidthPt;
  final double pageHeightPt;
  final bool isLandscape;
  final double marginTopPt;
  final double marginRightPt;
  final double marginBottomPt;
  final double marginLeftPt;
  final DocxHeader? header;
  final DocxFooter? footer;
  final List<DocxElement> elements;

  const DocxSection({
    this.pageWidthPt = 595.28, // A4 default
    this.pageHeightPt = 841.89,
    this.isLandscape = false,
    this.marginTopPt = 72.0,
    this.marginRightPt = 72.0,
    this.marginBottomPt = 72.0,
    this.marginLeftPt = 72.0,
    this.header,
    this.footer,
    required this.elements,
  });
}
