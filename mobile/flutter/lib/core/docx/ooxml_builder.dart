import 'layout/docx_elements.dart';
import 'ooxml_relationships.dart';
import 'ooxml_units.dart';
import 'xml_sanitizer.dart';

/// Serializes high-level [DocxSection]s and [DocxElement]s into compliant word/document.xml.
class OoxmlBuilder {
  /// Builds word/document.xml string and registers required relationships (images, etc.).
  static String buildDocumentXml({
    required List<DocxSection> sections,
    required OoxmlRelationships documentRels,
    required List<DocxImage> registeredImages,
  }) {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"\n');
    buffer.write('            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"\n');
    buffer.write('            xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"\n');
    buffer.write('            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"\n');
    buffer.write('            xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"\n');
    buffer.write('            xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">\n');
    buffer.write('  <w:body>\n');

    int imageIndex = 1;

    for (int s = 0; s < sections.length; s++) {
      final section = sections[s];

      for (int e = 0; e < section.elements.length; e++) {
        final element = section.elements[e];

        if (element is DocxParagraph) {
          _writeParagraph(buffer, element);
        } else if (element is DocxTable) {
          _writeTable(buffer, element);
        } else if (element is DocxImage) {
          final imgFileName = 'image$imageIndex.${element.extension}';
          final rId = documentRels.addRelationship(
            type: OoxmlRelationships.imageType,
            target: 'media/$imgFileName',
          );
          registeredImages.add(element);

          _writeImageParagraph(buffer, element, rId, imageIndex);
          imageIndex++;
        } else if (element is DocxPageBreak) {
          buffer.write('    <w:p><w:r><w:br w:type="page"/></w:r></w:p>\n');
        }
      }

      // If multiple pages/sections, add page break between sections (except last)
      if (s < sections.length - 1) {
        buffer.write('    <w:p><w:r><w:br w:type="page"/></w:r></w:p>\n');
      }
    }

    // Write final section properties <w:sectPr>
    final lastSection = sections.isNotEmpty ? sections.last : const DocxSection(elements: []);
    _writeSectionProperties(buffer, lastSection);

    buffer.write('  </w:body>\n');
    buffer.write('</w:document>');
    return buffer.toString();
  }

  static void _writeParagraph(StringBuffer buffer, DocxParagraph p) {
    buffer.write('    <w:p>\n');
    buffer.write('      <w:pPr>\n');

    if (p.styleId != 'Normal') {
      buffer.write('        <w:pStyle w:val="${XmlSanitizer.escape(p.styleId)}"/>\n');
    }

    if (p.isRtl) {
      buffer.write('        <w:bidi/>\n');
    }

    // Alignment
    final jcVal = _mapAlignment(p.alignment);
    buffer.write('        <w:jc w:val="$jcVal"/>\n');

    // Indentation
    if (p.indentTwips > 0) {
      buffer.write('        <w:ind w:left="${p.indentTwips}" w:hanging="${p.indentTwips ~/ 2}"/>\n');
    }

    // Spacing
    buffer.write('        <w:spacing w:before="${p.spacingBeforeTwips}" w:after="${p.spacingAfterTwips}" w:line="240" w:lineRule="auto"/>\n');
    buffer.write('      </w:pPr>\n');

    for (final run in p.runs) {
      _writeRun(buffer, run);
    }

    buffer.write('    </w:p>\n');
  }

  static void _writeRun(StringBuffer buffer, DocxRun run) {
    buffer.write('      <w:r>\n');
    buffer.write('        <w:rPr>\n');

    final latinFont = run.fontFamily ?? 'Calibri';
    final csFont = run.csFontFamily ?? 'Traditional Arabic';
    buffer.write('          <w:rFonts w:ascii="$latinFont" w:hAnsi="$latinFont" w:cs="$csFont"/>\n');

    if (run.isBold) {
      buffer.write('          <w:b/>\n');
      buffer.write('          <w:bCs/>\n');
    }

    if (run.isItalic) {
      buffer.write('          <w:i/>\n');
      buffer.write('          <w:iCs/>\n');
    }

    if (run.isUnderline) {
      buffer.write('          <w:u w:val="single"/>\n');
    }

    if (run.colorHex != null && run.colorHex!.isNotEmpty) {
      buffer.write('          <w:color w:val="${XmlSanitizer.escape(run.colorHex!)}"/>\n');
    }

    if (run.fontSizePt != null && run.fontSizePt! > 0) {
      final halfPoints = OoxmlUnits.pointsToHalfPoints(run.fontSizePt!);
      buffer.write('          <w:sz w:val="$halfPoints"/>\n');
      buffer.write('          <w:szCs w:val="${halfPoints + (run.isRtl ? 2 : 0)}"/>\n');
    }

    if (run.isRtl) {
      buffer.write('          <w:rtl/>\n');
    }

    buffer.write('        </w:rPr>\n');
    buffer.write('        <w:t xml:space="preserve">${XmlSanitizer.escape(run.text)}</w:t>\n');
    buffer.write('      </w:r>\n');
  }

