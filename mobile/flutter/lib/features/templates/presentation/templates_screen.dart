import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_dimensions.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_top_bar.dart';

class TemplateItem {
  final String title;
  final String category;
  final String description;
  final IconData icon;
  final String contentTemplate;

  const TemplateItem({
    required this.title,
    required this.category,
    required this.description,
    required this.icon,
    required this.contentTemplate,
  });
}

class TemplatesScreen extends StatefulWidget {
  final StorageService? storageService;

  const TemplatesScreen({super.key, this.storageService});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  late final StorageService _storageService;

  final List<TemplateItem> _templates = const [
    TemplateItem(
      title: 'Facture Professionnelle',
      category: 'Comptabilité',
      description: 'En-tête émetteur/client, tableau des prestations HT/TVA/TTC et mentions légales obligatoires.',
      icon: Icons.receipt_long_rounded,
      contentTemplate: 'FACTURE N° FAC-2026-001\n\nÉmetteur : [Société]\nClient : [Destinataire]\nDate : 11/10/2026\n\nDésignation | Qté | Prix Unitaire HT | Total HT\n1. Prestation de conseil | 1 | 1000.00 € | 1000.00 €\n\nTotal HT : 1000.00 €\nTVA (20%) : 200.00 €\nTotal TTC : 1200.00 €\n\nPaiement sous 30 jours par virement bancaire.',
    ),
    TemplateItem(
      title: 'Devis Commercial',
      category: 'Vente',
      description: 'Offre détaillée avec conditions de validité, acompte et signature.',
      icon: Icons.request_quote_rounded,
      contentTemplate: 'DEVIS N° DEV-2026-042\n\nValidité de l\'offre : 30 jours\nClient : [Nom du Client]\n\nPrestation : Développement applicatif sur mesure\nMontant estimé HT : 3500.00 €\nAcompte à la commande : 30%\n\nBon pour accord le : _____________\nSignature :',
    ),
    TemplateItem(
      title: 'Attestation sur l\'Honneur',
      category: 'Administratif',
      description: 'Document standard pour démarches administratives et justificatifs officiels.',
      icon: Icons.verified_user_rounded,
      contentTemplate: 'ATTESTATION SUR L\'HONNEUR\n\nJe soussigné(e), [Prénom Nom],\ndemeurant au [Adresse complète],\n\nAtteste sur l\'honneur que :\n[Déclaration sur l\'honneur]\n\nFait pour servir et valoir ce que de droit.\n\nFait à [Ville], le 11/10/2026\nSignature :',
    ),
    TemplateItem(
      title: 'Contrat de Prestation',
      category: 'Juridique',
      description: 'Clauses d\'engagement, périmètre, livrables et confidentialité.',
      icon: Icons.gavel_rounded,
      contentTemplate: 'CONTRAT DE PRESTATION DE SERVICES\n\nEntre les soussignés :\n1. Le Prestataire : [Nom Prestataire]\n2. Le Client : [Nom Client]\n\nArticle 1 - Objet du contrat\nLe présent contrat a pour objet la réalisation de...\n\nArticle 2 - Durée et résiliation\n...\n\nArticle 3 - Confidentialité\n...',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? LocalStorageService();
  }

  Future<void> _exportTemplate(TemplateItem template) async {
    try {
      final fileName = '${template.title.toLowerCase().replaceAll(' ', '_')}.txt';
      final file = await _storageService.saveExport(
        fileName,
        utf8.encode(template.contentTemplate),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modèle sauvegardé dans les exports (${file.path})'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _previewTemplate(TemplateItem template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLarge)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(AppDimensions.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(template.icon, color: AppColors.primary),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Text(
                          template.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  Text(
                    template.description,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(50),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(color: Colors.grey.withAlpha(50)),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: SelectableText(
                          template.contentTemplate,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Enregistrer le modèle',
                          icon: Icons.download_rounded,
                          onPressed: () {
                            Navigator.pop(context);
                            _exportTemplate(template);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Modèles de documents'),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(AppDimensions.space16),
          itemCount: _templates.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppDimensions.space12),
          itemBuilder: (context, index) {
            final t = _templates[index];
            return AppCard(
              onTap: () => _previewTemplate(t),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.space12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Icon(t.icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              t.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                            Chip(
                              label: Text(t.category, style: const TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.description,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    tooltip: 'Aperçu',
                    onPressed: () => _previewTemplate(t),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
