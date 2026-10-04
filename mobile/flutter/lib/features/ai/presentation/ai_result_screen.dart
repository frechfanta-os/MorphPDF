import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../domain/document_analysis_model.dart';

class AiResultScreen extends StatelessWidget {
  final DocumentAnalysisModel result;
  final int pageCount;

  const AiResultScreen({
    super.key,
    required this.result,
    this.pageCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppTopBar(title: 'Rapport d\'analyse IA'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            // Header summary card
            AppCard(
              color: AppColors.aiViolet.withAlpha(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppDimensions.space8),
                        decoration: BoxDecoration(
                          color: AppColors.aiViolet,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.documentType,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Langue: ${result.language.toUpperCase()} • $pageCount page(s)',
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Text(
                    'Résumé Exécutif',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    result.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Important Information
            if (result.importantInformation.isNotEmpty)
              _buildSectionCard(
                context,
                title: 'Informations Importantes',
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
                items: result.importantInformation,
              ),

            // Dates & Amounts
            if (result.dates.isNotEmpty || result.amounts.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.dates.isNotEmpty)
                    Expanded(
                      child: _buildSectionCard(
                        context,
                        title: 'Dates Clés',
                        icon: Icons.calendar_today_rounded,
                        iconColor: AppColors.primaryLight,
                        items: result.dates,
                      ),
                    ),
                  if (result.dates.isNotEmpty && result.amounts.isNotEmpty)
                    const SizedBox(width: AppDimensions.space12),
                  if (result.amounts.isNotEmpty)
                    Expanded(
                      child: _buildSectionCard(
                        context,
                        title: 'Montants',
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.successGreen,
                        items: result.amounts,
                      ),
                    ),
                ],
              ),
            ],

            // People & Organizations
            if (result.people.isNotEmpty || result.organizations.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space16),
              _buildSectionCard(
                context,
                title: 'Entités (Personnes & Organisations)',
                icon: Icons.business_outlined,
                iconColor: AppColors.aiViolet,
                items: [
                  ...result.people.map((p) => 'Personne: $p'),
                  ...result.organizations.map((o) => 'Organisation: $o'),
                ],
              ),
            ],

            // Issues / Warnings
            if (result.issues.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space16),
              _buildSectionCard(
                context,
                title: 'Points d\'attention / Problèmes détectés',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warningOrange,
                items: result.issues,
              ),
            ],

            // Suggestions
            if (result.suggestions.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space16),
              _buildSectionCard(
                context,
                title: 'Suggestions & Actions Recommandées',
                icon: Icons.tips_and_updates_outlined,
                iconColor: AppColors.aiVioletDark,
                items: result.suggestions,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
