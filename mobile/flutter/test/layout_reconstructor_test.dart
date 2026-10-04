import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/core/docx/layout/docx_elements.dart';
import 'package:morphpdf/core/docx/layout/layout_reconstructor.dart';
import 'package:morphpdf/shared/models/page_model.dart';
import 'package:morphpdf/shared/models/table_block.dart';
import 'package:morphpdf/shared/models/text_block.dart';

void main() {
  group('Layout Reconstructor Tests', () {
    const page = PageModel(pageNumber: 1, width: 595.0, height: 842.0);

    test('Single column top-to-bottom reading order and paragraph fusion', () {
      // In PDF coordinates, top of page has high Y (e.g. 800)
      final blocks = [
        const TextBlock(
          id: 'tb1',
          pageNumber: 1,
          text: 'Title of the Document',
          x: 100,
          y: 750,
          width: 250,
          height: 18.0, // Large height -> Heading
        ),
        const TextBlock(
          id: 'tb2',
          pageNumber: 1,
          text: 'First line of the body paragraph.',
          x: 100,
          y: 700,
          width: 300,
          height: 11.0,
        ),
        const TextBlock(
          id: 'tb3',
          pageNumber: 1,
          text: 'Second line of the same body paragraph.',
          x: 100,
          y: 686, // Delta Y = 14 <= 11 * 1.6 -> Fused!
          width: 280,
          height: 11.0,
        ),
        const TextBlock(
          id: 'tb4',
          pageNumber: 1,
          text: 'A completely new paragraph further down.',
          x: 100,
          y: 620, // Delta Y = 66 -> New paragraph!
          width: 300,
          height: 11.0,
        ),
      ];

      final elements = LayoutReconstructor.reconstructPage(
        page: page,
        textBlocks: blocks,
      );

      expect(elements.length, 3);

      // Element 1: Heading
      final e1 = elements[0] as DocxParagraph;
      expect(e1.styleId, 'Heading1');
      expect(e1.fullText, 'Title of the Document');

      // Element 2: Fused paragraph
      final e2 = elements[1] as DocxParagraph;
      expect(e2.styleId, 'Normal');
      expect(e2.fullText, contains('First line'));
      expect(e2.fullText, contains('Second line'));

      // Element 3: Separated paragraph
      final e3 = elements[2] as DocxParagraph;
      expect(e3.fullText, contains('A completely new paragraph'));
    });

    test('Multi-column detection and LTR reading order', () {
      // 2 columns separated by a central gutter between x=280 and x=320 (gap=40 pt)
      final blocks = [
        // Left Column (Col 1)
        const TextBlock(id: 'c1_l1', pageNumber: 1, text: 'Col 1 Line 1', x: 50, y: 700, width: 200, height: 11),
        const TextBlock(id: 'c1_l2', pageNumber: 1, text: 'Col 1 Line 2', x: 50, y: 650, width: 200, height: 11),

        // Right Column (Col 2)
        const TextBlock(id: 'c2_l1', pageNumber: 1, text: 'Col 2 Line 1', x: 340, y: 700, width: 200, height: 11),
        const TextBlock(id: 'c2_l2', pageNumber: 1, text: 'Col 2 Line 2', x: 340, y: 650, width: 200, height: 11),
      ];

      final elements = LayoutReconstructor.reconstructPage(
        page: page,
        textBlocks: blocks,
      );

      final texts = elements.whereType<DocxParagraph>().map((p) => p.fullText).toList();
      // LTR: Col 1 should be read completely before Col 2
      expect(texts[0], contains('Col 1 Line 1'));
      expect(texts[1], contains('Col 1 Line 2'));
      expect(texts[2], contains('Col 2 Line 1'));
      expect(texts[3], contains('Col 2 Line 2'));
    });

    test('Multi-column detection and RTL reading order for Arabic', () {
      // 2 columns with Arabic text: Right column should be read before Left column!
      final blocks = [
        // Left Column (Col 1 on the left)
        const TextBlock(id: 'ar_left_1', pageNumber: 1, text: 'العمود الأيسر سطر 1', x: 50, y: 700, width: 200, height: 11),
        const TextBlock(id: 'ar_left_2', pageNumber: 1, text: 'العمود الأيسر سطر 2', x: 50, y: 650, width: 200, height: 11),

        // Right Column (Col 2 on the right)
        const TextBlock(id: 'ar_right_1', pageNumber: 1, text: 'العمود الأيمن سطر 1', x: 340, y: 700, width: 200, height: 11),
        const TextBlock(id: 'ar_right_2', pageNumber: 1, text: 'العمود الأيمن سطر 2', x: 340, y: 650, width: 200, height: 11),
      ];

      final elements = LayoutReconstructor.reconstructPage(
        page: page,
        textBlocks: blocks,
      );

      final texts = elements.whereType<DocxParagraph>().map((p) => p.fullText).toList();
      // RTL: Right Column must come first!
      expect(texts[0], contains('العمود الأيمن سطر 1'));
      expect(texts[1], contains('العمود الأيمن سطر 2'));
      expect(texts[2], contains('العمود الأيسر سطر 1'));
      expect(texts[3], contains('العمود الأيسر سطر 2'));
    });

    test('Reconstruct TableBlock into DocxTable with grid cells', () {
      const tableBlock = TableBlock(
        id: 'tbl_1',
        pageNumber: 1,
        x: 50,
        y: 400,
        width: 400,
        height: 100,
        rows: 2,
        columns: 2,
      );

      final insideBlocks = [
        const TextBlock(id: 'c00', pageNumber: 1, text: 'Header A', x: 60, y: 460, width: 80, height: 12),
        const TextBlock(id: 'c01', pageNumber: 1, text: 'Header B', x: 260, y: 460, width: 80, height: 12),
        const TextBlock(id: 'c10', pageNumber: 1, text: 'Data 1', x: 60, y: 410, width: 80, height: 12),
        const TextBlock(id: 'c11', pageNumber: 1, text: 'Data 2', x: 260, y: 410, width: 80, height: 12),
      ];

      final elements = LayoutReconstructor.reconstructPage(
        page: page,
        textBlocks: insideBlocks,
        tableBlocks: [tableBlock],
      );

      expect(elements.any((e) => e is DocxTable), isTrue);
      final docxTable = elements.firstWhere((e) => e is DocxTable) as DocxTable;

      expect(docxTable.rows.length, 2);
      expect(docxTable.rows[0].cells.length, 2);
      expect(docxTable.rows[0].cells[0].paragraphs.first.fullText, contains('Header A'));
      expect(docxTable.rows[0].cells[1].paragraphs.first.fullText, contains('Header B'));
      expect(docxTable.rows[1].cells[0].paragraphs.first.fullText, contains('Data 1'));
      expect(docxTable.rows[1].cells[1].paragraphs.first.fullText, contains('Data 2'));
    });
  });
}
