import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class OcrScreen extends StatelessWidget {
  const OcrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Reconnaissance OCR'),
      body: EmptyState(
        title: 'Moteur OCR Local',
        message: 'Extraction de texte localement via Google ML Kit ou PaddleOCR sans connexion requise.',
        icon: Icons.document_scanner_rounded,
        actionLabel: 'Lancer une reconnaissance',
        onAction: () {},
      ),
    );
  }
}
