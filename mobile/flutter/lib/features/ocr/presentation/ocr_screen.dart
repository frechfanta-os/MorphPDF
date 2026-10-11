import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/ocr/ocr_models.dart';
import '../../../core/pdf/pdfium/pdfium_engine.dart';
import '../../../core/platform/native_file_picker.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../shared/models/text_block.dart';
import '../data/paddle_ocr_engine.dart';
import '../domain/ocr_service.dart';

class OcrScreen extends StatefulWidget {
  final OcrService? ocrService;
  final PdfiumEngine? pdfEngine;
  final NativeFilePicker? filePicker;
  final StorageService? storageService;
  final String? initialFilePath;

  const OcrScreen({
    super.key,
    this.ocrService,
    this.pdfEngine,
    this.filePicker,
    this.storageService,
    this.initialFilePath,
  });

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  late final OcrService _ocrService;
  late final PdfiumEngine _pdfEngine;
  late final NativeFilePicker _filePicker;
  late final StorageService _storageService;

  String? _selectedFilePath;
  String? _fileName;
  bool _isPdf = false;
  int _pageCount = 1;
  int _selectedPage = 1;
  bool _processAllPages = false;

  OcrMode _selectedMode = OcrMode.auto;
  bool _isRunning = false;
  double _progressFraction = 0.0;
  String _progressMessage = '';
  OcrCancellationToken? _cancellationToken;

  String? _extractedText;
  double? _averageConfidence;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ocrService = widget.ocrService ?? OcrService(PaddleOcrEngine());
    _pdfEngine = widget.pdfEngine ?? PdfiumEngine();
    _filePicker = widget.filePicker ?? NativeFilePicker();
    _storageService = widget.storageService ?? LocalStorageService();

