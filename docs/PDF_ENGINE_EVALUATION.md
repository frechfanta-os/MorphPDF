# Évaluation des Moteurs PDF — MorphPDF

Le traitement de fichiers PDF complexes impose de choisir des moteurs robustes, économes en mémoire RAM et nativement compatibles avec l'architecture **ARM64**.

---

## 1. Moteurs Évalués

| Solution | Langage / Écosystème | Licence | Compatibilité Android ARM64 | Rendu Graphique | Manipulation Structurelle | Empreinte Mémoire |
|---|---|---|---|---|---|---|
| **Google PDFium** (via `pdfrx` / FFI) | C++ / Dart FFI | Apache 2.0 / BSD 3-Clause | ⭐⭐⭐⭐⭐ Excellente (Inclus dans Chrome/Android) | ⭐⭐⭐⭐⭐ Rendu ultra-rapide | ⭐⭐⭐ Partielle (Rendu + texte) | Faible à Modérée |
| **pdfcpu** | Go pur | Apache 2.0 | ⭐⭐⭐⭐⭐ Excellente (Pas de cgo requis) | ❌ Pas de moteur de rastérisation | ⭐⭐⭐⭐⭐ Exceptionnelle (Merge, Split, Clean, Métadonnées) | Très faible |
| **MuPDF** | C / C++ | AGPLv3 (Contrainte forte) / Commercial | ⭐⭐⭐⭐ Bonne | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐⭐ Très complet | Modérée |
| **UniPDF** | Go | Commercial / AGPLv3 | ⭐⭐⭐ Bonne | ❌ Pas de rendu | ⭐⭐⭐⭐ Bon | Faible |
| **Android PdfRenderer Natif** | Java / C++ (Android SDK) | AOSP (Apache 2.0) | ⭐⭐⭐⭐⭐ Native Android | ⭐⭐⭐⭐ Bon pour l'affichage | ❌ Rendu uniquement | Nulle (Déjà présent dans l'OS) |

---

## 2. Analyse Technique

### A. Rendu Visuel et Affichage : Google PDFium (`pdfrx`)
- **Forces** : Moteur standard mondial maintenu par Google (utilisé dans Chrome et l'écosystème Android). Rendu extrêmement fluide des pages, support complet des polices intégrées, des dégradés, des formulaires et des annotations visuelles.
- **Faiblesses** : Moins orienté vers la manipulation de bas niveau des arbres d'objets PDF (réécriture, nettoyage complet des flux).

### B. Manipulation et Traitement Structurel : `pdfcpu` (Go)
- **Forces** : 100% Go pur sans dépendance C (aucun problème de compilation croisée ARM64 sous PRoot ou Android). Idéal pour :
  - La fusion rapide de plusieurs fichiers PDF (`merge`).
  - L'extraction et le découpage de plages de pages (`split`).
  - L'optimisation et la compression des flux d'objets (`clean` & `optimize`).
  - La suppression des métadonnées confidentielles.

---

## 3. Recommandation d'Architecture Retenue pour MorphPDF

MorphPDF sépare judicieusement les deux besoins :
1. **Couche UI / Affichage (Flutter)** : Utilisation de **PDFium** (via `pdfrx` ou le `PdfRenderer` Android) pour le visualiseur interactif, le défilement et le zoom tactile.
2. **Couche Métier / Manipulation Lourde (Go)** : Utilisation de **`pdfcpu`** dans la couche Go pour exécuter les opérations de fusion, division, optimisation et nettoyage sans aucune surcharge serveur externe.
