import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../shared/constants/app_constants.dart';

class OnboardingScreen extends StatelessWidget {
  final StorageService? storageService;

  const OnboardingScreen({super.key, this.storageService});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.space16),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(26),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_motion_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space24),
                      Text(
                        'Bienvenue sur\nMorphPDF',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        'Votre boîte à outils PDF complète, intelligente et respectueuse de la vie privée.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space32),
                      _buildFeatureRow(
                        icon: Icons.offline_bolt_rounded,
                        color: AppColors.primary,
                        title: 'Local-First & Gratuit',
                        subtitle: 'Opérations PDF, fusion, division et visualisation 100% sur l\'appareil.',
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      _buildFeatureRow(
                        icon: Icons.document_scanner_rounded,
                        color: AppColors.aiViolet,
                        title: 'OCR Multilingue',
                        subtitle: 'Reconnaissance de texte locale pour les langues latines et l\'arabe.',
                      ),
                      const SizedBox(height: AppDimensions.space16),
                      _buildFeatureRow(
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.successGreen,
                        title: 'Assistant IA Sécurisé',
                        subtitle: 'Analyse et correction via OpenRouter, avec protection totale des secrets.',
                      ),
                      const SizedBox(height: AppDimensions.space24),
                    ],
                  ),
                ),
              ),
              AppButton(
                label: 'Commencer',
                icon: Icons.arrow_forward_rounded,
                onPressed: () async {
                  final storage = storageService ?? LocalStorageService();
                  await storage.setOnboardingCompleted(true);
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed(AppConstants.routeHome);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.space8),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(icon, color: color, size: AppDimensions.iconSizeMedium),
        ),
        const SizedBox(width: AppDimensions.space16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: AppDimensions.space2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.lightTextSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
