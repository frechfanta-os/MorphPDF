import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/ocr/ocr_models.dart';
import '../../../core/pdf/pdfium/pdfium_engine.dart';
import '../../../core/platform/native_file_picker.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../data/sovereign_pdf_to_word_converter.dart';
import '../domain/conversion_converter.dart';

class ConversionScreen extends StatefulWidget {
  final PdfToWordConverter? converter;
  final PdfiumEngine? pdfEngine;
  final NativeFilePicker? filePicker;
  final StorageService? storageService;
  final String? initialPdfPath;

  const ConversionScreen({
    super.key,
    this.converter,
    this.pdfEngine,
    this.filePicker,
    this.storageService,
    this.initialPdfPath,
  });

  @override
  State<ConversionScreen> createState() => _ConversionScreenState();
}

class _ConversionScreenState extends State<ConversionScreen> {
  late final PdfToWordConverter _converter;
  late final PdfiumEngine _pdfEngine;
  late final NativeFilePicker _filePicker;
  late final StorageService _storageService;

  String? _selectedPdfPath;
  String? _fileName;
  int? _fileSizeBytes;
  int? _pageCount;

  bool _preserveLayout = true;
  bool _detectTables = true;
  bool _ocrScannedPages = false;
  OcrMode _ocrMode = OcrMode.auto;

  bool _isConverting = false;
  String? _errorMessage;
  String? _outputDocxPath;
  int? _outputSizeBytes;

