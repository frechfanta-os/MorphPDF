import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/docx/layout/docx_elements.dart';
import 'package:morphpdf/core/docx/layout/layout_reconstructor.dart';
import 'package:morphpdf/core/docx/ooxml_package.dart';
import 'package:morphpdf/shared/models/page_model.dart';
import 'package:xml/xml.dart';

import 'fixtures/synthetic_documents.dart';

void main() {
  group('Phase 5.2 DOCX Fidelity & Document Semantics Tests', () {
    // Helper to unzip and validate all XML parts in a DOCX archive
    Map<String, String> unzipAndValidateDocx(List<int> docxBytes) {
      final archive = ZipDecoder().decodeBytes(docxBytes);
      final xmlContents = <String, String>{};

      for (final file in archive) {
        if (file.isFile && (file.name.endsWith('.xml') || file.name.endsWith('.rels'))) {
          final contentStr = utf8.decode(file.content as List<int>);
          // Strict XML parse to ensure zero syntax or well-formedness errors
          expect(() => XmlDocument.parse(contentStr), returnsNormally,
              reason: 'File ${file.name} in package is not well-formed XML');
          xmlContents[file.name] = contentStr;
        }
      }

      // Mandatory OPC package parts
      expect(xmlContents.containsKey('_rels/.rels'), isTrue);
      expect(xmlContents.containsKey('[Content_Types].xml'), isTrue);
      expect(xmlContents.containsKey('word/document.xml'), isTrue);
      expect(xmlContents.containsKey('word/_rels/document.xml.rels'), isTrue);
      expect(xmlContents.containsKey('word/styles.xml'), isTrue);
      expect(xmlContents.containsKey('word/settings.xml'), isTrue);

      return xmlContents;
    }

    test('01_simple_french: Typography formatting (bold, italic, underline, strike)', () {
      final section = SyntheticDocuments.fixture01SimpleFrench();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:b/>'));
      expect(docXml, contains('<w:i/>'));
      expect(docXml, contains('<w:u w:val="single"/>'));
      expect(docXml, contains('<w:strike/>'));
      expect(docXml, contains("Rapport d&apos;activité annuel 2026"));
      expect(docXml, contains('officiel et confidentiel'));
      expect(docXml, contains('obsolète'));
    });

    test('02_arabic_rtl: Pure Arabic document with RTL tagging, right alignment and CS font', () {
      final section = SyntheticDocuments.fixture02ArabicRtl();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:bidi/>'));
      expect(docXml, contains('<w:rtl/>'));
      expect(docXml, contains('<w:jc w:val="right"/>'));
      expect(docXml, contains('w:cs="Traditional Arabic"'));
      expect(docXml, contains('تقرير الأداء المالي السنوي'));
    });

    test('03_mixed_bidi: Bilingual document with alternating LTR and RTL runs in same paragraph', () {
      final section = SyntheticDocuments.fixture03MixedBidi();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('Rapport bilingue:'));
      expect(docXml, contains('مشروع مورف الرقمي'));
      expect(docXml, contains('GHD Interactive Studio'));
      expect(docXml, contains('<w:rtl/>'));
    });

    test('04_arabic_numbers_dates: Arabic numbers (123, ٤٥٦), dates and external hyperlink', () {
      final section = SyntheticDocuments.fixture04ArabicNumbersDates();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      final relsXml = files['word/_rels/document.xml.rels']!;

      expect(docXml, contains('123'));
      expect(docXml, contains('٤٥٦'));
      expect(docXml, contains('1446'));
      expect(docXml, contains('2026/10/04'));

      // Hyperlink XML and external relationship
      expect(docXml, contains('<w:hyperlink'));
      expect(relsXml, contains('Target="https://morphpdf.example.com"'));
      expect(relsXml, contains('TargetMode="External"'));
    });

    test('05_two_columns: Multi-column reconstruction with distinct white valley and zero false positives', () {
      final blocks = SyntheticDocuments.fixture05TwoColumnsBlocks();
      const page = PageModel(pageNumber: 1, width: 595.28, height: 841.89);

      final elements = LayoutReconstructor.reconstructPage(
        page: page,
        textBlocks: blocks,
      );

      final paragraphs = elements.whereType<DocxParagraph>().toList();
      expect(paragraphs.length, greaterThanOrEqualTo(2));

      final allTexts = paragraphs.map((p) => p.fullText).toList();
      // Left column followed by right column
      expect(allTexts.any((t) => t.contains('Colonne Gauche')), isTrue);
      expect(allTexts.any((t) => t.contains('Colonne Droite')), isTrue);

      // Verify DOCX generation from multi-column result
      final docxBytes = OoxmlPackage.createDocxBytes(
        sections: [DocxSection(elements: elements)],
      );
      final files = unzipAndValidateDocx(docxBytes);
      expect(files['word/document.xml'], contains('Colonne Gauche'));
      expect(files['word/document.xml'], contains('Colonne Droite'));
    });

    test('06_headings_hierarchy: Heading1, Heading2, Heading3 styling hierarchy', () {
      final section = SyntheticDocuments.fixture06HeadingsHierarchy();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:pStyle w:val="Heading1"/>'));
      expect(docXml, contains('<w:pStyle w:val="Heading2"/>'));
      expect(docXml, contains('<w:pStyle w:val="Heading3"/>'));
    });

    test('07_bullet_list: Bullet list detection and numbering.xml integration', () {
      final section = SyntheticDocuments.fixture07BulletList();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      expect(files.containsKey('word/numbering.xml'), isTrue);
      final numXml = files['word/numbering.xml']!;
      expect(numXml, contains('w:numFmt w:val="bullet"'));

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:numId w:val="1"/>'));
      expect(docXml, contains('<w:ilvl w:val="0"/>'));
      expect(docXml, contains('Extraction native PDFium sans perte'));
    });

    test('08_numbered_list: Numbered list with decimal numbering.xml integration', () {
      final section = SyntheticDocuments.fixture08NumberedList();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      expect(files.containsKey('word/numbering.xml'), isTrue);
      final numXml = files['word/numbering.xml']!;
      expect(numXml, contains('w:numFmt w:val="decimal"'));

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:numId w:val="2"/>'));
      expect(docXml, contains('Chargement du document PDF'));
    });

    test('09_simple_table: 3x3 table with headers and border formatting', () {
      final section = SyntheticDocuments.fixture09SimpleTable();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:tbl>'));
      expect(docXml, contains('<w:tblHeader/>'));
      expect(docXml, contains('<w:tblBorders>'));
      expect(docXml, contains('<w:gridCol'));
      expect(docXml, contains('Composant'));
      expect(docXml, contains('PDFium'));
      expect(docXml, contains('PaddleOCR'));
    });

    test('10_table_empty_cells: Table containing empty cells emits valid empty <w:p/> in <w:tc>', () {
      final section = SyntheticDocuments.fixture10TableEmptyCells();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:tc>'));
      expect(docXml, contains('<w:p/>'));
      expect(docXml, contains('Cellule Remplie'));
    });

    test('11_table_rtl: Arabic table with RTL visual and right aligned cells', () {
      final section = SyntheticDocuments.fixture11TableRtl();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:bidiVisual/>'));
      expect(docXml, contains('البند'));
      expect(docXml, contains('القيمة'));
      expect(docXml, contains('100,000 ريال'));
    });

    test('12_image_document: Embedded PNG image in word/media/ and DrawingML representation', () {
      final section = SyntheticDocuments.fixture12ImageDocument();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      final archive = ZipDecoder().decodeBytes(docxBytes);

      final mediaFile = archive.findFile('word/media/image1.png');
      expect(mediaFile, isNotNull);
      expect(mediaFile!.content, equals(SyntheticDocuments.samplePngBytes));

      final files = unzipAndValidateDocx(docxBytes);
      final docXml = files['word/document.xml']!;
      expect(docXml, contains('<w:drawing>'));
      expect(docXml, contains('<a:blip r:embed='));
      expect(docXml, contains('Logo MorphPDF Transparent'));
    });

    test('13_header_footer: Multi-page document with dedicated header1.xml and footer1.xml', () {
      final sections = SyntheticDocuments.fixture13HeaderFooter();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: sections);
      final files = unzipAndValidateDocx(docxBytes);

      expect(files.containsKey('word/header1.xml'), isTrue);
      expect(files.containsKey('word/footer1.xml'), isTrue);

      final headerXml = files['word/header1.xml']!;
      final footerXml = files['word/footer1.xml']!;
      final docXml = files['word/document.xml']!;
      final contentTypesXml = files['[Content_Types].xml']!;

      expect(headerXml, contains('MorphPDF Enterprise Edition'));
      expect(footerXml, contains('Page 1 sur 2 - Tous droits réservés'));
      expect(docXml, contains('<w:headerReference'));
      expect(docXml, contains('<w:footerReference'));
      expect(contentTypesXml, contains('header+xml'));
      expect(contentTypesXml, contains('footer+xml'));
    });

    test('14_landscape_multipage: Landscape orientation and multi-page breaks', () {
      final sections = SyntheticDocuments.fixture14LandscapeMultipage();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: sections);
      final files = unzipAndValidateDocx(docxBytes);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('w:orient="landscape"'));
      expect(docXml, contains('<w:br w:type="page"/>'));
      expect(docXml, contains('Tableau de bord paysage - Page 1'));
      expect(docXml, contains('Graphiques analytiques - Page 2'));
    });

    test('15_mixed_document: Complex document combining all document semantics without corruption', () {
      final sections = SyntheticDocuments.fixture15MixedDocument();
      final docxBytes = OoxmlPackage.createDocxBytes(sections: sections);
      final files = unzipAndValidateDocx(docxBytes);

      // Verify all parts exist and are well-formed
      expect(files.containsKey('word/header1.xml'), isTrue);
      expect(files.containsKey('word/footer1.xml'), isTrue);
      expect(files.containsKey('word/numbering.xml'), isTrue);

      final docXml = files['word/document.xml']!;
      expect(docXml, contains('Dossier Technique &amp; Stratégique'));
      expect(docXml, contains('<w:bidi/>'));
      expect(docXml, contains('<w:numId w:val="1"/>'));
      expect(docXml, contains('<w:tbl>'));
      expect(docXml, contains('<w:drawing>'));
    });
  });
}
