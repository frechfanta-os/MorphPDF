import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/platform/native_file_picker.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../pdf_viewer/presentation/pdf_viewer_screen.dart';

class PdfEditorScreen extends StatefulWidget {
  final NativeFilePicker? filePicker;

  const PdfEditorScreen({super.key, this.filePicker});

  @override
  State<PdfEditorScreen> createState() => _PdfEditorScreenState();
}

class _PdfEditorScreenState extends State<PdfEditorScreen> {
  late final NativeFilePicker _filePicker;

  @override
  void initState() {
    super.initState();
    _filePicker = widget.filePicker ?? NativeFilePicker();
  }

  Future<void> _openPdfInViewer() async {
    final path = await _filePicker.pickPdfFile();
    if (path != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfViewerScreen(initialFilePath: path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Modifier le PDF'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_document,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimensions.space20),
              const Text(
                'Édition Visuelle & Annotations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.space12),
              const Text(
                'Les outils d\'annotation vectorielle (surlignage dynamique, dessin libre et signatures manuscrites) sont en cours de développement.\n\nVous pouvez dès maintenant ouvrir vos documents dans le lecteur PDFium haute performance pour examiner la géométrie des blocs et extraire le texte.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: AppDimensions.space24),
              AppButton(
                label: 'Ouvrir dans le visualiseur PDF',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: _openPdfInViewer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
