import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/pdf/pdfium/pdfium_engine.dart';
import '../../../core/platform/native_file_picker.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../pdf_viewer/domain/pdf_engine.dart';

class MergeSplitScreen extends StatefulWidget {
  final bool isEmbedded;
  final PdfEngine? pdfEngine;
  final PdfiumEngine? pdfium;
  final NativeFilePicker? filePicker;
  final StorageService? storageService;

  const MergeSplitScreen({
    super.key,
    this.isEmbedded = false,
    this.pdfEngine,
    this.pdfium,
    this.filePicker,
    this.storageService,
  });

  @override
  State<MergeSplitScreen> createState() => _MergeSplitScreenState();
}

class _MergeSplitScreenState extends State<MergeSplitScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final PdfEngine _pdfEngine;
  late final PdfiumEngine _pdfium;
  late final NativeFilePicker _filePicker;
  late final StorageService _storageService;

  // Merge state
  final List<String> _mergeFiles = [];
  bool _isMerging = false;
  String? _mergeError;
  String? _mergedOutputPath;
  int? _mergedSizeBytes;

  // Split state
  String? _splitSourcePdf;
  String? _splitFileName;
  int _splitPageCount = 0;
  final TextEditingController _rangeController = TextEditingController();
  bool _isSplitting = false;
  String? _splitError;
  List<String> _splitOutputFiles = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pdfium = widget.pdfium ?? PdfiumEngine();
    _pdfEngine = widget.pdfEngine ?? HybridPdfEngine(pdfiumEngine: _pdfium);
    _filePicker = widget.filePicker ?? NativeFilePicker();
    _storageService = widget.storageService ?? LocalStorageService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  // --- MERGE LOGIC ---

  Future<void> _pickMergeFiles() async {
    final paths = await _filePicker.pickPdfFiles();
    if (paths.isNotEmpty && mounted) {
      setState(() {
        for (final p in paths) {
          if (!_mergeFiles.contains(p)) {
            _mergeFiles.add(p);
          }
        }
        _mergeError = null;
        _mergedOutputPath = null;
      });
    }
  }

  Future<void> _executeMerge() async {
    if (_mergeFiles.length < 2) {
      setState(() {
        _mergeError = 'Veuillez sélectionner au moins 2 fichiers PDF à fusionner.';
      });
      return;
    }

    setState(() {
      _isMerging = true;
      _mergeError = null;
      _mergedOutputPath = null;
    });

    try {
      final tempDir = Directory.systemTemp;
      final outPath = '${tempDir.path}/fusion_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final resultPath = await _pdfEngine.merge(_mergeFiles, outPath);
      final outFile = File(resultPath);

      if (!await outFile.exists() || (await outFile.length()) == 0) {
        throw Exception('Service de traitement avancé non disponible — vérifiez la connexion au serveur');
      }

      final size = await outFile.length();
      await _storageService.addRecentDocument(
        resultPath,
        name: 'fusion_${DateTime.now().millisecondsSinceEpoch}.pdf',
        sizeBytes: size,
      );

      if (mounted) {
        setState(() {
          _isMerging = false;
          _mergedOutputPath = resultPath;
          _mergedSizeBytes = size;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isMerging = false;
          _mergeError = 'Service de traitement avancé non disponible — vérifiez la connexion au serveur ($e)';
        });
      }
    }
  }

  // --- SPLIT LOGIC ---

  Future<void> _pickSplitFile() async {
    final path = await _filePicker.pickPdfFile();
    if (path == null) return;

    final file = File(path);
    if (!await file.exists()) return;

    int pages = 1;
    try {
      final insp = await _pdfium.inspect(path);
      pages = insp.pageCount;
    } catch (_) {
      pages = 1;
    }

    setState(() {
      _splitSourcePdf = path;
      _splitFileName = file.uri.pathSegments.last;
      _splitPageCount = pages;
      _rangeController.text = pages > 1 ? '1-${pages > 3 ? 2 : pages}' : '1';
      _splitError = null;
      _splitOutputFiles = [];
    });
  }

  List<int> _parsePageRange(String input, int maxPages) {
    if (input.trim().isEmpty) {
      throw const FormatException('Veuillez saisir une plage de pages.');
    }

    final pages = <int>{};
    final parts = input.split(',');

    for (var part in parts) {
      part = part.trim();
      if (part.isEmpty) continue;

      if (part.contains('-')) {
        final bounds = part.split('-');
        if (bounds.length != 2) {
          throw FormatException('Syntaxe de plage invalide : "$part"');
        }
        final start = int.tryParse(bounds[0].trim());
        final end = int.tryParse(bounds[1].trim());

        if (start == null || end == null || start < 1 || end > maxPages || start > end) {
          throw FormatException('Plage invalide "$part" (le document contient $maxPages page(s))');
        }

        for (int p = start; p <= end; p++) {
          pages.add(p);
        }
      } else {
        final p = int.tryParse(part);
        if (p == null || p < 1 || p > maxPages) {
          throw FormatException('Page invalide "$part" (doit être entre 1 et $maxPages)');
        }
        pages.add(p);
      }
    }

    if (pages.isEmpty) {
      throw const FormatException('Aucune page valide sélectionnée.');
    }

    final sorted = pages.toList()..sort();
    return sorted;
  }

  Future<void> _executeSplit() async {
    if (_splitSourcePdf == null) return;

    List<int> pages;
    try {
      pages = _parsePageRange(_rangeController.text, _splitPageCount);
    } on FormatException catch (e) {
      setState(() => _splitError = e.message);
      return;
    }

    setState(() {
      _isSplitting = true;
      _splitError = null;
      _splitOutputFiles = [];
    });

    try {
      final tempDir = Directory.systemTemp;
      final outDir = '${tempDir.path}/split_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(outDir).create(recursive: true);

      final files = await _pdfEngine.split(_splitSourcePdf!, pages, outDir);

      if (files.isEmpty) {
        throw Exception('Service de traitement avancé non disponible — vérifiez la connexion au serveur');
      }

      if (mounted) {
        setState(() {
          _isSplitting = false;
          _splitOutputFiles = files;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSplitting = false;
          _splitError = 'Service de traitement avancé non disponible — vérifiez la connexion au serveur ($e)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Fusionner & Diviser',
        showBackButton: !widget.isEmbedded,
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
                Tab(text: 'Fusionner', icon: Icon(Icons.call_merge_rounded)),
                Tab(text: 'Diviser', icon: Icon(Icons.call_split_rounded)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMergeView(),
                  _buildSplitView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MERGE UI ---

  Widget _buildMergeView() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Documents à fusionner (${_mergeFiles.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  TextButton.icon(
                    onPressed: _isMerging ? null : _pickMergeFiles,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Ajouter des PDF'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space8),
              if (_mergeFiles.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppDimensions.space16),
                  child: Center(
                    child: Text(
                      'Aucun fichier sélectionné. Ajoutez au moins 2 fichiers PDF.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mergeFiles.length,
                  // ignore: deprecated_member_use
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _mergeFiles.removeAt(oldIndex);
                      _mergeFiles.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final path = _mergeFiles[index];
                    final name = File(path).uri.pathSegments.last;
                    return ListTile(
                      key: ValueKey(path),
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.primary.withAlpha(30),
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                      ),
                      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        onPressed: () => setState(() => _mergeFiles.removeAt(index)),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        if (_isMerging) ...[
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: AppDimensions.space12),
          const Center(child: Text('Fusion des documents en cours...')),
        ] else ...[
          AppButton(
            label: 'Fusionner les PDF (${_mergeFiles.length})',
            icon: Icons.call_merge_rounded,
            onPressed: _mergeFiles.length >= 2 ? _executeMerge : null,
          ),
        ],
        if (_mergeError != null) ...[
          const SizedBox(height: AppDimensions.space16),
          _buildErrorBox(_mergeError!),
        ],
        if (_mergedOutputPath != null) ...[
          const SizedBox(height: AppDimensions.space16),
          _buildMergeSuccessBox(),
        ],
      ],
    );
  }

  Widget _buildMergeSuccessBox() {
    final sizeKb = ((_mergedSizeBytes ?? 0) / 1024).toStringAsFixed(1);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
              SizedBox(width: AppDimensions.space8),
              Text('Fusion réussie !', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen)),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Text('Taille du document : $sizeKb Ko', style: const TextStyle(fontSize: 13)),
          Text('Emplacement : $_mergedOutputPath', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  // --- SPLIT UI ---

  Widget _buildSplitView() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_splitSourcePdf == null) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppDimensions.space12),
                    child: Text('Sélectionnez un document PDF à diviser.'),
                  ),
                ),
                Center(
                  child: AppButton(
                    label: 'Sélectionner un PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: _pickSplitFile,
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_splitFileName ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('$_splitPageCount page(s)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    TextButton(onPressed: _pickSplitFile, child: const Text('Changer')),
                  ],
                ),
                const SizedBox(height: AppDimensions.space16),
                TextField(
                  controller: _rangeController,
                  decoration: const InputDecoration(
                    labelText: 'Plages de pages à extraire',
                    hintText: 'Ex: 1-2, 4',
                    helperText: 'Séparez par des virgules (ex: 1-3, 5)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (_splitSourcePdf != null) ...[
          const SizedBox(height: AppDimensions.space16),
          if (_isSplitting) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: AppDimensions.space12),
            const Center(child: Text('Extraction des pages en cours...')),
          ] else ...[
            AppButton(
              label: 'Extraire les pages',
              icon: Icons.call_split_rounded,
              onPressed: _executeSplit,
            ),
          ],
        ],
        if (_splitError != null) ...[
          const SizedBox(height: AppDimensions.space16),
          _buildErrorBox(_splitError!),
        ],
        if (_splitOutputFiles.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.space16),
          _buildSplitSuccessBox(),
        ],
      ],
    );
  }

  Widget _buildSplitSuccessBox() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
              const SizedBox(width: AppDimensions.space8),
              Text(
                'Extraction réussie (${_splitOutputFiles.length} fichiers)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          ..._splitOutputFiles.map((file) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('• ${File(file).uri.pathSegments.last}', style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.errorRed.withAlpha(25),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.errorRed.withAlpha(100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.errorRed),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}
