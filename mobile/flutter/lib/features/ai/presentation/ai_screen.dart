import 'dart:io';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../data/remote_ai_provider.dart';
import '../domain/ai_service.dart';
import 'ai_result_screen.dart';

enum AiScreenState { idle, loading, success, error, offline, notConfigured }

class AiScreen extends StatefulWidget {
  final bool isEmbedded;
  final AiService? aiService;

  const AiScreen({
    super.key,
    this.isEmbedded = false,
    this.aiService,
  });

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  late final AiService _aiService;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();

  AiScreenState _state = AiScreenState.idle;
  String _statusMessage = '';
  String _resultText = '';

  @override
  void initState() {
    super.initState();
    _aiService = widget.aiService ?? AiService(RemoteAiProvider(apiClient: ApiClient()));
  }

  @override
  void dispose() {
    _textController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  void _handleError(dynamic e) {
    if (e is SocketException || e.toString().contains('SocketException') || e.toString().contains('NETWORK_ERROR')) {
      setState(() {
        _state = AiScreenState.offline;
        _statusMessage = 'Connexion Internet requise pour l\'IA.';
      });
    } else if (e.toString().contains('AI_NOT_CONFIGURED')) {
      setState(() {
        _state = AiScreenState.notConfigured;
        _statusMessage = 'Le fournisseur IA (OpenRouter) n\'est pas encore configuré côté serveur.';
      });
    } else {
      setState(() {
        _state = AiScreenState.error;
        _statusMessage = e.toString().replaceAll('ApiException', '').trim();
      });
    }
  }

  Future<void> _executeAction(String actionName, Future<void> Function() action) async {
    setState(() {
      _state = AiScreenState.loading;
      _statusMessage = '$actionName en cours...';
    });

    try {
      await action();
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _analyzeDocument() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir ou importer le texte du document')),
      );
      setState(() => _state = AiScreenState.idle);
      return;
    }

    await _executeAction('Analyse du document', () async {
      final res = await _aiService.analyzeStructured(text);
      if (mounted) {
        setState(() => _state = AiScreenState.idle);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AiResultScreen(result: res),
          ),
        );
      }
    });
  }

  Future<void> _correctText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    await _executeAction('Correction du texte', () async {
      final corrected = await _aiService.correct(text);
      setState(() {
        _state = AiScreenState.success;
        _resultText = corrected;
      });
    });
  }

  Future<void> _summarize() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    await _executeAction('Résumé du document', () async {
      final summary = await _aiService.summarize(text);
      setState(() {
        _state = AiScreenState.success;
        _resultText = summary;
      });
    });
  }

  Future<void> _extract() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    await _executeAction('Extraction structurée', () async {
      final extracted = await _aiService.extractStructuredData(text);
      setState(() {
        _state = AiScreenState.success;
        _resultText = extracted;
      });
    });
  }

  Future<void> _translate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    await _executeAction('Traduction', () async {
      final translated = await _aiService.translate(text, targetLanguage: 'anglais');
      setState(() {
        _state = AiScreenState.success;
        _resultText = translated;
      });
    });
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    final text = _textController.text.trim();
    if (question.isEmpty) return;

    await _executeAction('Consultation IA', () async {
      final response = await _aiService.chat(
        text.isNotEmpty
            ? 'Basé sur ce document : "$text"\n\nQuestion : $question'
            : question,
      );
      setState(() {
        _state = AiScreenState.success;
        _resultText = response;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(
        title: 'Assistant IA PDF',
        showBackButton: !widget.isEmbedded,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.space16),
          children: [
            // Top information banner
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: AppColors.aiViolet.withAlpha(20),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.aiViolet.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.aiViolet, size: 20),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      'Modèle OpenRouter orchestré côté serveur. Vos secrets sont protégés.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.aiVioletDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Document text input
            AppTextField(
              label: 'Contenu du document à traiter',
              hint: 'Collez le texte du document ou utilisez le résultat OCR...',
              controller: _textController,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: AppDimensions.space16),

            // Action grid
            Text(
              'Actions Intelligentes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.space8),
            Wrap(
              spacing: AppDimensions.space8,
              runSpacing: AppDimensions.space8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Analyser le document'),
                  onPressed: _analyzeDocument,
                ),
                ActionChip(
                  avatar: const Icon(Icons.spellcheck_rounded, size: 18),
                  label: const Text('Corriger le texte'),
                  onPressed: _correctText,
                ),
                ActionChip(
                  avatar: const Icon(Icons.summarize_outlined, size: 18),
                  label: const Text('Résumer'),
                  onPressed: _summarize,
                ),
                ActionChip(
                  avatar: const Icon(Icons.data_object_rounded, size: 18),
                  label: const Text('Extraire les informations'),
                  onPressed: _extract,
                ),
                ActionChip(
                  avatar: const Icon(Icons.translate_rounded, size: 18),
                  label: const Text('Traduire'),
                  onPressed: _translate,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),

            // Question input
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Poser une question au document',
                    hint: 'Posez n\'importe quelle question...',
                    controller: _questionController,
                  ),
                ),
                const SizedBox(width: AppDimensions.space8),
                Padding(
                  padding: const EdgeInsets.only(top: 26.0),
                  child: AppButton(
                    label: 'Demander',
                    icon: Icons.send_rounded,
                    onPressed: _askQuestion,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),

            // Feedback and state presentation
            _buildStateWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildStateWidget() {
    switch (_state) {
      case AiScreenState.loading:
        return LoadingState(message: _statusMessage);
      case AiScreenState.offline:
        return AppCard(
          color: AppColors.warningOrange.withAlpha(20),
          child: Column(
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.warningOrange, size: 36),
              const SizedBox(height: AppDimensions.space8),
              const Text(
                'Connexion Internet requise pour l\'IA.',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.space4),
              const Text(
                'Les autres fonctionnalités (PDF, visualisation, OCR local) restent opérationnelles hors ligne.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      case AiScreenState.notConfigured:
        return AppCard(
          color: AppColors.warningOrange.withAlpha(20),
          child: Column(
            children: [
              const Icon(Icons.settings_suggest_outlined, color: AppColors.warningOrange, size: 36),
              const SizedBox(height: AppDimensions.space8),
              Text(
                _statusMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      case AiScreenState.error:
        return ErrorState(
          message: _statusMessage,
          onRetry: () => setState(() => _state = AiScreenState.idle),
        );
      case AiScreenState.success:
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 20),
                  const SizedBox(width: AppDimensions.space8),
                  Text(
                    'Résultat IA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),
              SelectableText(
                _resultText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        );
      case AiScreenState.idle:
        return const SizedBox.shrink();
    }
  }
}
