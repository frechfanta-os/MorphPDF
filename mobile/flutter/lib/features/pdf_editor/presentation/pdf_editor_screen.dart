import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class PdfEditorScreen extends StatelessWidget {
  const PdfEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Modifier le PDF'),
      body: EmptyState(
        title: 'Éditeur visuel PDF',
        message: 'L\'éditeur interactif permet d\'éditer les blocs de texte, les images et les annotations.',
        icon: Icons.edit_document,
        actionLabel: 'Choisir un document à modifier',
        onAction: () {},
      ),
    );
  }
}
