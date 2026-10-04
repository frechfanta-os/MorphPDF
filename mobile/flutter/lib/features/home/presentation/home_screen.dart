import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../shared/constants/app_constants.dart';
import '../../ai/presentation/ai_screen.dart';
import '../../documents/presentation/documents_screen.dart';
import '../../merge_split/presentation/merge_split_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeDashboardView(),
      const DocumentsScreen(isEmbedded: true),
      const MergeSplitScreen(isEmbedded: true),
      const AiScreen(isEmbedded: true),
      const SettingsScreen(isEmbedded: true),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _navIndex,
        onTap: (index) {
          setState(() {
            _navIndex = index;
          });
        },
      ),
    );
  }
}

class HomeDashboardView extends StatelessWidget {
  const HomeDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: AppConstants.appName,
        showBackButton: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            // Hero banner
            Container(
              padding: const EdgeInsets.all(AppDimensions.space20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenue sur MorphPDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'Traitement PDF local-first, OCR puissant et IA intégrée.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space24),
            Text(
              'Actions Rapides',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.space12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppDimensions.space12,
              crossAxisSpacing: AppDimensions.space12,
              childAspectRatio: 1.3,
              children: [
                _buildActionCard(
                  context,
                  title: 'Ouvrir un PDF',
                  icon: Icons.folder_open_rounded,
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).pushNamed(AppConstants.routePdfViewer),
                ),
                _buildActionCard(
                  context,
                  title: 'Scanner OCR',
                  icon: Icons.document_scanner_rounded,
                  color: AppColors.aiViolet,
                  onTap: () => Navigator.of(context).pushNamed(AppConstants.routeScanner),
                ),
                _buildActionCard(
                  context,
                  title: 'Modifier PDF',
                  icon: Icons.edit_document,
                  color: AppColors.primaryLight,
                  onTap: () => Navigator.of(context).pushNamed(AppConstants.routePdfEditor),
                ),
                _buildActionCard(
                  context,
                  title: 'Assistant IA',
                  icon: Icons.auto_awesome_rounded,
                  color: AppColors.aiVioletDark,
                  onTap: () => Navigator.of(context).pushNamed(AppConstants.routeAi),
                ),
                _buildActionCard(
                  context,
                  title: 'Nettoyer PDF',
                  icon: Icons.cleaning_services_rounded,
                  color: AppColors.warningOrange,
                  onTap: () => Navigator.of(context).pushNamed(AppConstants.routeCleanPdf),
                ),
                _buildActionCard(
                  context,
                  title: 'Fusion / Division',
                  icon: Icons.call_split_rounded,
                  color: AppColors.primary,
                  onTap: () => Navigator.of(context).pushNamed(AppConstants.routeMergeSplit),
                ),
                _buildActionCard(
                  context,
                  title: 'PDF → Word',
                  icon: Icons.text_snippet_rounded,
                  color: AppColors.successGreen,
                  onTap: () => Navigator.of(context).pushNamed(AppConstants.routeConversion),
                ),
                _buildActionCard(
                  context,
                  title: 'Modèles',
                  icon: Icons.dashboard_customize_rounded,
                  color: AppColors.primaryLight,
                  onTap: () => Navigator.of(context).pushNamed(AppConstants.routeTemplates),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.space8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, color: color, size: AppDimensions.iconSizeMedium),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
