import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/docx/ooxml_content_types.dart';
import 'package:morphpdf/core/docx/ooxml_relationships.dart';
import 'package:morphpdf/core/docx/ooxml_units.dart';
import 'package:morphpdf/core/docx/xml_sanitizer.dart';
import 'package:xml/xml.dart';

void main() {
  group('OOXML Units Conversion Tests', () {
    test('pointsToTwips and twipsToPoints', () {
      // 1 pt = 20 twips
      expect(OoxmlUnits.pointsToTwips(1.0), 20);
      expect(OoxmlUnits.pointsToTwips(72.0), 1440); // 1 inch = 1440 twips
      expect(OoxmlUnits.pointsToTwips(OoxmlUnits.a4WidthPt), 11906);
      expect(OoxmlUnits.pointsToTwips(OoxmlUnits.a4HeightPt), 16838);

      expect(OoxmlUnits.twipsToPoints(1440), 72.0);
      expect(OoxmlUnits.twipsToPoints(20), 1.0);
    });

    test('pointsToEmu and emuToPoints', () {
      // 1 pt = 12700 EMU
      expect(OoxmlUnits.pointsToEmu(1.0), 12700);
      expect(OoxmlUnits.pointsToEmu(72.0), 914400); // 1 inch = 914400 EMU
      expect(OoxmlUnits.emuToPoints(12700), 1.0);
      expect(OoxmlUnits.emuToPoints(914400), 72.0);
    });

    test('pointsToHalfPoints and halfPointsToPoints', () {
      // 1 pt = 2 half-points
      expect(OoxmlUnits.pointsToHalfPoints(12.0), 24);
      expect(OoxmlUnits.pointsToHalfPoints(16.5), 33);
      expect(OoxmlUnits.halfPointsToPoints(24), 12.0);
      expect(OoxmlUnits.halfPointsToPoints(33), 16.5);
    });
  });

  group('XML Sanitizer & Security Tests', () {
    test('Entity escaping (&, <, >, ", \')', () {
      const raw = 'Tom & Jerry <cartoon> "vintage" \'edition\'';
      final escaped = XmlSanitizer.escape(raw);
      expect(escaped, 'Tom &amp; Jerry &lt;cartoon&gt; &quot;vintage&quot; &apos;edition&apos;');
    });

    test('Strips illegal XML 1.0 control characters', () {
      // 0x00 (NUL), 0x07 (BEL), 0x08 (BS), 0x1B (ESC)
      final rawWithControlChars = 'Text\x00With\x07Illegal\x08Chars\x1BEnd';
      final cleaned = XmlSanitizer.escape(rawWithControlChars);
      expect(cleaned, 'TextWithIllegalCharsEnd');

      // Valid whitespace: \t (0x09), \n (0x0A), \r (0x0D) must be preserved
      final validWs = 'Line1\tCol2\r\nLine2';
      expect(XmlSanitizer.escape(validWs), validWs);
    });

    test('Path traversal protection in sanitizePackagePath', () {
      expect(XmlSanitizer.sanitizePackagePath('word/media/image1.png'), 'word/media/image1.png');
      expect(XmlSanitizer.sanitizePackagePath('/word/document.xml'), 'word/document.xml');
      expect(XmlSanitizer.sanitizePackagePath(r'word\media\pic.jpg'), 'word/media/pic.jpg');

      // Attempted traversal throws ArgumentError
      expect(
        () => XmlSanitizer.sanitizePackagePath('../../../etc/passwd'),
        throwsArgumentError,
      );
      expect(
        () => XmlSanitizer.sanitizePackagePath('word/../../secret.txt'),
        throwsArgumentError,
      );
    });
  });

  group('OOXML Relationships Tests', () {
    test('addRelationship generates deterministic rIds without duplicates', () {
      final rels = OoxmlRelationships();
      final id1 = rels.addRelationship(type: OoxmlRelationships.stylesType, target: 'styles.xml');
      final id2 = rels.addRelationship(type: OoxmlRelationships.settingsType, target: 'settings.xml');
      final id3 = rels.addRelationship(type: OoxmlRelationships.stylesType, target: 'styles.xml');

      expect(id1, 'rId1');
      expect(id2, 'rId2');
      expect(id3, 'rId1'); // Reuses existing relationship for identical target/type
      expect(rels.entries.length, 2);
    });

    test('toXml produces valid XML document', () {
      final rels = OoxmlRelationships.createRootPackageRels();
      final xmlString = rels.toXml();

      final parsed = XmlDocument.parse(xmlString);
      expect(parsed.rootElement.name.local, 'Relationships');
      expect(parsed.findAllElements('Relationship').length, 1);
      final rel = parsed.findAllElements('Relationship').first;
      expect(rel.getAttribute('Id'), 'rId1');
      expect(rel.getAttribute('Target'), 'word/document.xml');
    });
  });

  group('OOXML Content Types Tests', () {
    test('Default and override registration and XML serialization', () {
      final ct = OoxmlContentTypes.createDefault();
      ct.addDefault('webp', 'image/webp');
      ct.addOverride('/word/custom.xml', 'application/custom+xml');

      final xmlString = ct.toXml();
      final parsed = XmlDocument.parse(xmlString);

      expect(parsed.rootElement.name.local, 'Types');

      final defaults = parsed.findAllElements('Default');
      expect(defaults.any((d) => d.getAttribute('Extension') == 'png'), isTrue);
      expect(defaults.any((d) => d.getAttribute('Extension') == 'webp'), isTrue);

      final overrides = parsed.findAllElements('Override');
      expect(overrides.any((o) => o.getAttribute('PartName') == '/word/document.xml'), isTrue);
      expect(overrides.any((o) => o.getAttribute('PartName') == '/word/custom.xml'), isTrue);
    });
  });
}
