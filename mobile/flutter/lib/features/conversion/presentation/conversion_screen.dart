import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class ConversionScreen extends StatelessWidget {
  const ConversionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Conversion PDF → Word'),
      body: EmptyState(
        title: 'Conversion DOCX',
        message: 'Convertit vos documents PDF en fichiers Word (.docx) éditables avec préservation des blocs.',
        icon: Icons.text_snippet_rounded,
        actionLabel: 'Convertir un document',
        onAction: () {},
      ),
    );
  }
}
