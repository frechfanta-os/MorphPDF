import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

import 'layout/docx_elements.dart';
import 'ooxml_builder.dart';
import 'ooxml_content_types.dart';
import 'ooxml_relationships.dart';
import 'ooxml_styles.dart';
import 'xml_sanitizer.dart';

/// Complete generator assembling a compliant Open Packaging Conventions (OPC) .docx archive.
class OoxmlPackage {
  /// Generates a valid .docx ZIP archive as a byte buffer.
  static Uint8List createDocxBytes({
    required List<DocxSection> sections,
    String defaultLatinFont = 'Calibri',
    String defaultArabicFont = 'Traditional Arabic',
  }) {
    final archive = Archive();

    // 1. Root Package Relationships (_rels/.rels)
    final rootRels = OoxmlRelationships.createRootPackageRels();
    final rootRelsXml = utf8.encode(rootRels.toXml());
    archive.addFile(
      ArchiveFile('_rels/.rels', rootRelsXml.length, rootRelsXml),
    );

    // 2. Document Relationships (word/_rels/document.xml.rels)
    final documentRels = OoxmlRelationships();
    documentRels.addRelationship(
      type: OoxmlRelationships.stylesType,
      target: 'styles.xml',
    );
    documentRels.addRelationship(
      type: OoxmlRelationships.settingsType,
      target: 'settings.xml',
    );

    // 3. Document Content (word/document.xml) & Images (word/media/*)
    final registeredImages = <DocxImage>[];
    final documentXmlString = OoxmlBuilder.buildDocumentXml(
      sections: sections,
      documentRels: documentRels,
      registeredImages: registeredImages,
    );
    final documentXmlBytes = utf8.encode(documentXmlString);
    archive.addFile(
      ArchiveFile('word/document.xml', documentXmlBytes.length, documentXmlBytes),
    );

    // Add media files
    for (int i = 0; i < registeredImages.length; i++) {
      final img = registeredImages[i];
      final imgIndex = i + 1;
      final fileName = 'word/media/image$imgIndex.${img.extension}';
      final cleanPath = XmlSanitizer.sanitizePackagePath(fileName);
      archive.addFile(
        ArchiveFile(cleanPath, img.bytes.length, img.bytes),
      );
    }

    // Write word/_rels/document.xml.rels
    final docRelsXml = utf8.encode(documentRels.toXml());
    archive.addFile(
      ArchiveFile('word/_rels/document.xml.rels', docRelsXml.length, docRelsXml),
    );

    // 4. Styles (word/styles.xml)
    final stylesXmlString = OoxmlStyles.generateStylesXml(
      defaultLatinFont: defaultLatinFont,
      defaultArabicFont: defaultArabicFont,
    );
    final stylesXmlBytes = utf8.encode(stylesXmlString);
    archive.addFile(
      ArchiveFile('word/styles.xml', stylesXmlBytes.length, stylesXmlBytes),
    );

    // 5. Settings (word/settings.xml)
    final settingsXmlString = OoxmlStyles.generateSettingsXml();
    final settingsXmlBytes = utf8.encode(settingsXmlString);
    archive.addFile(
      ArchiveFile('word/settings.xml', settingsXmlBytes.length, settingsXmlBytes),
    );

    // 6. Content Types ([Content_Types].xml)
    final contentTypes = OoxmlContentTypes.createDefault();
    final contentTypesXml = utf8.encode(contentTypes.toXml());
    archive.addFile(
      ArchiveFile('[Content_Types].xml', contentTypesXml.length, contentTypesXml),
    );

    // 7. Compress into ZIP archive
    final zipEncoder = ZipEncoder();
    final zipData = zipEncoder.encode(archive);
    if (zipData == null) {
      throw StateError('Failed to encode ZIP archive for DOCX package.');
    }

    return Uint8List.fromList(zipData);
  }

  /// Generates a .docx file and writes it to the designated output path.
  static Future<File> saveDocxToFile({
    required List<DocxSection> sections,
    required String outputPath,
    String defaultLatinFont = 'Calibri',
    String defaultArabicFont = 'Traditional Arabic',
  }) async {
    final bytes = createDocxBytes(
      sections: sections,
      defaultLatinFont: defaultLatinFont,
      defaultArabicFont: defaultArabicFont,
    );

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    return file.writeAsBytes(bytes, flush: true);
  }
}
