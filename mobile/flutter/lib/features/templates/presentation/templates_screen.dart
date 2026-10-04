import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Modèles de documents'),
      body: EmptyState(
        title: 'Bibliothèque de Modèles',
        message: 'Accédez à des modèles prêts à l\'emploi (factures, devis, contrats, attestations).',
        icon: Icons.dashboard_customize_rounded,
        actionLabel: 'Explorer les modèles',
        onAction: () {},
      ),
    );
  }
}
