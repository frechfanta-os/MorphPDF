import 'xml_sanitizer.dart';

/// Single relationship entry in an OOXML .rels file.
class OoxmlRelationshipEntry {
  final String id;
  final String type;
  final String target;
  final String? targetMode; // 'External' or null (Internal)

  const OoxmlRelationshipEntry({
    required this.id,
    required this.type,
    required this.target,
    this.targetMode,
  });

  String toXml() {
    final modeAttr = targetMode != null ? ' TargetMode="${XmlSanitizer.escape(targetMode!)}"' : '';
    return '<Relationship Id="${XmlSanitizer.escape(id)}" Type="${XmlSanitizer.escape(type)}" Target="${XmlSanitizer.escape(target)}"$modeAttr/>';
  }
}

/// Centralized manager for Open Packaging Conventions (OPC) relationships.
class OoxmlRelationships {
  // Standard OOXML Relationship Types
  static const String officeDocumentType =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument';
  static const String stylesType =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles';
  static const String settingsType =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings';
  static const String numberingType =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering';
  static const String imageType =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/image';
  static const String hyperlinkType =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink';
  static const String headerType =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/header';
  static const String footerType =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer';

  final List<OoxmlRelationshipEntry> _entries = [];
  int _counter = 1;

  List<OoxmlRelationshipEntry> get entries => List.unmodifiable(_entries);

  /// Registers a new relationship with a unique deterministic rId.
  String addRelationship({
    required String type,
    required String target,
    String? targetMode,
  }) {
    // Check if identical target & type already registered
    for (final entry in _entries) {
      if (entry.type == type && entry.target == target && entry.targetMode == targetMode) {
        return entry.id;
      }
    }

    final id = 'rId$_counter';
    _counter++;
    _entries.add(
      OoxmlRelationshipEntry(
        id: id,
        type: type,
        target: target,
        targetMode: targetMode,
      ),
    );
    return id;
  }

  /// Checks if a relationship with the given ID exists.
  bool containsId(String id) {
    return _entries.any((e) => e.id == id);
  }

  /// Serializes the relationships collection into a valid .rels XML document.
  String toXml() {
    final buffer = StringBuffer();
    buffer.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    buffer.write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n');
    for (final entry in _entries) {
      buffer.write('  ${entry.toXml()}\n');
    }
    buffer.write('</Relationships>');
    return buffer.toString();
  }

  /// Creates a standard root package _rels/.rels targeting word/document.xml.
  static OoxmlRelationships createRootPackageRels() {
    final rels = OoxmlRelationships();
    rels.addRelationship(
      type: officeDocumentType,
      target: 'word/document.xml',
    );
    return rels;
  }
}
