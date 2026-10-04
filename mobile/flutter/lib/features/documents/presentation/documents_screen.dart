import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class DocumentsScreen extends StatelessWidget {
  final bool isEmbedded;

  const DocumentsScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Fichiers & Documents',
        showBackButton: !isEmbedded,
      ),
      body: EmptyState(
        title: 'Aucun document',
        message: 'Importez un document PDF ou numérisez une page avec la caméra pour commencer.',
        icon: Icons.folder_open_rounded,
        actionLabel: 'Importer un PDF',
        onAction: () {},
      ),
    );
  }
}
