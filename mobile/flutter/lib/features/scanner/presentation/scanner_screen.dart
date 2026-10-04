import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Scanner de Documents'),
      body: EmptyState(
        title: 'Scanner Caméra',
        message: 'Prenez en photo vos documents papier pour les convertir en PDF indexable et scannable par OCR.',
        icon: Icons.camera_alt_outlined,
        actionLabel: 'Activer la caméra',
        onAction: () {},
      ),
    );
  }
}
