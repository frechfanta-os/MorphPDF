import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_state.dart';
import 'pdf_viewer_controller.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String? initialFilePath;

  const PdfViewerScreen({super.key, this.initialFilePath});

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final TransformationController _transformController = TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialFilePath != null) {
        ref.read(pdfViewerControllerProvider.notifier).loadDocument(widget.initialFilePath!);
      }
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      _transformController.value = Matrix4.diagonal3Values(2.0, 2.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pdfViewerControllerProvider);
    final theme = Theme.of(context);

    // Empty state if no document is loaded
    if (state.filePath == null && !state.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Lecteur PDF'),
          centerTitle: true,
        ),
        body: EmptyState(
          title: 'Aucun PDF sélectionné',
          message: 'Sélectionnez un document PDF pour visualiser son contenu et ses pages.',
          icon: Icons.picture_as_pdf_outlined,
          actionLabel: 'Ouvrir un exemple',
          onAction: () {
            // Find sample fixture
            const fixture = 'test/fixtures/doc_multipage.pdf';
            if (File(fixture).existsSync()) {
              ref.read(pdfViewerControllerProvider.notifier).loadDocument(fixture);
            }
          },
        ),
      );
    }

    final docTitle = state.document?.fileName ?? 'Document PDF';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          docTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Métadonnées du document',
            onPressed: () => _showDocumentInfo(context, state),
          ),
          IconButton(
            icon: Icon(
              state.showTextOverlay ? Icons.text_snippet : Icons.text_snippet_outlined,
              color: state.showTextOverlay ? AppColors.primary : null,
            ),
            tooltip: 'Texte & Géométrie',
            onPressed: () => _showTextBlocks(context, state),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main PDF Page Viewer
          Expanded(
            child: Stack(
              children: [
                if (state.errorMessage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.space24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorRed),
                          const SizedBox(height: AppDimensions.space12),
                          Text(state.errorMessage!, textAlign: TextAlign.center),
                          const SizedBox(height: AppDimensions.space16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Réessayer'),
                            onPressed: () {
                              if (state.filePath != null) {
                                ref.read(pdfViewerControllerProvider.notifier).loadDocument(state.filePath!);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state.currentPageImage != null)
                  GestureDetector(
                    onDoubleTap: _onDoubleTap,
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(AppDimensions.space16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(30),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                                child: Image.memory(
                                  state.currentPageImage!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Loading overlay while rendering
                if (state.isLoading)
                  Container(
                    color: Colors.black.withAlpha(40),
                    child: const Center(
                      child: LoadingState(message: 'Rendu de la page...'),
                    ),
                  ),
              ],
            ),
          ),

          // Thumbnail strip drawer
          if (state.showThumbnails)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space8, vertical: AppDimensions.space8),
                itemCount: state.totalPages,
                itemBuilder: (context, index) {
                  final pageNum = index + 1;
                  final isCurrent = pageNum == state.currentPage;
                  final thumb = state.thumbnails[pageNum];

                  return GestureDetector(
                    onTap: () {
                      ref.read(pdfViewerControllerProvider.notifier).goToPage(pageNum);
                    },
                    child: Container(
                      width: 75,
                      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isCurrent ? AppColors.primary : Colors.grey.withAlpha(80),
                          width: isCurrent ? 2.5 : 1.0,
                        ),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        color: Colors.white,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: thumb != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall - 2),
                                    child: Image.memory(thumb, fit: BoxFit.cover),
                                  )
                                : const Center(child: Icon(Icons.description_outlined, size: 24, color: Colors.grey)),
                          ),
                          Container(
                            color: isCurrent ? AppColors.primary : Colors.grey.withAlpha(40),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '$pageNum',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bottom Control Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
                    tooltip: 'Page précédente',
                    onPressed: state.currentPage > 1
                        ? () => ref.read(pdfViewerControllerProvider.notifier).previousPage()
                        : null,
                  ),
                  InkWell(
                    onTap: () => _showJumpToPageDialog(context, state),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space12, vertical: AppDimensions.space8),
                      child: Text(
                        '${state.currentPage} / ${state.totalPages}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
                    tooltip: 'Page suivante',
                    onPressed: state.currentPage < state.totalPages
                        ? () => ref.read(pdfViewerControllerProvider.notifier).nextPage()
                        : null,
                  ),
                  IconButton(
                    icon: Icon(
                      state.showThumbnails ? Icons.view_sidebar_rounded : Icons.view_sidebar_outlined,
                      color: state.showThumbnails ? AppColors.primary : null,
                    ),
                    tooltip: 'Miniatures',
                    onPressed: () => ref.read(pdfViewerControllerProvider.notifier).toggleThumbnails(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showJumpToPageDialog(BuildContext context, PdfViewerState state) {
    int target = state.currentPage;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aller à la page'),
          content: TextField(
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: '1 à ${state.totalPages}',
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) {
              target = int.tryParse(val) ?? state.currentPage;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(pdfViewerControllerProvider.notifier).goToPage(target);
              },
              child: const Text('Aller'),
            ),
          ],
        );
      },
    );
  }

  void _showDocumentInfo(BuildContext context, PdfViewerState state) {
    final doc = state.document;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations sur le document',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.space16),
              _buildInfoRow('Nom', doc?.fileName ?? '-'),
              _buildInfoRow('Pages', '${state.totalPages}'),
              _buildInfoRow('Taille', '${((doc?.fileSize ?? 0) / 1024).toStringAsFixed(1)} Ko'),
              _buildInfoRow('Emplacement', state.filePath ?? '-'),
              const SizedBox(height: AppDimensions.space16),
            ],
          ),
        );
      },
    );
  }

  void _showTextBlocks(BuildContext context, PdfViewerState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(AppDimensions.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Texte extrait (Page ${state.currentPage})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${state.currentTextBlocks.length} blocs',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Expanded(
                    child: state.currentTextBlocks.isEmpty
                        ? const Center(child: Text('Aucun texte extrait sur cette page.'))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: state.currentTextBlocks.length,
                            separatorBuilder: (_, _) => const Divider(),
                            itemBuilder: (context, i) {
                              final block = state.currentTextBlocks[i];
                              return ListTile(
                                dense: true,
                                title: Text(block.text, style: const TextStyle(fontSize: 14)),
                                subtitle: Text(
                                  'x: ${block.x.toStringAsFixed(1)}, y: ${block.y.toStringAsFixed(1)}, w: ${block.width.toStringAsFixed(1)}, h: ${block.height.toStringAsFixed(1)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
