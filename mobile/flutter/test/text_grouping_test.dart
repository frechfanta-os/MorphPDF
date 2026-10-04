import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/pdf/text_grouper.dart';

void main() {
  group('TextGrouper Tests', () {
    test('Groups characters on same line into word and line text block', () {
      final chars = [
        const RawCharBox(char: 'H', x: 50, y: 780, width: 8, height: 12),
        const RawCharBox(char: 'e', x: 58, y: 780, width: 8, height: 12),
        const RawCharBox(char: 'l', x: 66, y: 780, width: 6, height: 12),
        const RawCharBox(char: 'l', x: 72, y: 780, width: 6, height: 12),
        const RawCharBox(char: 'o', x: 78, y: 780, width: 8, height: 12),
        // Space gap (> 6)
        const RawCharBox(char: 'P', x: 96, y: 780, width: 8, height: 12),
        const RawCharBox(char: 'D', x: 104, y: 780, width: 8, height: 12),
        const RawCharBox(char: 'F', x: 112, y: 780, width: 8, height: 12),
      ];

      final blocks = TextGrouper.groupCharacters(pageNumber: 1, rawChars: chars);

      expect(blocks.length, 1);
      final b = blocks.first;
      expect(b.text, 'Hello PDF');
      expect(b.pageNumber, 1);
      expect(b.x, 50.0);
      expect(b.y, 780.0);
      expect(b.width, 70.0);
      expect(b.height, 12.0);
    });

    test('Separates characters on different vertical lines into distinct blocks', () {
      final chars = [
        // Line 1 (y = 780)
        const RawCharBox(char: 'T', x: 50, y: 780, width: 8, height: 12),
        const RawCharBox(char: '1', x: 58, y: 780, width: 8, height: 12),
        // Line 2 (y = 750)
        const RawCharBox(char: 'T', x: 50, y: 750, width: 8, height: 12),
        const RawCharBox(char: '2', x: 58, y: 750, width: 8, height: 12),
      ];

      final blocks = TextGrouper.groupCharacters(pageNumber: 1, rawChars: chars);

      expect(blocks.length, 2);
      expect(blocks[0].text, 'T1');
      expect(blocks[1].text, 'T2');
    });

    test('Handles empty or invalid character arrays gracefully', () {
      final emptyBlocks = TextGrouper.groupCharacters(pageNumber: 1, rawChars: []);
      expect(emptyBlocks, isEmpty);

      final zeroWidthChars = [
        const RawCharBox(char: 'A', x: 50, y: 780, width: 0, height: 0),
      ];
      final zeroBlocks = TextGrouper.groupCharacters(pageNumber: 1, rawChars: zeroWidthChars);
      expect(zeroBlocks, isEmpty);
    });
  });
}
