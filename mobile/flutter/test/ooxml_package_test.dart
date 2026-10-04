import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/docx/layout/docx_elements.dart';
import 'package:morphpdf/core/docx/ooxml_package.dart';
import 'package:xml/xml.dart';

void main() {
  group('OOXML Package & Milestone DOCX Tests', () {
    test('Generate complete synthetic DOCX and verify ZIP / XML validity (Milestone)', () async {
      // 1. Construct rich synthetic document elements
      final dummyPngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG header
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82,
      ]);

      final elements = <DocxElement>[
        // Title
        const DocxParagraph(
          runs: [
            DocxRun(
              text: 'MorphPDF Official Document Test',
              isBold: true,
              fontSizePt: 18.0,
              colorHex: '1F497D',
            ),
          ],
          styleId: 'Heading1',
          alignment: DocxAlignment.center,
        ),

        // French Paragraph with Bold and Italic
        const DocxParagraph(
          runs: [
            DocxRun(text: 'Ceci est un document de test avec '),
            DocxRun(text: 'texte en gras', isBold: true),
            DocxRun(text: ' et '),
            DocxRun(text: 'texte en italique.', isItalic: true),
          ],
          alignment: DocxAlignment.left,
        ),

        // Arabic Paragraph with RTL properties
        const DocxParagraph(
          runs: [
            DocxRun(
              text: 'الجمهورية الجزائرية الديمقراطية الشعبية - وزارة العدل',
              isRtl: true,
              csFontFamily: 'Traditional Arabic',
              fontSizePt: 14.0,
            ),
          ],
          isRtl: true,
          alignment: DocxAlignment.right,
        ),

        // Mixed Arabic + Latin Paragraph
        const DocxParagraph(
          runs: [
            DocxRun(
              text: 'وثيقة رسمية صادرة عن تطبيق ',
              isRtl: true,
              csFontFamily: 'Traditional Arabic',
            ),
            DocxRun(
              text: 'MorphPDF Studio 2026',
              isBold: true,
            ),
          ],
          isRtl: true,
          alignment: DocxAlignment.right,
        ),

        // Table
        const DocxTable(
          gridColTwips: [4500, 4500],
          hasBorders: true,
          rows: [
            DocxTableRow(
              isHeader: true,
              cells: [
                DocxTableCell(
                  widthTwips: 4500,
                  paragraphs: [
                    DocxParagraph(
                      runs: [DocxRun(text: 'Article', isBold: true)],
                      alignment: DocxAlignment.left,
                    ),
                  ],
                ),
                DocxTableCell(
                  widthTwips: 4500,
                  paragraphs: [
                    DocxParagraph(
                      runs: [DocxRun(text: 'Valeur', isBold: true)],
                      alignment: DocxAlignment.left,
                    ),
                  ],
                ),
              ],
            ),
            DocxTableRow(
              cells: [
                DocxTableCell(
                  widthTwips: 4500,
                  paragraphs: [
                    DocxParagraph(
                      runs: [DocxRun(text: 'Document Model')],
                    ),
                  ],
                ),
                DocxTableCell(
                  widthTwips: 4500,
                  paragraphs: [
                    DocxParagraph(
                      runs: [DocxRun(text: 'Conforme OOXML')],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Image
        DocxImage(
          bytes: dummyPngBytes,
          extension: 'png',
          widthPt: 200.0,
          heightPt: 150.0,
          altText: 'Logo MorphPDF',
        ),

        // Page break
        const DocxPageBreak(),

        // Page 2 Paragraph
        const DocxParagraph(
          runs: [
            DocxRun(text: 'Page 2 du document converti.'),
          ],
        ),
      ];

      final section = DocxSection(
        pageWidthPt: 595.28,
        pageHeightPt: 841.89,
        elements: elements,
      );

      // 2. Generate byte buffer
      final docxBytes = OoxmlPackage.createDocxBytes(sections: [section]);
      expect(docxBytes, isNotEmpty);

      // 3. Verify ZIP archive integrity
      final archive = ZipDecoder().decodeBytes(docxBytes);
      final fileNames = archive.files.map((f) => f.name).toSet();

      // Required OOXML OPC parts check
      expect(fileNames, contains('[Content_Types].xml'));
      expect(fileNames, contains('_rels/.rels'));
      expect(fileNames, contains('word/document.xml'));
      expect(fileNames, contains('word/styles.xml'));
      expect(fileNames, contains('word/settings.xml'));
      expect(fileNames, contains('word/_rels/document.xml.rels'));
      expect(fileNames, contains('word/media/image1.png'));

      // 4. Verify that EVERY XML file is strictly well-formed
      for (final f in archive.files) {
        if (f.name.endsWith('.xml') || f.name.endsWith('.rels')) {
          final content = String.fromCharCodes(f.content as List<int>);
          expect(
            () => XmlDocument.parse(content),
            returnsNormally,
            reason: 'XML file ${f.name} failed strict parsing',
          );
        }
      }

      // 5. Verify relationships linkage
      final docRelsFile = archive.findFile('word/_rels/document.xml.rels')!;
      final docRelsContent = String.fromCharCodes(docRelsFile.content as List<int>);
      final docRelsXml = XmlDocument.parse(docRelsContent);
      final rIds = docRelsXml.findAllElements('Relationship').map((r) => r.getAttribute('Id')).toSet();

      final docXmlFile = archive.findFile('word/document.xml')!;
      final docXmlContent = String.fromCharCodes(docXmlFile.content as List<int>);
      final docXml = XmlDocument.parse(docXmlContent);

      // Check DrawingML image relationship
      final blips = docXml.findAllElements('a:blip');
      expect(blips, isNotEmpty);
      for (final blip in blips) {
        final embedId = blip.getAttribute('r:embed');
        expect(rIds, contains(embedId));
      }

      // Check Arabic RTL tags
      final bidiTags = docXml.findAllElements('w:bidi');
      expect(bidiTags, isNotEmpty);
      final rtlRuns = docXml.findAllElements('w:rtl');
      expect(rtlRuns, isNotEmpty);

      // Check Table tags
      final tables = docXml.findAllElements('w:tbl');
      expect(tables, isNotEmpty);

      // 6. Write test_output.docx to disk and test with unzip -t if unzip exists
      final outputPath = '${Directory.systemTemp.path}/test_output.docx';
      await File(outputPath).writeAsBytes(docxBytes);

      final unzipCheck = await Process.run('unzip', ['-t', outputPath]);
      expect(unzipCheck.exitCode, 0, reason: 'unzip -t failed: ${unzipCheck.stderr}');
      expect(unzipCheck.stdout.toString(), contains('No errors detected'));
    });
  });
}
