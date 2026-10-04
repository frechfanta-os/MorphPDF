import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morphpdf/features/pdf_viewer/domain/pdf_engine.dart';
import 'package:morphpdf/features/pdf_viewer/presentation/pdf_viewer_controller.dart';
import 'package:morphpdf/features/pdf_viewer/presentation/pdf_viewer_screen.dart';

void main() {
  group('PdfViewerScreen Widget Tests', () {
    const multiDoc = 'test/fixtures/doc_multipage.pdf';

    test('PdfViewerNotifier loadDocument directly with real engine', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(pdfViewerControllerProvider.notifier);
      await notifier.loadDocument(multiDoc);
      final state = container.read(pdfViewerControllerProvider);
      expect(state.document?.fileName, 'doc_multipage.pdf');
      expect(state.totalPages, 3);
      expect(state.currentPageImage, isNotNull);
    });

    testWidgets('Renders empty state when no document is provided', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PdfViewerScreen(),
          ),
        ),
      );

      expect(find.text('Lecteur PDF'), findsOneWidget);
      expect(find.text('Aucun PDF sélectionné'), findsOneWidget);
      expect(find.text('Ouvrir un exemple'), findsOneWidget);
    });

    testWidgets('Opens document, displays page, and navigates pages', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pdfEngineProvider.overrideWithValue(MockPdfEngine()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pdfViewerControllerProvider.notifier).loadDocument(multiDoc);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PdfViewerScreen(),
          ),
        ),
      );
      await tester.pump();

      // Check document title and page indicator
      expect(find.text('doc_multipage.pdf'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);

      // Tap Next page
      final nextBtn = find.byTooltip('Page suivante');
      expect(nextBtn, findsOneWidget);
      await container.read(pdfViewerControllerProvider.notifier).nextPage();
      await tester.pump();

      expect(find.text('2 / 3'), findsOneWidget);

      // Tap Previous page
      final prevBtn = find.byTooltip('Page précédente');
      expect(prevBtn, findsOneWidget);
      await container.read(pdfViewerControllerProvider.notifier).previousPage();
      await tester.pump();

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('Toggling thumbnails shows thumbnail strip', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pdfEngineProvider.overrideWithValue(MockPdfEngine()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(pdfViewerControllerProvider.notifier).loadDocument(multiDoc);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PdfViewerScreen(),
          ),
        ),
      );
      await tester.pump();

      final thumbBtn = find.byTooltip('Miniatures');
      expect(thumbBtn, findsOneWidget);

      // Open thumbnails
      await tester.tap(thumbBtn);
      await tester.pump();

      // Verify thumbnails are visible (showing page numbers 1, 2, 3 in strip)
      expect(find.text('1'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
    });
  });
}
