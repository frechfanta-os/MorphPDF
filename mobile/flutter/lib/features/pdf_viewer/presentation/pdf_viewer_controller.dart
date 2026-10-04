import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/document.dart';
import '../../../shared/models/page_model.dart';
import '../../../shared/models/text_block.dart';
import '../domain/pdf_engine.dart';

class PdfViewerState {
  final String? filePath;
  final DocumentModel? document;
  final List<PageModel> pages;
  final int currentPage; // 1-indexed
  final int totalPages;
  final double zoomLevel;
  final bool isLoading;
  final String? errorMessage;
  final bool showThumbnails;
  final Uint8List? currentPageImage;
  final Map<int, Uint8List> thumbnails;
  final List<TextBlock> currentTextBlocks;
  final bool showTextOverlay;

  const PdfViewerState({
    this.filePath,
    this.document,
    this.pages = const [],
    this.currentPage = 1,
    this.totalPages = 1,
    this.zoomLevel = 1.0,
    this.isLoading = false,
    this.errorMessage,
    this.showThumbnails = false,
    this.currentPageImage,
    this.thumbnails = const {},
    this.currentTextBlocks = const [],
    this.showTextOverlay = false,
  });

  PdfViewerState copyWith({
    String? filePath,
    DocumentModel? document,
    List<PageModel>? pages,
    int? currentPage,
    int? totalPages,
    double? zoomLevel,
    bool? isLoading,
    String? errorMessage,
    bool? showThumbnails,
    Uint8List? currentPageImage,
    Map<int, Uint8List>? thumbnails,
    List<TextBlock>? currentTextBlocks,
    bool? showTextOverlay,
  }) {
    return PdfViewerState(
      filePath: filePath ?? this.filePath,
      document: document ?? this.document,
      pages: pages ?? this.pages,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      currentPageImage: currentPageImage ?? this.currentPageImage,
      thumbnails: thumbnails ?? this.thumbnails,
      currentTextBlocks: currentTextBlocks ?? this.currentTextBlocks,
      showTextOverlay: showTextOverlay ?? this.showTextOverlay,
    );
  }
}

final pdfEngineProvider = Provider<PdfEngine>((ref) => HybridPdfEngine());

class PdfViewerNotifier extends Notifier<PdfViewerState> {
  late PdfEngine _engine;

  @override
  PdfViewerState build() {
    _engine = ref.watch(pdfEngineProvider);
    return const PdfViewerState();
  }

  /// Loads a document from file path.
  Future<void> loadDocument(String filePath) async {
    state = state.copyWith(isLoading: true, errorMessage: null, filePath: filePath);

    try {
      final doc = await _engine.inspect(filePath);
      final pages = await _engine.getPages(filePath);
      final total = pages.isNotEmpty ? pages.length : doc.pageCount;

      state = state.copyWith(
        document: doc,
        pages: pages,
        currentPage: 1,
        totalPages: total,
      );

      await _renderCurrentPage();
      await _preloadThumbnails();
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Impossible d\'ouvrir le document : ${e.toString()}',
        );
      }
    }
  }

  /// Navigates to the next page.
  Future<void> nextPage() async {
    if (state.currentPage < state.totalPages) {
      await goToPage(state.currentPage + 1);
    }
  }

  /// Navigates to the previous page.
  Future<void> previousPage() async {
    if (state.currentPage > 1) {
      await goToPage(state.currentPage - 1);
    }
  }

  /// Navigates to a specific 1-indexed page number.
  Future<void> goToPage(int page) async {
    if (page < 1 || page > state.totalPages || page == state.currentPage) return;
    state = state.copyWith(currentPage: page, isLoading: true);
    await _renderCurrentPage();
    await _preloadThumbnails();
  }

  /// Sets zoom level.
  void setZoom(double zoom) {
    final clamped = zoom.clamp(0.5, 5.0);
    state = state.copyWith(zoomLevel: clamped);
  }

  /// Toggles thumbnail bottom drawer.
  void toggleThumbnails() {
    state = state.copyWith(showThumbnails: !state.showThumbnails);
    if (state.showThumbnails) {
      _preloadThumbnails();
    }
  }

  /// Toggles spatial text overlay.
  void toggleTextOverlay() {
    state = state.copyWith(showTextOverlay: !state.showTextOverlay);
  }

  Future<void> _renderCurrentPage() async {
    if (state.filePath == null) return;
    try {
      final imageBytes = await _engine.renderPage(state.filePath!, state.currentPage, dpi: 150);
      final textBlocks = await _engine.extractTextBlocks(state.filePath!, state.currentPage);

      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          currentPageImage: Uint8List.fromList(imageBytes),
          currentTextBlocks: textBlocks,
        );
      }
    } catch (e) {
      if (ref.mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Échec de rendu de la page : ${e.toString()}',
        );
      }
    }
  }

  Future<void> _preloadThumbnails() async {
    if (state.filePath == null) return;
    final Map<int, Uint8List> updated = Map.from(state.thumbnails);

    final start = (state.currentPage - 2).clamp(1, state.totalPages);
    final end = (state.currentPage + 2).clamp(1, state.totalPages);

    for (int p = start; p <= end; p++) {
      if (!updated.containsKey(p)) {
        try {
          final thumb = await _engine.renderThumbnail(state.filePath!, p, size: 100);
          updated[p] = Uint8List.fromList(thumb);
        } catch (_) {}
      }
    }
    if (ref.mounted) {
      state = state.copyWith(thumbnails: updated);
    }
  }
}

final pdfViewerControllerProvider =
    NotifierProvider<PdfViewerNotifier, PdfViewerState>(PdfViewerNotifier.new);