  @override
  void initState() {
    super.initState();
    _converter = widget.converter ?? SovereignPdfToWordConverter();
    _pdfEngine = widget.pdfEngine ?? PdfiumEngine();
    _filePicker = widget.filePicker ?? NativeFilePicker();
    _storageService = widget.storageService ?? LocalStorageService();

    if (widget.initialPdfPath != null && widget.initialPdfPath!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPdfDetails(widget.initialPdfPath!);
      });
    }
  }

  Future<void> _loadPdfDetails(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    final name = file.uri.pathSegments.last;
    final size = file.lengthSync();
    int pages = 1;

    if (mounted) {
      setState(() {
        _selectedPdfPath = path;
        _fileName = name;
        _fileSizeBytes = size;
        _pageCount = pages;
        _errorMessage = null;
        _outputDocxPath = null;
        _outputSizeBytes = null;
      });
    }

    try {
      final inspection = await _pdfEngine.inspect(path);
      pages = inspection.pageCount;
      if (mounted) {
        setState(() {
          _pageCount = pages;
        });
      }
    } catch (_) {
      pages = 1;
    }

    await _storageService.addRecentDocument(
      path,
      name: name,
      sizeBytes: size,
      pageCount: pages,
    );
  }

  Future<void> _pickFile() async {
    final path = await _filePicker.pickPdfFile();
    if (path != null && mounted) {
      await _loadPdfDetails(path);
    }
  }

  Future<void> _startConversion() async {
    if (_selectedPdfPath == null) return;

    setState(() {
      _isConverting = true;
      _errorMessage = null;
      _outputDocxPath = null;
      _outputSizeBytes = null;
    });

    try {
      final tempDir = Directory.systemTemp;
      final baseName = _fileName?.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '') ?? 'document';
      final outPath = '${tempDir.path}/${baseName}_${DateTime.now().millisecondsSinceEpoch}.docx';

      final resultPath = await _converter.convertPdfToWord(
        _selectedPdfPath!,
        outPath,
        options: ConversionOptions(
          preserveLayout: _preserveLayout,
          detectTables: _detectTables,
          ocrScannedPages: _ocrScannedPages,
          ocrMode: _ocrMode,
        ),
      );

      final outFile = File(resultPath);
      if (!outFile.existsSync()) {
        throw Exception('Le fichier DOCX n\'a pas pu être créé.');
      }

      final outSize = outFile.lengthSync();
      if (mounted) {
        setState(() {
          _outputDocxPath = resultPath;
          _outputSizeBytes = outSize;
          _isConverting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isConverting = false;
        });
      }
    }
  }

  Future<void> _exportDocument() async {
    if (_outputDocxPath == null) return;
    try {
      final file = File(_outputDocxPath!);
      final bytes = await file.readAsBytes();
      final baseName = _fileName?.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '') ?? 'document';
      final savedFile = await _storageService.saveExport('$baseName.docx', bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document enregistré dans les exports (${savedFile.path})'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export : $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Conversion PDF → Word'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            _buildSourceDocumentSection(),
            const SizedBox(height: AppDimensions.space16),
            if (_selectedPdfPath != null) ...[
              _buildOptionsSection(),
              const SizedBox(height: AppDimensions.space20),
              _buildConvertActionSection(),
              const SizedBox(height: AppDimensions.space20),
            ],
            if (_errorMessage != null) ...[
              _buildErrorSection(),
              const SizedBox(height: AppDimensions.space16),
            ],
            if (_outputDocxPath != null) ...[
              _buildSuccessSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceDocumentSection() {
    if (_selectedPdfPath == null) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
          child: Column(
            children: [
              const Icon(
                Icons.picture_as_pdf_rounded,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppDimensions.space12),
              const Text(
                'Sélectionnez un document PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppDimensions.space8),
              const Text(
                'Convertissez directement vos documents PDF en fichiers Microsoft Word (.docx) éditables.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: AppDimensions.space16),
              AppButton(
                label: 'Choisir un fichier PDF',
                icon: Icons.folder_open_rounded,
                onPressed: _pickFile,
              ),
            ],
          ),
        ),
      );
    }

    final sizeKb = ((_fileSizeBytes ?? 0) / 1024).toStringAsFixed(1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                ),
                child: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
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
                      '$_pageCount pages • $sizeKb Ko',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Changer de fichier',
                onPressed: _isConverting ? null : _pickFile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Options de conversion',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppDimensions.space8),
          CheckboxListTile(
            title: const Text('Préserver la mise en page fidèle', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Maintient les colonnes, positions et alignements spatiaux', style: TextStyle(fontSize: 12)),
            value: _preserveLayout,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: _isConverting ? null : (val) => setState(() => _preserveLayout = val ?? true),
          ),
          CheckboxListTile(
            title: const Text('Détection automatique des tableaux', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Reconstruit les grilles et cellules sous forme de tableaux Word', style: TextStyle(fontSize: 12)),
            value: _detectTables,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: _isConverting ? null : (val) => setState(() => _detectTables = val ?? true),
          ),
          CheckboxListTile(
            title: const Text('OCR sur pages scannées', style: TextStyle(fontSize: 14)),
            subtitle: const Text('Active la reconnaissance de caractères pour les pages images', style: TextStyle(fontSize: 12)),
            value: _ocrScannedPages,
            dense: true,
            contentPadding: EdgeInsets.zero,
            onChanged: _isConverting ? null : (val) => setState(() => _ocrScannedPages = val ?? false),
          ),
          if (_ocrScannedPages) ...[
            const SizedBox(height: AppDimensions.space8),
            DropdownButtonFormField<OcrMode>(
              initialValue: _ocrMode,
              decoration: const InputDecoration(
                labelText: 'Mode linguistique OCR',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: OcrMode.auto, child: Text('Détection automatique')),
                DropdownMenuItem(value: OcrMode.latin, child: Text('Français / Latin')),
                DropdownMenuItem(value: OcrMode.arabic, child: Text('Arabe (avec BiDi)')),
              ],
              onChanged: _isConverting ? null : (mode) => setState(() => _ocrMode = mode ?? OcrMode.auto),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConvertActionSection() {
    if (_isConverting) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
          child: Column(
            children: const [
              LinearProgressIndicator(),
              SizedBox(height: AppDimensions.space12),
              Text(
                'Conversion souveraine en cours...',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text(
                'Extraction PDFium, reconstruction spatiale et génération de l\'archive ECMA-376.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return AppButton(
      label: 'Convertir en Word (.docx)',
      icon: Icons.text_snippet_rounded,
      onPressed: _startConversion,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Échec de la conversion',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.errorRed),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage ?? 'Une erreur inconnue est survenue.',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessSection() {
    final sizeKb = ((_outputSizeBytes ?? 0) / 1024).toStringAsFixed(1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 28),
              SizedBox(width: AppDimensions.space8),
              Text(
                'Conversion réussie !',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.successGreen),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(
            'Fichier Word : ${_fileName?.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '')}.docx',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text('Taille : $sizeKb Ko', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            'Chemin : $_outputDocxPath',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.space16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Sauvegarder',
                  icon: Icons.save_alt_rounded,
                  onPressed: _exportDocument,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: AppButton(
                  label: 'Nouveau',
                  variant: AppButtonVariant.outline,
                  icon: Icons.add_circle_outline,
                  onPressed: () {
                    setState(() {
                      _selectedPdfPath = null;
                      _outputDocxPath = null;
                      _outputSizeBytes = null;
                      _errorMessage = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
