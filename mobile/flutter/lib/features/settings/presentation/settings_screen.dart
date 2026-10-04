import 'package:flutter/material.dart';
import '../../../app/config/app_config.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../shared/constants/app_constants.dart';

class SettingsScreen extends StatelessWidget {
  final bool isEmbedded;

  const SettingsScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Paramètres',
        showBackButton: !isEmbedded,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À propos de l\'application',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppDimensions.space8),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text(AppConstants.appName),
                  subtitle: Text('Version ${AppConstants.appVersion} • ${AppConstants.packageId}'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dns_outlined),
                  title: const Text('Environnement API'),
                  subtitle: Text('${AppConfig.current.environment.name} (${AppConfig.current.apiBaseUrl})'),
                ),
                const Divider(),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.security_outlined),
                  title: Text('Sécurité & Confidentialité'),
                  subtitle: Text('Traitement local prioritaire. Secrets gérés hors client mobile.'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
