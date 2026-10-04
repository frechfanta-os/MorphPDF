import 'package:flutter/material.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/empty_state.dart';

class AiScreen extends StatelessWidget {
  final bool isEmbedded;

  const AiScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Assistant IA PDF',
        showBackButton: !isEmbedded,
      ),
      body: EmptyState(
        title: 'Intelligence Artificielle',
        message: 'Résumez vos documents, posez des questions, corrigez ou traduisez vos textes via OpenRouter.',
        icon: Icons.auto_awesome_rounded,
        actionLabel: 'Poser une question au document',
        onAction: () {},
      ),
    );
  }
}
