# Feuille de Route Technique (Roadmap) — MorphPDF

## Phase 0 — Initialisation & Audit de l'Environnement (Terminée)
- [x] Audit complet du runtime hôte (Ubuntu 26.04 ARM64, PRoot).
- [x] Vérification Flutter 3.47.5, Dart 3.13.4, Java 17, Git.
- [x] Identification des dépendances manquantes (Go).

## Phase 1 — Architecture Fondamentale Flutter + Go (En cours de finalisation)
- [x] Création du repository `MorphPDF` avec l'identité d'application `com.ghdinteractivestudio.morphpdf`.
- [x] Installation et validation du compilateur Go 1.26.0 ARM64.
- [x] Implémentation du backend Go (Serveur HTTP, config, middleware, santé, réponses standardisées, tests 100%).
- [x] Application Flutter Android (Design System Material 3, Riverpod, navigation, routes, composants réutilisables).
- [x] Abstractions des moteurs clés : `PdfEngine`, `OcrEngine`, `AiProvider`, `PdfToWordConverter`, `StorageService`.
- [x] Validation intégrale par tests unitaires (`flutter test`, `go test`, `flutter analyze`).

## Phase 2 — Moteur PDF Local & Visualisation
- [ ] Intégration du moteur PDF local haute performance.
- [ ] Rendu interactif des pages, zoom et navigation fluide.
- [ ] Extraction de texte et calcul des boîtes englobantes.

## Phase 3 — Moteur OCR Local (ML Kit & PaddleOCR)
- [ ] Intégration Google ML Kit Text Recognition pour l'anglais/français/latin.
- [ ] Intégration PaddleOCR optimisé ARM64 pour le multilingue et l'arabe.
- [ ] Détection automatique de l'orientation et prétraitement d'image.

## Phase 4 — Intégration IA via OpenRouter & Backend Go
- [ ] Communication sécurisée Flutter → Go → OpenRouter.
- [ ] Pipelines de résumé, correction grammaticale et extraction d'entités.
- [ ] Gestion du cache de réponses et limitation de débit.

## Phase 5 — Outils PDF Avancés & Conversion DOCX
- [ ] Algorithmes de fusion et division locales de PDF.
- [ ] Nettoyage de métadonnées et compression de flux.
- [ ] Pipeline de conversion robuste PDF → Word (.docx).

## Phase 6 — Finitions UX, Tests End-to-End & Packaging
- [ ] Polissage des animations et thèmes Material 3.
- [ ] Génération de l'APK Release signé pour `com.ghdinteractivestudio.morphpdf`.
- [ ] Documentation utilisateur et guide de déploiement.
