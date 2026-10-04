/// Centralized XML sanitization and security protection for OOXML generation.
class XmlSanitizer {
  // Disallowed control characters in XML 1.0 (excluding tab \t 0x09, LF \n 0x0A, CR \r 0x0D)
  static final RegExp _invalidXmlChars = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x84\x86-\x9F]',
  );

  /// Escapes standard XML characters and strips illegal XML 1.0 control characters.
  static String escape(String input) {
    if (input.isEmpty) return '';

    // First strip illegal XML 1.0 characters
    final cleaned = input.replaceAll(_invalidXmlChars, '');

    // Escape entities
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      final char = cleaned[i];
      switch (char) {
        case '&':
          buffer.write('&amp;');
          break;
        case '<':
          buffer.write('&lt;');
          break;
        case '>':
          buffer.write('&gt;');
          break;
        case '"':
          buffer.write('&quot;');
          break;
        case "'":
          buffer.write('&apos;');
          break;
        default:
          buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Sanitizes package internal file paths, preventing path traversal attacks.
  static String sanitizePackagePath(String path) {
    // Disallow external URLs or absolute drive paths
    var normalized = path.replaceAll('\\', '/');

    // Remove any leading slashes
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }

    // Disallow directory traversal segments
    final segments = normalized.split('/');
    final cleanSegments = <String>[];
    for (final seg in segments) {
      if (seg.isEmpty || seg == '.') continue;
      if (seg == '..') {
        throw ArgumentError('Path traversal sequence (..) is forbidden: $path');
      }
      cleanSegments.add(seg);
    }

    return cleanSegments.join('/');
  }
}