    if (widget.initialFilePath != null && widget.initialFilePath!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSourceFile(widget.initialFilePath!);
      });
    }
  }

  Future<void> _loadSourceFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    final name = file.uri.pathSegments.last;
    final isPdf = name.toLowerCase().endsWith('.pdf');
    int pages = 1;

    if (isPdf) {
      try {
        final inspection = await _pdfEngine.inspect(path);
        pages = inspection.pageCount;
      } catch (_) {
        pages = 1;
      }
      await _storageService.addRecentDocument(
        path,
        name: name,
        sizeBytes: file.lengthSync(),
        pageCount: pages,
      );
    }

    if (mounted) {
      setState(() {
        _selectedFilePath = path;
        _fileName = name;
        _isPdf = isPdf;
        _pageCount = pages;
        _selectedPage = 1;
        _processAllPages = false;
        _extractedText = null;
        _errorMessage = null;
        _averageConfidence = null;
      });
    }
  }

  Future<void> _pickFile({bool imageOnly = false}) async {
    String? path;
    if (imageOnly) {
      path = await _filePicker.pickImageFile();
    } else {
      path = await _filePicker.pickSingleFile(mimeType: '*/*');
    }

    if (path != null && mounted) {
      await _loadSourceFile(path);
    }
  }

  Future<void> _runOcr() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _isRunning = true;
      _progressFraction = 0.0;
      _progressMessage = 'Initialisation de l\'OCR...';
      _errorMessage = null;
      _extractedText = null;
      _cancellationToken = OcrCancellationToken();
    });

    try {
      final List<TextBlock> allBlocks = [];

      if (_isPdf) {
        final pagesToProcess = _processAllPages
            ? List.generate(_pageCount, (i) => i + 1)
            : [_selectedPage];

        for (int i = 0; i < pagesToProcess.length; i++) {
          final pageNum = pagesToProcess[i];
          if (_cancellationToken?.isCancelled == true) {
            throw const OcrCancelledException();
          }

          final blocks = await _ocrService.extractTextFromPdfPage(
            pdfEngine: _pdfEngine,
            pdfPath: _selectedFilePath!,
            pageIndex: pageNum,
            mode: _selectedMode,
            cancellationToken: _cancellationToken,
            onProgress: (p) {
              if (mounted) {
                setState(() {
                  _progressFraction = _processAllPages
                      ? (i + p.fraction) / pagesToProcess.length
                      : p.fraction;
                  _progressMessage = p.statusMessage;
                });
              }
            },
          );
          allBlocks.addAll(blocks);
        }
      } else {
        // Image OCR
        final pageResult = await _ocrService.processPage(
          imagePath: _selectedFilePath!,
          pageIndex: 1,
          mode: _selectedMode,
          cancellationToken: _cancellationToken,
          onProgress: (p) {
            if (mounted) {
              setState(() {
                _progressFraction = p.fraction;
                _progressMessage = p.statusMessage;
              });
            }
          },
        );

        final blocks = pageResult.blocks.map((b) {
          return TextBlock(
            id: b.id,
            pageNumber: 1,
            text: b.text,
            x: b.boundingBox.left,
            y: b.boundingBox.top,
            width: b.boundingBox.width,
            height: b.boundingBox.height,
            confidence: b.confidence,
            language: b.language,
          );
        }).toList();

        allBlocks.addAll(blocks);
      }

      final fullText = allBlocks.map((b) => b.text).join('\n');
      double? avgConf;
      if (allBlocks.isNotEmpty) {
        avgConf = allBlocks.fold(0.0, (acc, b) => acc + b.confidence) / allBlocks.length;
      }

      if (mounted) {
        setState(() {
          _isRunning = false;
          _extractedText = fullText;
          _averageConfidence = avgConf;
        });
      }
    } on OcrCancelledException {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _progressMessage = 'Opération annulée par l\'utilisateur.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _cancelOcr() {
    _cancellationToken?.cancel();
  }

  Future<void> _copyToClipboard() async {
    if (_extractedText == null) return;
    await Clipboard.setData(ClipboardData(text: _extractedText!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Texte copié dans le presse-papiers'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _exportAsText() async {
    if (_extractedText == null) return;
    try {
      final base = _fileName?.split('.').first ?? 'ocr_result';
      final file = await _storageService.saveExport(
        '${base}_texte.txt',
        utf8.encode(_extractedText!),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Texte exporté dans ${file.path}'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'export : $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  bool _isArabicText(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Reconnaissance OCR'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            _buildSourceSection(),
            const SizedBox(height: AppDimensions.space16),
            if (_selectedFilePath != null) ...[
              _buildOptionsSection(),
              const SizedBox(height: AppDimensions.space20),
              _buildActionSection(),
              const SizedBox(height: AppDimensions.space20),
            ],
            if (_errorMessage != null) ...[
              _buildErrorSection(),
              const SizedBox(height: AppDimensions.space16),
            ],
            if (_extractedText != null) ...[
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSection() {
    if (_selectedFilePath == null) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
          child: Column(
            children: [
              const Icon(
                Icons.document_scanner_rounded,
                size: 48,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppDimensions.space12),
              const Text(
                'Sélectionnez une image ou un PDF',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppDimensions.space8),
              const Text(
                'Reconnaissance optique souveraine sans connexion via ONNX Runtime.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: AppDimensions.space16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppButton(
                    label: 'Choisir un PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    onPressed: () => _pickFile(imageOnly: false),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  AppButton(
                    label: 'Choisir une image',
                    icon: Icons.image_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: () => _pickFile(imageOnly: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.space8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              _isPdf ? Icons.picture_as_pdf : Icons.image,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fileName ?? 'Fichier sélectionné',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _isPdf ? 'Document PDF • $_pageCount page(s)' : 'Fichier image',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Changer de fichier',
            onPressed: _isRunning ? null : () => _pickFile(imageOnly: false),
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
            'Configuration de l\'OCR',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppDimensions.space12),
          DropdownButtonFormField<OcrMode>(
            initialValue: _selectedMode,
            decoration: const InputDecoration(
              labelText: 'Modèle linguistique',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: OcrMode.auto, child: Text('Détection automatique (Latin + Arabe)')),
              DropdownMenuItem(value: OcrMode.latin, child: Text('Français & Alphabet Latin')),
              DropdownMenuItem(value: OcrMode.arabic, child: Text('Arabe (avec réordonnancement BiDi)')),
            ],
            onChanged: _isRunning ? null : (mode) => setState(() => _selectedMode = mode ?? OcrMode.auto),
          ),
          if (_isPdf && _pageCount > 1) ...[
            const SizedBox(height: AppDimensions.space16),
            CheckboxListTile(
              title: const Text('Traiter toutes les pages', style: TextStyle(fontSize: 14)),
              subtitle: Text('Traitement séquentiel N=1 des $_pageCount pages', style: const TextStyle(fontSize: 12)),
              value: _processAllPages,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: _isRunning ? null : (val) => setState(() => _processAllPages = val ?? false),
            ),
            if (!_processAllPages) ...[
              const SizedBox(height: AppDimensions.space8),
              Row(
                children: [
                  const Text('Page à traiter : ', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: AppDimensions.space8),
                  DropdownButton<int>(
                    value: _selectedPage,
                    items: List.generate(_pageCount, (i) => i + 1).map((p) {
                      return DropdownMenuItem(value: p, child: Text('Page $p / $_pageCount'));
                    }).toList(),
                    onChanged: _isRunning ? null : (p) => setState(() => _selectedPage = p ?? 1),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (_isRunning) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
          child: Column(
            children: [
              LinearProgressIndicator(value: _progressFraction > 0 ? _progressFraction : null),
              const SizedBox(height: AppDimensions.space12),
              Text(
                _progressMessage,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.space12),
              AppButton(
                label: 'Annuler',
                variant: AppButtonVariant.danger,
                icon: Icons.cancel_outlined,
                onPressed: _cancelOcr,
              ),
            ],
          ),
        ),
      );
    }

    return AppButton(
      label: 'Lancer l\'OCR',
      icon: Icons.play_arrow_rounded,
      onPressed: _runOcr,
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
                  'Erreur lors de l\'OCR',
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

  Widget _buildResultsSection() {
    final text = _extractedText ?? '';
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final chars = text.length;
    final isRtl = _isArabicText(text);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Texte extrait',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    tooltip: 'Copier',
                    onPressed: _copyToClipboard,
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_alt_rounded, size: 20),
                    tooltip: 'Exporter en .txt',
                    onPressed: _exportAsText,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: AppDimensions.space8,
            children: [
              Chip(
                label: Text('$words mots', style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              ),
              Chip(
                label: Text('$chars caractères', style: const TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
              ),
              if (_averageConfidence != null)
                Chip(
                  label: Text('Confiance: ${(_averageConfidence! * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: Colors.grey.withAlpha(50)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text.isEmpty ? 'Aucun texte détecté dans le document.' : text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontFamily: isRtl ? 'sans-serif' : null,
                ),
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
