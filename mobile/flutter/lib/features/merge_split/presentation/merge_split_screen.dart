import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class MergeSplitScreen extends StatelessWidget {
  final bool isEmbedded;

  const MergeSplitScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Fusionner & Diviser',
        showBackButton: !isEmbedded,
      ),
      body: EmptyState(
        title: 'Outils d\'assemblage PDF',
        message: 'Combinez plusieurs fichiers en un seul ou extrayez des pages spécifiques.',
        icon: Icons.call_split_rounded,
        actionLabel: 'Fusionner des PDF',
        onAction: () {},
      ),
    );
  }
}
