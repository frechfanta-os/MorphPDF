import 'dart:math';
import '../../shared/models/text_block.dart';

/// Raw character box extracted from native PDFium.
class RawCharBox {
  final String char;
  final double x;
  final double y;
  final double width;
  final double height;
  final double fontSize;
  final String fontName;

  const RawCharBox({
    required this.char,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.fontSize = 12.0,
    this.fontName = 'Helvetica',
  });
}

/// Deterministic text grouping algorithm converting raw character glyph bounding boxes
/// into structured [TextBlock]s with precise spatial coordinates in PDF points.
class TextGrouper {
  /// Groups raw characters into ordered lines and paragraphs.
  static List<TextBlock> groupCharacters({
    required int pageNumber,
    required List<RawCharBox> rawChars,
    double lineThreshold = 4.0,
    double wordGapMultiplier = 0.5,
  }) {
    if (rawChars.isEmpty) return const [];

    // Filter out non-printable or zero-width glyphs
    final validChars = rawChars.where((c) => c.width > 0 && c.height > 0).toList();
    if (validChars.isEmpty) return const [];

    // Sort top-to-bottom (Y descending in PDF points), then left-to-right (X ascending)
    validChars.sort((a, b) {
      if ((a.y - b.y).abs() > lineThreshold) {
        return b.y.compareTo(a.y); // Higher Y first (top of page in PDF coords)
      }
      return a.x.compareTo(b.x); // Left-to-right
    });

    final List<List<RawCharBox>> lines = [];
    List<RawCharBox> currentLine = [validChars.first];

    for (int i = 1; i < validChars.length; i++) {
      final prev = currentLine.last;
      final curr = validChars[i];

      // Check if on same vertical line
      if ((curr.y - prev.y).abs() <= lineThreshold) {
        currentLine.add(curr);
      } else {
        lines.add(currentLine);
        currentLine = [curr];
      }
    }
    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    // Now group each line into words and text blocks
    final List<TextBlock> blocks = [];
    int blockIndex = 1;

    for (final line in lines) {
      if (line.isEmpty) continue;

      final buffer = StringBuffer();
      double minX = line.first.x;
      double minY = line.first.y;
      double maxX = line.first.x + line.first.width;
      double maxY = line.first.y + line.first.height;

      for (int i = 0; i < line.length; i++) {
        final c = line[i];
        minX = min(minX, c.x);
        minY = min(minY, c.y);
        maxX = max(maxX, c.x + c.width);
        maxY = max(maxY, c.y + c.height);

        buffer.write(c.char);

        // Check if we need to insert space between this and next char
        if (i < line.length - 1) {
          final next = line[i + 1];
          final gap = next.x - (c.x + c.width);
          final spaceThreshold = c.fontSize * wordGapMultiplier;
          if (gap > spaceThreshold && !c.char.endsWith(' ')) {
            buffer.write(' ');
          }
        }
      }

      final text = buffer.toString().trim();
      if (text.isNotEmpty) {
        blocks.add(
          TextBlock(
            id: 'block_${pageNumber}_$blockIndex',
            pageNumber: pageNumber,
            text: text,
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY,
            confidence: 1.0,
            language: 'fr',
          ),
        );
        blockIndex++;
      }
    }

    return blocks;
  }
}
