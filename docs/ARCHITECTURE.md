# Architecture MorphPDF

## 1. Vue d'Ensemble

MorphPDF est une application Android moderne et performante dédiée au traitement intelligent de documents PDF, à la reconnaissance optique de caractères (OCR) et à l'assistance documentaire basée sur des modèles de langage (LLM).

Elle repose sur un paradigme **Local-First**, privilégiant l'exécution sur l'appareil (on-device) pour garantir la rapidité, la gratuité et la stricte confidentialité des données personnelles.

```
                    ┌────────────────────────┐
                    │    Système Android     │
                    └───────────┬────────────┘
                                │
                                ▼
                    ┌────────────────────────┐
                    │     Flutter / Dart     │
                    │   (Interface & UX)     │
                    └───────────┬────────────┘
                                │ HTTP + JSON
                                ▼
                    ┌────────────────────────┐
                    │     Go Backend API     │
                    │  (Sécurité & Moteurs)  │
                    └───────────┬────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│  PDF Engine   │       │  OCR Engine   │       │   AI Engine   │
│  Inspection,  │       │  ML Kit /     │       │  OpenRouter   │
│  manipulation │       │  PaddleOCR    │       │  (Abstrait)   │
└───────┬───────┘       └───────┬───────┘       └───────┬───────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                ▼
                    ┌────────────────────────┐
                    │     Document Model     │
                    │ (Blocs, Pages, Coords) │
                    └───────────┬────────────┘
                                ▼
                    ┌────────────────────────┐
                    │     Export Engine      │
                    │   (PDF, DOCX, TXT)     │
                    └────────────────────────┘
```

---

## 2. Principes Fondamentaux

### A. Local-First
- Les opérations de lecture, visualisation, division, fusion, compression et conversion locale s'effectuent sans connexion Internet.
- L'OCR est délégué prioritairement aux moteurs locaux de l'appareil (Google ML Kit pour l'anglais/français/latin, PaddleOCR pour l'arabe et le multilingue).

### B. Sécurité & Secrets
- Le client Flutter ne détient **jamais** de clé secrète (ex: `OPENROUTER_API_KEY`).
- Toutes les requêtes vers les LLM transitent par le backend Go qui filtre, sécurise et gère l'authentification.

### C. Architecture Applicative Flutter
- **Pattern** : Feature-First couplé à une séparation claire des responsabilités :
  ```
  UI (Widgets / Screens)
    ↓
  Notifier / Controller (Riverpod)
    ↓
  Repository (Abstraction données)
    ↓
  Service (Logique métier)
    ↓
  Local Engine ou ApiClient HTTP
  ```
- Les widgets sont purement déclaratifs et ne contiennent pas de logique métier lourde.

---

## 3. Modèle de Données Unifié

Le cœur de MorphPDF s'articule autour d'un modèle spatialisé permettant de situer précisément chaque élément au sein du document :
- `DocumentModel` : Métadonnées, statut, nombre de pages, empreinte mémoire.
- `PageModel` : Dimensions (largeur, hauteur), orientation et rotation.
- `TextBlock` : Coordonnées cartésiennes (x, y, w, h), texte brut, niveau de confiance, langue.
- `ImageBlock` : Détection des images bitmap/vectorielles extraites des pages.
- `TableBlock` : Reconnaissance des cellules, colonnes et lignes pour la reconstruction de tableaux.

---

## 4. Moteur PDF — Architecture Hybride Spécialisée (Phase 3.0 & 3.1)

MorphPDF retient une architecture hybride spécialisée documentée en détail dans [PDF_ENGINE_DECISION.md](PDF_ENGINE_DECISION.md) et [PDF_ENGINE_IMPLEMENTATION.md](PDF_ENGINE_IMPLEMENTATION.md) :
1. **Moteur Primaire (Couche Flutter / FFI)** : **Google PDFium** pour le rendu vectoriel haute performance, le zoom interactif, la navigation, l'extraction de texte avec coordonnées spatiales et l'alignement précis du repère OCR.
2. **Moteur Secondaire (Couche Go Backend)** : **pdfcpu** (100% Go pur, Apache 2.0) pour les manipulations structurelles lourdes (fusion, division, réorganisation, nettoyage, optimisation et compression sans perte).

---

## 5. Moteur OCR — Architecture et Implémentation (Phase 4.0, 4.0.1 & 4.1)

MorphPDF arrête son architecture OCR documentée en détail dans [OCR_ENGINE_DECISION.md](OCR_ENGINE_DECISION.md) et implémentée dans [OCR_RUNTIME.md](OCR_RUNTIME.md) :
1. **Moteur Primaire (Universel & Souverain)** : **PaddleOCR sous ONNX Runtime Mobile** (`PaddleOcrEngine` + pont natif Android Kotlin `PaddleOcrBridge`). Architecture modulaire découplée associant la détection DBNet++ (`ch_PP-OCRv4_det`), la classification d'orientation 0/180° (`ch_ppocr_mobile_v2.0_cls`), et des modèles de reconnaissance spécialisés par écriture (`arabic_PP-OCRv3_rec` pour l'arabe, les chiffres arabo-indiens et le bilingue ; `en_PP-OCRv4_rec` pour le latin). MorphPDF prend en charge le post-traitement de normalisation logique Unicode BiDi (`BidiNormalizer`) pour l'indexation et le rendu, avec projection cartésienne vers le repère PDF (`OcrCoordinateMapper` via `CoordinateConverter.pixelRectToPdfRect`). Exécution séquentielle stricte ($N=1$) et limite dimensionnelle de sécurité ($4096 \times 4096$ px). 100% hors-ligne et sans dépendance envers Google Play Services.
2. **Moteur Secondaire (Accélérateur Optionnel)** : **Google ML Kit Text Recognition V2** pour les scans exclusivement latins (français, anglais) lorsque Google Play Services est détecté sur le terminal (préservé via l'abstraction unifiée `OcrEngine` et `MlKitEngineMock`).

---

## 6. Moteur de Conversion PDF vers Word (.docx) — Architecture Arrêtée (Phase 5.0)

MorphPDF retient l'architecture de conversion Word documentée en détail dans [WORD_CONVERSION_DECISION.md](WORD_CONVERSION_DECISION.md) :
1. **Moteur Primaire (Mobile / In-Process)** : **MorphPDF Sovereign OOXML Engine en Dart Pur** (`package:archive` + encodeur XML OpenXML conforme ISO/IEC 29500 / ECMA-376). Reconstitution sémantique et fluide de la mise en page à partir du `DocumentModel` spatialisé, prise en charge native du balisage arabe et BiDi (`<w:bidi/>`, `<w:rtl/>`), des tables en twips (`dxa`), des images DrawingML en EMU, avec une cible de fidélité de Niveau 3.5 - 4 (structure et éditabilité réelles, rejet du faux pixel-perfect en zones de texte figées). 100% hors-ligne, zéro surcoût IPC, zéro dépendance C/NDK additionnelle.
2. **Moteur Secondaire (Serveur / Batch)** : **Service Go OOXML Stream** (`backend/go/internal/conversion`) pour les traitements batch lourds, desktop et déploiements d'infrastructure future.