  static void _writeTable(StringBuffer buffer, DocxTable tbl) {
    buffer.write('    <w:tbl>\n');
    buffer.write('      <w:tblPr>\n');
    buffer.write('        <w:tblW w:w="0" w:type="auto"/>\n');
    if (tbl.isRtl) {
      buffer.write('        <w:bidiVisual/>\n');
    }
    if (tbl.hasBorders) {
      buffer.write('        <w:tblBorders>\n');
      buffer.write('          <w:top w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>\n');
      buffer.write('          <w:left w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>\n');
      buffer.write('          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>\n');
      buffer.write('          <w:right w:val="single" w:sz="4" w:space="0" w:color="BFBFBF"/>\n');
      buffer.write('          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="E0E0E0"/>\n');
      buffer.write('          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="E0E0E0"/>\n');
      buffer.write('        </w:tblBorders>\n');
    }
    buffer.write('      </w:tblPr>\n');

    // Grid columns
    buffer.write('      <w:tblGrid>\n');
    for (final colWidth in tbl.gridColTwips) {
      buffer.write('        <w:gridCol w:w="$colWidth"/>\n');
    }
    buffer.write('      </w:tblGrid>\n');

    // Rows
    for (final row in tbl.rows) {
      buffer.write('      <w:tr>\n');
      if (row.isHeader) {
        buffer.write('        <w:trPr><w:tblHeader/></w:trPr>\n');
      }
      for (final cell in row.cells) {
        buffer.write('        <w:tc>\n');
        buffer.write('          <w:tcPr>\n');
        buffer.write('            <w:tcW w:w="${cell.widthTwips}" w:type="dxa"/>\n');
        if (cell.colSpan > 1) {
          buffer.write('            <w:gridSpan w:val="${cell.colSpan}"/>\n');
        }
        buffer.write('          </w:tcPr>\n');

        if (cell.paragraphs.isEmpty) {
          buffer.write('          <w:p/>\n');
        } else {
          for (final cp in cell.paragraphs) {
            _writeParagraph(buffer, cp);
          }
        }
        buffer.write('        </w:tc>\n');
      }
      buffer.write('      </w:tr>\n');
    }
    buffer.write('    </w:tbl>\n');
  }

  static void _writeImageParagraph(StringBuffer buffer, DocxImage img, String rId, int imgId) {
    final cxEmu = OoxmlUnits.pointsToEmu(img.widthPt);
    final cyEmu = OoxmlUnits.pointsToEmu(img.heightPt);

    buffer.write('    <w:p>\n');
    buffer.write('      <w:pPr><w:jc w:val="center"/></w:pPr>\n');
    buffer.write('      <w:r>\n');
    buffer.write('        <w:drawing>\n');
    buffer.write('          <wp:inline distT="0" distB="0" distL="0" distR="0">\n');
    buffer.write('            <wp:extent cx="$cxEmu" cy="$cyEmu"/>\n');
    buffer.write('            <wp:docPr id="$imgId" name="${XmlSanitizer.escape(img.altText)}"/>\n');
    buffer.write('            <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">\n');
    buffer.write('              <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">\n');
    buffer.write('                <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">\n');
    buffer.write('                  <pic:nvPicPr>\n');
    buffer.write('                    <pic:cNvPr id="$imgId" name="${XmlSanitizer.escape(img.altText)}"/>\n');
    buffer.write('                    <pic:cNvPicPr/>\n');
    buffer.write('                  </pic:nvPicPr>\n');
    buffer.write('                  <pic:blipFill>\n');
    buffer.write('                    <a:blip r:embed="$rId"/>\n');
    buffer.write('                    <a:stretch><a:fillRect/></a:stretch>\n');
    buffer.write('                  </pic:blipFill>\n');
    buffer.write('                  <pic:spPr>\n');
    buffer.write('                    <a:xfrm>\n');
    buffer.write('                      <a:off x="0" y="0"/>\n');
    buffer.write('                      <a:ext cx="$cxEmu" cy="$cyEmu"/>\n');
    buffer.write('                    </a:xfrm>\n');
    buffer.write('                    <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>\n');
    buffer.write('                  </pic:spPr>\n');
    buffer.write('                </pic:pic>\n');
    buffer.write('              </a:graphicData>\n');
    buffer.write('            </a:graphic>\n');
    buffer.write('          </wp:inline>\n');
    buffer.write('        </w:drawing>\n');
    buffer.write('      </w:r>\n');
    buffer.write('    </w:p>\n');
  }

  static void _writeSectionProperties(StringBuffer buffer, DocxSection section) {
    final wTwips = OoxmlUnits.pointsToTwips(section.pageWidthPt);
    final hTwips = OoxmlUnits.pointsToTwips(section.pageHeightPt);
    final topTwips = OoxmlUnits.pointsToTwips(section.marginTopPt);
    final rightTwips = OoxmlUnits.pointsToTwips(section.marginRightPt);
    final bottomTwips = OoxmlUnits.pointsToTwips(section.marginBottomPt);
    final leftTwips = OoxmlUnits.pointsToTwips(section.marginLeftPt);

    final orientAttr = section.isLandscape ? ' w:orient="landscape"' : '';

    buffer.write('    <w:sectPr>\n');
    buffer.write('      <w:pgSz w:w="$wTwips" w:h="$hTwips"$orientAttr/>\n');
    buffer.write('      <w:pgMar w:top="$topTwips" w:right="$rightTwips" w:bottom="$bottomTwips" w:left="$leftTwips" w:header="720" w:footer="720" w:gutter="0"/>\n');
    buffer.write('    </w:sectPr>\n');
  }

  static String _mapAlignment(DocxAlignment alignment) {
    switch (alignment) {
      case DocxAlignment.left:
        return 'left';
      case DocxAlignment.center:
        return 'center';
      case DocxAlignment.right:
        return 'right';
      case DocxAlignment.justify:
        return 'both';
    }
  }
}
