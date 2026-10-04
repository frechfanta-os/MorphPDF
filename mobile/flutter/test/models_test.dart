import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/shared/enums/document_status.dart';
import 'package:morphpdf/shared/models/document.dart';
import 'package:morphpdf/shared/models/image_block.dart';
import 'package:morphpdf/shared/models/page_model.dart';
import 'package:morphpdf/shared/models/table_block.dart';
import 'package:morphpdf/shared/models/text_block.dart';

void main() {
  group('Document Model Serialization', () {
    test('DocumentModel converts to and from JSON', () {
      final now = DateTime.now();
      final doc = DocumentModel(
        id: 'doc-123',
        fileName: 'rapport.pdf',
        mimeType: 'application/pdf',
        fileSize: 2048,
        pageCount: 5,
        createdAt: now,
        updatedAt: now,
        status: DocumentStatus.ready,
      );

      final json = doc.toJson();
      final parsed = DocumentModel.fromJson(json);

      expect(parsed.id, doc.id);
      expect(parsed.fileName, doc.fileName);
      expect(parsed.fileSize, doc.fileSize);
      expect(parsed.pageCount, doc.pageCount);
      expect(parsed.status, DocumentStatus.ready);
    });

    test('PageModel serialization', () {
      const page = PageModel(pageNumber: 2, width: 595, height: 842, rotation: 90);
      final json = page.toJson();
      final parsed = PageModel.fromJson(json);

      expect(parsed.pageNumber, 2);
      expect(parsed.width, 595.0);
      expect(parsed.height, 842.0);
      expect(parsed.rotation, 90);
    });

    test('TextBlock coordinates and serialization', () {
      const block = TextBlock(
        id: 'tb-1',
        pageNumber: 1,
        text: 'MorphPDF Architecture',
        x: 50.0,
        y: 100.0,
        width: 200.0,
        height: 25.0,
        confidence: 0.99,
        language: 'fr',
      );

      final json = block.toJson();
      final parsed = TextBlock.fromJson(json);

      expect(parsed.id, 'tb-1');
      expect(parsed.text, 'MorphPDF Architecture');
      expect(parsed.confidence, 0.99);
      expect(parsed.language, 'fr');
    });

    test('ImageBlock and TableBlock serialization', () {
      const img = ImageBlock(
        id: 'img-1',
        pageNumber: 1,
        x: 0,
        y: 0,
        width: 100,
        height: 100,
        source: 'img.png',
      );
      final imgParsed = ImageBlock.fromJson(img.toJson());
      expect(imgParsed.source, 'img.png');

      const tbl = TableBlock(
        id: 'tbl-1',
        pageNumber: 1,
        x: 10,
        y: 20,
        width: 400,
        height: 200,
        rows: 4,
        columns: 3,
      );
      final tblParsed = TableBlock.fromJson(tbl.toJson());
      expect(tblParsed.rows, 4);
      expect(tblParsed.columns, 3);
    });

    test('DocumentStatus string conversions', () {
      expect(DocumentStatus.fromString('pending'), DocumentStatus.pending);
      expect(DocumentStatus.fromString('processing'), DocumentStatus.processing);
      expect(DocumentStatus.fromString('ready'), DocumentStatus.ready);
      expect(DocumentStatus.fromString('error'), DocumentStatus.error);
      expect(DocumentStatus.fromString('unknown'), DocumentStatus.pending);
    });
  });
}
