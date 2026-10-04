import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Statistical and structural profile extracted from a generated .docx package.
class DocxStructureProfile {
  final int paragraphCount;
  final int runCount;
  final int tableCount;
  final int rowCount;
  final int cellCount;
  final int imageCount;
  final int headerCount;
  final int footerCount;
  final int hyperlinkCount;
  final int numberingCount;
  final int sectionCount;
  final int pageBreakCount;
  final int rtlParagraphCount;
  final String fullText;
  final Map<String, String> xmlFiles;

  const DocxStructureProfile({
    required this.paragraphCount,
    required this.runCount,
    required this.tableCount,
    required this.rowCount,
    required this.cellCount,
    required this.imageCount,
    required this.headerCount,
    required this.footerCount,
    required this.hyperlinkCount,
    required this.numberingCount,
    required this.sectionCount,
    required this.pageBreakCount,
    required this.rtlParagraphCount,
    required this.fullText,
    required this.xmlFiles,
  });
}

/// Helper that inspects and validates a generated DOCX package.
class DocxInspector {
  /// Inspects a DOCX file from disk or bytes.
  static Future<DocxStructureProfile> inspectFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return inspectBytes(bytes);
  }

  /// Inspects a DOCX file from raw bytes.
  static DocxStructureProfile inspectBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final xmlFiles = <String, String>{};
    int imageCount = 0;

    for (final file in archive) {
      if (!file.isFile) continue;
      if (file.name.endsWith('.xml') || file.name.endsWith('.rels')) {
        final text = utf8.decode(file.content as List<int>);
        xmlFiles[file.name] = text;
      } else if (file.name.startsWith('word/media/')) {
        imageCount++;
      }
    }

    final docXmlStr = xmlFiles['word/document.xml'] ?? '';
    final docXml = XmlDocument.parse(docXmlStr);

    int paragraphCount = 0;
    int runCount = 0;
    int rtlParagraphCount = 0;
    int hyperlinkCount = 0;
    int pageBreakCount = 0;
    final textBuffer = StringBuffer();

    for (final p in docXml.findAllElements('w:p')) {
      paragraphCount++;
      final isRtl = p.findElements('w:pPr').any((pPr) => pPr.findElements('w:bidi').isNotEmpty);
      if (isRtl) rtlParagraphCount++;

      for (final r in p.findAllElements('w:r')) {
        runCount++;
        for (final br in r.findElements('w:br')) {
          if (br.getAttribute('w:type') == 'page') {
            pageBreakCount++;
          }
        }
        for (final t in r.findElements('w:t')) {
          textBuffer.write(t.innerText);
          textBuffer.write(' ');
        }
      }
    }

    for (final _ in docXml.findAllElements('w:hyperlink')) {
      hyperlinkCount++;
    }

    int tableCount = 0;
    int rowCount = 0;
    int cellCount = 0;

    for (final tbl in docXml.findAllElements('w:tbl')) {
      tableCount++;
      for (final tr in tbl.findElements('w:tr')) {
        rowCount++;
        for (final _ in tr.findElements('w:tc')) {
          cellCount++;
        }
      }
    }

    int sectionCount = docXml.findAllElements('w:sectPr').length;
    if (sectionCount == 0) sectionCount = 1;

    int headerCount = xmlFiles.containsKey('word/header1.xml') ? 1 : 0;
    int footerCount = xmlFiles.containsKey('word/footer1.xml') ? 1 : 0;
    int numberingCount = xmlFiles.containsKey('word/numbering.xml') ? 1 : 0;

    return DocxStructureProfile(
      paragraphCount: paragraphCount,
      runCount: runCount,
      tableCount: tableCount,
      rowCount: rowCount,
      cellCount: cellCount,
      imageCount: imageCount,
      headerCount: headerCount,
      footerCount: footerCount,
      hyperlinkCount: hyperlinkCount,
      numberingCount: numberingCount,
      sectionCount: sectionCount,
      pageBreakCount: pageBreakCount,
      rtlParagraphCount: rtlParagraphCount,
      fullText: textBuffer.toString().trim(),
      xmlFiles: xmlFiles,
    );
  }
}
