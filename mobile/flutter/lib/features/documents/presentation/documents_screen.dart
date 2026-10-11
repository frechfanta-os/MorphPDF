import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/pdf/pdfium/pdfium_engine.dart';
import '../../../core/platform/native_file_picker.dart';
import '../../../core/storage/recent_document.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../pdf_viewer/presentation/pdf_viewer_screen.dart';

class DocumentsScreen extends StatefulWidget {
  final bool isEmbedded;
  final StorageService? storageService;
  final NativeFilePicker? filePicker;
  final PdfiumEngine? pdfEngine;

  const DocumentsScreen({
    super.key,
    this.isEmbedded = false,
    this.storageService,
    this.filePicker,
    this.pdfEngine,
  });

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> with SingleTickerProviderStateMixin {
  late final StorageService _storageService;
  late final NativeFilePicker _filePicker;
  late final PdfiumEngine _pdfEngine;
  late final TabController _tabController;

  List<RecentDocument> _recentDocs = [];
  List<File> _exportedFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? LocalStorageService();
    _filePicker = widget.filePicker ?? NativeFilePicker();
    _pdfEngine = widget.pdfEngine ?? PdfiumEngine();
    _tabController = TabController(length: 2, vsync: this);
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    try {
      final recents = await _storageService.getRecentDocuments();
      final exports = await _storageService.listExports();

      if (mounted) {
        setState(() {
          _recentDocs = recents;
          _exportedFiles = exports;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndOpenDocument() async {
    final path = await _filePicker.pickPdfFile();
    if (path == null) return;

    final file = File(path);
    if (!await file.exists()) return;

    final name = file.uri.pathSegments.last;
    final size = await file.length();
    int pages = 1;

    try {
      final inspection = await _pdfEngine.inspect(path);
      pages = inspection.pageCount;
    } catch (_) {
      pages = 1;
    }

    await _storageService.addRecentDocument(
      path,
      name: name,
      sizeBytes: size,
      pageCount: pages,
    );

    if (mounted) {
      _loadDocuments();
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfViewerScreen(initialFilePath: path),
        ),
      );
    }
  }

  Future<void> _removeRecent(RecentDocument doc) async {
    await _storageService.removeRecentDocument(doc.path);
    await _loadDocuments();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${doc.fileName} retiré de l\'historique'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () async {
              await _storageService.addRecentDocument(
                doc.path,
                name: doc.fileName,
                sizeBytes: doc.fileSize,
                pageCount: doc.pageCount,
              );
              _loadDocuments();
            },
          ),
        ),
      );
    }
  }

  void _openDocument(String path) {
    if (path.toLowerCase().endsWith('.pdf')) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfViewerScreen(initialFilePath: path),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouverture du fichier : $path')),
      );
    }
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Fichiers & Documents',
        showBackButton: !widget.isEmbedded,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Importer un PDF',
            onPressed: _pickAndOpenDocument,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Récents', icon: Icon(Icons.history_rounded)),
                Tab(text: 'Fichiers exportés', icon: Icon(Icons.folder_shared_rounded)),
              ],
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRecentsTab(),
                        _buildExportsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndOpenDocument,
        icon: const Icon(Icons.add),
        label: const Text('Importer un PDF'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRecentsTab() {
    if (_recentDocs.isEmpty) {
      return EmptyState(
        title: 'Aucun document récent',
        message: 'Importez un document PDF depuis votre stockage pour commencer la lecture ou le traitement.',
        icon: Icons.folder_open_rounded,
        actionLabel: 'Importer un PDF',
        onAction: _pickAndOpenDocument,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: _recentDocs.length,
      itemBuilder: (context, index) {
        final doc = _recentDocs[index];
        final sizeKb = (doc.fileSize / 1024).toStringAsFixed(1);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.space8),
          child: AppCard(
            onTap: () => _openDocument(doc.path),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${doc.pageCount} page(s) • $sizeKb Ko',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ouvert le ${_formatDate(doc.lastOpened)}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: Colors.grey),
                  tooltip: 'Retirer de la liste',
                  onPressed: () => _removeRecent(doc),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportsTab() {
    if (_exportedFiles.isEmpty) {
      return EmptyState(
        title: 'Aucun fichier exporté',
        message: 'Les documents convertis en Word ou les textes extraits apparaîtront ici.',
        icon: Icons.save_alt_rounded,
        actionLabel: 'Actualiser',
        onAction: _loadDocuments,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.space16),
      itemCount: _exportedFiles.length,
      itemBuilder: (context, index) {
        final file = _exportedFiles[index];
        final name = file.uri.pathSegments.last;
        final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
        final isDocx = name.toLowerCase().endsWith('.docx');
        final isPdf = name.toLowerCase().endsWith('.pdf');

        IconData icon = Icons.insert_drive_file_rounded;
        Color color = Colors.grey;
        if (isDocx) {
          icon = Icons.text_snippet_rounded;
          color = AppColors.successGreen;
        } else if (isPdf) {
          icon = Icons.picture_as_pdf_rounded;
          color = AppColors.primary;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.space8),
          child: AppCard(
            onTap: () => _openDocument(file.path),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space8),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$sizeKb Ko',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 20),
                  tooltip: 'Partager / Ouvrir',
                  onPressed: () => _openDocument(file.path),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
