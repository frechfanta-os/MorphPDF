import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/config/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../shared/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  final ApiClient? apiClient;

  const SettingsScreen({
    super.key,
    this.isEmbedded = false,
    this.apiClient,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final ApiClient _apiClient;
  bool _isLoadingStatus = false;
  String _aiStatus = 'Vérification...';
  String _aiModel = 'meta-llama/llama-3.3-70b-instruct:free';
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? ApiClient();
    _fetchAiStatus();
  }

  Future<void> _fetchAiStatus() async {
    setState(() => _isLoadingStatus = true);
    try {
      final resp = await _apiClient.getAiStatus();
      if (resp.success && resp.data != null) {
        final configured = resp.data!['configured'] as bool? ?? false;
        final model = resp.data!['model'] as String? ?? 'meta-llama/llama-3.3-70b-instruct:free';
        setState(() {
          _isConfigured = configured;
          _aiModel = model;
          _aiStatus = configured ? 'OpenRouter configuré' : 'OpenRouter non configuré';
        });
      } else {
        setState(() {
          _isConfigured = false;
          _aiStatus = 'Erreur de connexion';
        });
      }
    } on SocketException {
      setState(() {
        _isConfigured = false;
        _aiStatus = 'Hors ligne';
      });
    } catch (_) {
      setState(() {
        _isConfigured = false;
        _aiStatus = 'Non disponible';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Paramètres',
        showBackButton: !widget.isEmbedded,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        children: [
          // Intelligence Artificielle Section
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intelligence Artificielle',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: _isLoadingStatus ? null : _fetchAiStatus,
                      tooltip: 'Rafraîchir le statut',
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.auto_awesome_rounded, color: AppColors.aiViolet),
                  title: const Text('Fournisseur IA'),
                  subtitle: const Text('OpenRouter (Orchestré côté serveur Go)'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.memory_rounded, color: AppColors.primary),
                  title: const Text('Modèle configuré'),
                  subtitle: Text(_aiModel),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _isConfigured ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: _isConfigured ? AppColors.successGreen : AppColors.warningOrange,
                  ),
                  title: const Text('Statut de la connexion'),
                  subtitle: Text(_aiStatus),
                  trailing: _isLoadingStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),

          // About Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'À propos de l\'application',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
