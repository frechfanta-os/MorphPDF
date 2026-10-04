# Évaluation des Moteurs OCR — MorphPDF

L'objectif de MorphPDF est d'offrir une reconnaissance optique de caractères (OCR) **locale, gratuite et respectueuse de la vie privée**, avec une prise en charge bilingue/multilingue d'excellence (écritures latines + arabe).

---

## 1. Moteurs Évalués

| Moteur | Licence | Architecture & Plateforme | Support Latin | Support Arabe | Empreinte / Poids | Dépendance Réseau |
|---|---|---|---|---|---|---|
| **Google ML Kit (Android)** | Propriétaire gratuite (Google Play Services / Standalone) | Android ARM64, x86_64 | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐ Limité (Pack spécifique) | Faible (< 5 Mo si dynamique) | ❌ Non (100% On-Device) |
| **PaddleOCR (PP-OCRv4 / ONNX / NCNN)** | Apache 2.0 (Open Source) | ARM64 (Linux & Android), C++ / Go / Flutter FFI | ⭐⭐⭐⭐ Très bon | ⭐⭐⭐⭐⭐ Excellent (Modèles spécialisés) | Modéré (~15-25 Mo quantifié int8) | ❌ Non (100% On-Device) |
| **Tesseract OCR (v5)** | Apache 2.0 | C++ / CLI / Wrapper | ⭐⭐⭐ Bon | ⭐⭐⭐ Moyen (Lent sur mobile) | Élevé (~40-60 Mo tessdata) | ❌ Non |

---

## 2. Analyse Détaillée

### A. Google ML Kit (Text Recognition v2)
- **Avantages** : Intégration transparente dans l'écosystème Android natif. Extrêmement rapide et optimisé pour le GPU/NPU des smartphones récents. Détection de texte latin en temps réel avec calcul très précis des boîtes englobantes (`BoundingBox`).
- **Limites** : Moins performant sur les écritures cursives complexes comme l'arabe sans modèles linguistiques complémentaires.

### B. PaddleOCR (PP-OCRv4)
- **Avantages** : L'état de l'art mondial en matière de reconnaissance de texte multilingue et d'écritures connectées/cursives (notamment l'arabe, le chinois, le japonais). Très compact lorsqu'il est exécuté via le runtime ONNX Runtime Mobile ou NCNN optimisé pour ARM Neon (ARM64).
- **Limites** : Nécessite un packaging des modèles ONNX ou un binding C++/FFI dans l'application ou le binaire Go.

---

## 3. Stratégie d'Architecture Retenue pour MorphPDF

MorphPDF adopte une approche **hybride et abstraite** :
1. **Abstraction `OcrEngine`** : Ni Flutter ni Go ne sont couplés directement à une bibliothèque tierce.
2. **Dispatch Intelligent** :
   - Pour les documents en français, anglais, espagnol, allemand : utilisation prioritaire de **Google ML Kit** pour une latence minimale et une faible consommation de batterie.
   - Pour les documents en langue arabe ou multilingues complexes : activation du moteur **PaddleOCR** embarqué.
