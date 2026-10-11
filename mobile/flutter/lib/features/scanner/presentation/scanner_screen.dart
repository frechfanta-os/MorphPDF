import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/platform/native_file_picker.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../ocr/presentation/ocr_screen.dart';

class ScannerScreen extends StatefulWidget {
  final NativeFilePicker? filePicker;

  const ScannerScreen({super.key, this.filePicker});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final NativeFilePicker _filePicker;

  @override
  void initState() {
    super.initState();
    _filePicker = widget.filePicker ?? NativeFilePicker();
  }

  Future<void> _importImageForOcr() async {
    final path = await _filePicker.pickImageFile();
    if (path != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OcrScreen(initialFilePath: path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Scanner de Documents'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.space20),
                decoration: BoxDecoration(
                  color: AppColors.aiViolet.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 56,
                  color: AppColors.aiViolet,
                ),
              ),
              const SizedBox(height: AppDimensions.space20),
              const Text(
                'Capture Caméra en Développement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.space12),
              const Text(
                'L\'intégration directe de la caméra pour le redressement automatique de documents est en cours de finalisation.\n\nEn attendant, vous pouvez importer une photo existante de votre galerie pour lancer immédiatement la reconnaissance OCR souveraine.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: AppDimensions.space24),
              AppButton(
                label: 'Importer une photo pour l\'OCR',
                icon: Icons.photo_library_outlined,
                onPressed: _importImageForOcr,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
