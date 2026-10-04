import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Lecteur PDF'),
      body: EmptyState(
        title: 'Aucun PDF sélectionné',
        message: 'Sélectionnez un document PDF pour visualiser son contenu et ses pages.',
        icon: Icons.picture_as_pdf_outlined,
        actionLabel: 'Sélectionner un fichier',
        onAction: () {},
      ),
    );
  }
}
