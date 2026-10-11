import 'dart:convert';
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
import '../../conversion/presentation/conversion_screen.dart';

class ExportScreen extends StatefulWidget {
  final NativeFilePicker? filePicker;
  final StorageService? storageService;
  final PdfiumEngine? pdfEngine;

  const ExportScreen({
    super.key,
    this.filePicker,
    this.storageService,
    this.pdfEngine,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  late final NativeFilePicker _filePicker;
  late final StorageService _storageService;
  late final PdfiumEngine _pdfEngine;

  String? _selectedFilePath;
  String? _fileName;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _filePicker = widget.filePicker ?? NativeFilePicker();
    _storageService = widget.storageService ?? LocalStorageService();
    _pdfEngine = widget.pdfEngine ?? PdfiumEngine();
  }

  Future<void> _pickFile() async {
    final path = await _filePicker.pickPdfFile();
    if (path == null) return;
    final file = File(path);
    if (!await file.exists()) return;

    setState(() {
      _selectedFilePath = path;
      _fileName = file.uri.pathSegments.last;
    });
  }

  Future<void> _exportAsWord() async {
    if (_selectedFilePath == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversionScreen(initialPdfPath: _selectedFilePath),
      ),
    );
  }

  Future<void> _exportAsPlainText() async {
    if (_selectedFilePath == null) return;
    setState(() => _isProcessing = true);

    try {
      final pages = await _pdfEngine.getPages(_selectedFilePath!);
      final buffer = StringBuffer();

      for (int i = 1; i <= pages.length; i++) {
        buffer.writeln('--- PAGE $i ---');
        final text = await _pdfEngine.extractText(_selectedFilePath!, i);
        buffer.writeln(text);
        buffer.writeln();
      }

      final base = _fileName?.replaceAll('.pdf', '') ?? 'document';
      final file = await _storageService.saveExport(
        '${base}_texte_brut.txt',
        utf8.encode(buffer.toString()),
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Texte brut exporté dans ${file.path}'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'extraction : $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Exporter'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            _buildSourceCard(),
            const SizedBox(height: AppDimensions.space20),
            if (_selectedFilePath != null) ...[
              Text(
                'Formats d\'export disponibles',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.space12),
              _buildExportOption(
                title: 'Microsoft Word (.docx)',
                subtitle: 'Convertit le PDF avec préservation des colonnes et des styles',
                icon: Icons.text_snippet_rounded,
                color: AppColors.successGreen,
                onTap: _isProcessing ? null : _exportAsWord,
              ),
              const SizedBox(height: AppDimensions.space12),
              _buildExportOption(
                title: 'Texte Brut (.txt)',
                subtitle: 'Extrait l\'intégralité du texte sans mise en forme',
                icon: Icons.notes_rounded,
                color: AppColors.primary,
                onTap: _isProcessing ? null : _exportAsPlainText,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard() {
    if (_selectedFilePath == null) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
          child: Column(
            children: [
              const Icon(Icons.ios_share_rounded, size: 48, color: AppColors.primary),
              const SizedBox(height: AppDimensions.space12),
              const Text(
                'Sélectionnez un document à exporter',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppDimensions.space8),
              const Text(
                'Convertissez ou extrayez vos documents vers différents formats éditables.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: AppDimensions.space16),
              AppButton(
                label: 'Choisir un fichier',
                icon: Icons.folder_open_rounded,
                onPressed: _pickFile,
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
            child: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              _fileName ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Changer',
            onPressed: _pickFile,
          ),
        ],
      ),
    );
  }

  Widget _buildExportOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }
}
