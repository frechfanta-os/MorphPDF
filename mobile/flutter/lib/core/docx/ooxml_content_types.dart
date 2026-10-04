import 'xml_sanitizer.dart';

/// Centralized manager for Open Packaging Conventions (OPC) [Content_Types].xml.
class OoxmlContentTypes {
  // Standard MIME Content Types
  static const String relsContentType =
      'application/vnd.openxmlformats-package.relationships+xml';
  static const String xmlContentType = 'application/xml';
  static const String documentMainContentType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml';
  static const String stylesContentType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml';
  static const String settingsContentType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml';
  static const String numberingContentType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml';
  static const String headerContentType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml';
  static const String footerContentType =
      'application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml';

  final Map<String, String> _defaults = {
    'rels': relsContentType,
    'xml': xmlContentType,
  };

  final Map<String, String> _overrides = {};

  /// Adds a default extension mapping (e.g. 'png' -> 'image/png').
  void addDefault(String extension, String contentType) {
    _defaults[extension.toLowerCase()] = contentType;
  }

  /// Adds an override for a specific part (e.g. '/word/document.xml').
  void addOverride(String partName, String contentType) {
    var normalized = partName.replaceAll('\\', '/');
    if (!normalized.startsWith('/')) {
      normalized = '/$normalized';
    }
    _overrides[normalized] = contentType;
  }

  /// Serializes into a valid [Content_Types].xml string.
  String toXml() {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n');

    // Defaults
    for (final entry in _defaults.entries) {
      buffer.write(
        '  <Default Extension="${XmlSanitizer.escape(entry.key)}" ContentType="${XmlSanitizer.escape(entry.value)}"/>\n',
      );
    }

    // Overrides
    for (final entry in _overrides.entries) {
      buffer.write(
        '  <Override PartName="${XmlSanitizer.escape(entry.key)}" ContentType="${XmlSanitizer.escape(entry.value)}"/>\n',
      );
    }

    buffer.write('</Types>');
    return buffer.toString();
  }

  /// Factory creating standard default content types for a MorphPDF DOCX package.
  static OoxmlContentTypes createDefault() {
    final ct = OoxmlContentTypes();
    ct.addDefault('png', 'image/png');
    ct.addDefault('jpeg', 'image/jpeg');
    ct.addDefault('jpg', 'image/jpeg');

    ct.addOverride('/word/document.xml', documentMainContentType);
    ct.addOverride('/word/styles.xml', stylesContentType);
    ct.addOverride('/word/settings.xml', settingsContentType);

    return ct;
  }
}
