import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Exporter'),
      body: EmptyState(
        title: 'Exportation de documents',
        message: 'Partagez ou sauvegardez vos fichiers au format PDF, DOCX, TXT ou images.',
        icon: Icons.ios_share_rounded,
        actionLabel: 'Choisir un fichier à exporter',
        onAction: () {},
      ),
    );
  }
}
