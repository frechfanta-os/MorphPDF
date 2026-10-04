import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class CleanPdfScreen extends StatelessWidget {
  const CleanPdfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Nettoyer et Optimiser'),
      body: EmptyState(
        title: 'Optimisation de document',
        message: 'Suppression des métadonnées, compression des images et réduction du poids du fichier.',
        icon: Icons.cleaning_services_rounded,
        actionLabel: 'Choisir un PDF à optimiser',
        onAction: () {},
      ),
    );
  }
}
