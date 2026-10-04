# MorphPDF

Application Android professionnelle de traitement intelligent et local de documents PDF, avec OCR multilingue et assistance IA via OpenRouter.

- **Nom Commercial** : MorphPDF
- **Organisation** : `com.ghdinteractivestudio`
- **Package Android** : `com.ghdinteractivestudio.morphpdf`
- **Dépôt GitHub** : [https://github.com/frechfanta-os/MorphPDF.git](https://github.com/frechfanta-os/MorphPDF.git)

---

## 1. Description du Produit

MorphPDF est conçu pour les professionnels et particuliers ayant besoin d'une solution complète sur Android pour :
- Importer, lire et afficher des documents PDF volumineux avec fluidité.
- Scanner des documents physiques avec la caméra et redresser l'image.
- Extraire le texte par **OCR local** (Google ML Kit pour les langues latines, PaddleOCR pour l'arabe et le multilingue).
- Analyser, résumer, corriger et traduire le contenu grâce à des modèles de pointe via **OpenRouter**.
- Réaliser des opérations courantes en local : fusion, division, optimisation, nettoyage de métadonnées.
- Convertir des PDF vers Word (.docx) avec préservation de la structure documentaire.

---

## 2. Architecture Globale

```
                    ANDROID
                       │
                       ▼
                 FLUTTER / DART
                       │
                  HTTP + JSON
                       │
                       ▼
                    GO API
                       │
       ┌───────────────┼────────────────┐
       │               │                │
       ▼               ▼                ▼
   PDF ENGINE       OCR ENGINE       AI ENGINE
       │               │                │
       │               │          OpenRouter
       │               │
       └───────────────┼────────────────┘
                       │
                       ▼
                 DOCUMENT MODEL
                       │
                       ▼
                  EXPORT ENGINE
                       │
                ┌──────┴──────┐
                ▼             ▼
               PDF           DOCX
```

### Principes Clés
1. **Local-First** : Priorité absolue aux traitements sur l'appareil (on-device) pour garantir rapidité, gratuité et confidentialité.
2. **Sécurité Forte** : Les clés API (OpenRouter) ne sont **jamais** intégrées dans le code Flutter ; elles sont gérées par la couche Go.
3. **Architecture Modulaire** : Toutes les composantes lourdes (PDF, OCR, IA, Conversion) sont isolées derrière des abstractions strictes (`PdfEngine`, `OcrEngine`, `AiProvider`, `PdfToWordConverter`).

---

## 3. Structure du Projet

```
MorphPDF/
├── mobile/
│   └── flutter/        # Application mobile Android (Flutter 3.47 / Dart 3.13)
│       ├── lib/
│       │   ├── app/    # Thème Material 3, Router, Config
│       │   ├── core/   # Réseau, Stockage local, Widgets réutilisables
│       │   ├── features/ # Écrans et modules fonctionnels
│       │   └── shared/ # Modèles de documents, Enums, Constantes
│       └── test/       # Tests unitaires et d'intégration Flutter
│
├── backend/
│   └── go/             # Serveur HTTP et moteur Go (Go 1.26 ARM64)
│       ├── cmd/server/ # Point d'entrée main.go
│       ├── internal/   # Configuration, handlers, services, moteurs
│       ├── pkg/        # Enveloppe de réponse standardisée
│       └── README.md
│
├── docs/               # Spécifications et études d'ingénierie
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── ROADMAP.md
│   ├── OCR_EVALUATION.md
│   ├── PDF_ENGINE_EVALUATION.md
│   └── WORD_CONVERSION_EVALUATION.md
│
├── scripts/            # Scripts d'automatisation et de validation
├── .gitignore
├── README.md
└── LICENSE
```

---

## 4. Prérequis & Installation

### Environnement Recommandé
- **Système** : Linux ARM64 (ou x86_64), Android PRoot / Termux ou machine de build standard.
- **Flutter** : `>= 3.47.0`
- **Dart** : `>= 3.13.0`
- **Go** : `>= 1.22.0` (installé : `1.26.0`)
- **JDK** : OpenJDK 17

### Installation des dépendances

```bash
# Frontend Flutter
cd mobile/flutter
flutter pub get

# Backend Go
cd ../../backend/go
go mod download
```

---

## 5. Lancement des Services

### Lancement du Backend Go
```bash
cd backend/go
cp .env.example .env
go run cmd/server/main.go
```
Le serveur écoute par défaut sur `http://0.0.0.0:8080`.

### Lancement de l'Application Flutter
```bash
cd mobile/flutter
flutter run
```

---

## 6. Tests & Qualité de Code

```bash
# Tests & Analyse Flutter
cd mobile/flutter
flutter analyze
flutter test

# Tests & Analyse Go
cd ../../backend/go
go vet ./...
go test -v ./...
```
