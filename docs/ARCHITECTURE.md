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

## 4. Moteur PDF — Architecture Hybride Spécialisée (Phase 3.0)

MorphPDF retient une architecture hybride spécialisée documentée en détail dans [PDF_ENGINE_DECISION.md](PDF_ENGINE_DECISION.md) :
1. **Moteur Primaire (Couche Flutter / FFI)** : **Google PDFium** pour le rendu vectoriel haute performance, le zoom interactif, la navigation, l'extraction de texte avec coordonnées spatiales et l'alignement précis du repère OCR.
2. **Moteur Secondaire (Couche Go Backend)** : **pdfcpu** (100% Go pur, Apache 2.0) pour les manipulations structurelles lourdes (fusion, division, réorganisation, nettoyage, optimisation et compression sans perte).

