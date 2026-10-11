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

class CleanPdfScreen extends StatefulWidget {
  final PdfEngine? pdfEngine;
  final PdfiumEngine? pdfium;
  final NativeFilePicker? filePicker;
  final StorageService? storageService;

  const CleanPdfScreen({
    super.key,
    this.pdfEngine,
    this.pdfium,
    this.filePicker,
    this.storageService,
  });

  @override
  State<CleanPdfScreen> createState() => _CleanPdfScreenState();
}

class _CleanPdfScreenState extends State<CleanPdfScreen> {
  late final PdfEngine _pdfEngine;
  late final PdfiumEngine _pdfium;
  late final NativeFilePicker _filePicker;
  late final StorageService _storageService;

  String? _selectedPdfPath;
  String? _fileName;
  int? _initialSizeBytes;
  int? _pageCount;

  bool _isCleaning = false;
  String? _cleanedPath;
  int? _cleanedSizeBytes;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pdfium = widget.pdfium ?? PdfiumEngine();
    _pdfEngine = widget.pdfEngine ?? HybridPdfEngine(pdfiumEngine: _pdfium);
    _filePicker = widget.filePicker ?? NativeFilePicker();
    _storageService = widget.storageService ?? LocalStorageService();
  }

  Future<void> _pickFile() async {
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
      _selectedPdfPath = path;
      _fileName = file.uri.pathSegments.last;
      _initialSizeBytes = file.lengthSync();
      _pageCount = pages;
      _cleanedPath = null;
      _cleanedSizeBytes = null;
      _errorMessage = null;
    });
  }

  Future<void> _startCleaning() async {
    if (_selectedPdfPath == null) return;

    setState(() {
      _isCleaning = true;
      _errorMessage = null;
      _cleanedPath = null;
      _cleanedSizeBytes = null;
    });

    try {
      final tempDir = Directory.systemTemp;
      final base = _fileName?.replaceAll('.pdf', '') ?? 'document';
      final outPath = '${tempDir.path}/${base}_optimise_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final resultPath = await _pdfEngine.clean(_selectedPdfPath!, outPath);
      final outFile = File(resultPath);

      if (!await outFile.exists() || (await outFile.length()) == 0) {
        throw Exception('Service d\'optimisation avancé non disponible — vérifiez la connexion au serveur');
      }

      final outSize = await outFile.length();
      await _storageService.addRecentDocument(
        resultPath,
        name: '${base}_optimise.pdf',
        sizeBytes: outSize,
        pageCount: _pageCount,
      );

      if (mounted) {
        setState(() {
          _isCleaning = false;
          _cleanedPath = resultPath;
          _cleanedSizeBytes = outSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCleaning = false;
          _errorMessage = 'Service d\'optimisation avancé non disponible — vérifiez la connexion au serveur ($e)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Nettoyer et Optimiser'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            _buildSourceSection(),
            const SizedBox(height: AppDimensions.space16),
            if (_selectedPdfPath != null) ...[
              _buildActionSection(),
              const SizedBox(height: AppDimensions.space16),
            ],
            if (_errorMessage != null) ...[
              _buildErrorSection(),
              const SizedBox(height: AppDimensions.space16),
            ],
            if (_cleanedPath != null) ...[
              _buildSuccessSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSection() {
    if (_selectedPdfPath == null) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
          child: Column(
            children: [
              const Icon(Icons.cleaning_services_rounded, size: 48, color: AppColors.warningOrange),
              const SizedBox(height: AppDimensions.space12),
              const Text(
                'Optimisation & Nettoyage de PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppDimensions.space8),
              const Text(
                'Réduisez la taille de vos fichiers, supprimez les métadonnées obsolètes et nettoyez les objets inutilisés.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: AppDimensions.space16),
              AppButton(
                label: 'Choisir un PDF à optimiser',
                icon: Icons.folder_open_rounded,
                onPressed: _pickFile,
              ),
            ],
          ),
        ),
      );
    }

    final sizeKb = ((_initialSizeBytes ?? 0) / 1024).toStringAsFixed(1);

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.space8),
            decoration: BoxDecoration(
              color: AppColors.warningOrange.withAlpha(25),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: const Icon(Icons.picture_as_pdf, color: AppColors.warningOrange),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? 'Document PDF',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$_pageCount page(s) • $sizeKb Ko',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Changer de fichier',
            onPressed: _isCleaning ? null : _pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (_isCleaning) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
          child: Column(
            children: const [
              LinearProgressIndicator(),
              SizedBox(height: AppDimensions.space12),
              Text('Optimisation en cours...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    return AppButton(
      label: 'Lancer l\'optimisation',
      icon: Icons.cleaning_services_rounded,
      onPressed: _startCleaning,
    );
  }

  Widget _buildErrorSection() {
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
              _errorMessage ?? 'Erreur lors de l\'optimisation.',
              style: const TextStyle(fontSize: 13, color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessSection() {
    final originalKb = ((_initialSizeBytes ?? 0) / 1024).toStringAsFixed(1);
    final finalKb = ((_cleanedSizeBytes ?? 0) / 1024).toStringAsFixed(1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.successGreen),
              SizedBox(width: AppDimensions.space8),
              Text(
                'Optimisation terminée avec succès !',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Text('Taille initiale : $originalKb Ko', style: const TextStyle(fontSize: 13)),
          Text('Taille optimisée : $finalKb Ko', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Fichier : $_cleanedPath', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
