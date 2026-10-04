# Évaluation de la Conversion PDF vers Word (DOCX) — MorphPDF

La conversion d'un document PDF vers un format éditable Microsoft Word (.docx) est l'un des défis techniques les plus ardus en ingénierie logicielle, car le format PDF est conçu pour le rendu fixe d'instructions graphiques (coordonnées absolues x/y, glyphes isolés), tandis que le format DOCX repose sur un modèle de flux textuel sémantique dynamique (paragraphes, styles, marges relatives, flux tabulaires).

> [!IMPORTANT]
> MorphPDF adopte une démarche d'ingénierie honnête et réaliste : **nous ne promettons pas une conservation parfaite à 100% de la mise en page**, mais une reconstruction structurée et robuste du contenu textuel, des images et des tableaux.

---

## 1. Moteurs & Approches Évaluées

| Approche / Moteur | Licence | Fonctionnement Local | Compatibilité ARM64 | Conservation Texte | Reconnaissance Tableaux | Conservation Images |
|---|---|---|---|---|---|---|
| **Pipeline Hybride MorphPDF (Spatial Parser + `docx` Go/Dart)** | Open Source (Interne) | ⭐⭐⭐⭐⭐ 100% Local | ⭐⭐⭐⭐⭐ Parfaite | ⭐⭐⭐⭐⭐ Excellente | ⭐⭐⭐⭐ Très bonne (heuristique) | ⭐⭐⭐⭐ Extraction directe |
| **pdf2docx (Python / C++)** | GPLv3 (Contraintes fortes de distribution) | ⭐⭐⭐⭐ Local | ⭐⭐⭐ Complexe sous mobile | ⭐⭐⭐⭐ Bonne | ⭐⭐⭐⭐ Bonne | ⭐⭐⭐ Bonne |
| **Pandoc / Poppler pdftotext** | GPLv2 | ⭐⭐⭐⭐ Local | ⭐⭐⭐⭐ Binaire CLI | ⭐⭐⭐ Linéaire uniquement | ❌ Perte des tableaux | ❌ Perte des images |
| **LibreOffice headless / unoconv** | LGPL / GPL | ❌ Trop lourd pour Android (> 300 Mo) | ❌ Très complexe | ⭐⭐⭐⭐ Bonne | ⭐⭐⭐⭐ Bonne | ⭐⭐⭐ Bonne |

---

## 2. Pipeline Technique Hybride Retenu pour MorphPDF

Pour garantir un fonctionnement **100% local, léger et performant sur Android ARM64**, MorphPDF implémente un pipeline en 4 étapes :

```
[ PDF Source ]
      ↓
Étape 1 : Analyse Spatiale (Extraction des TextBlocks, ImageBlocks, TableBlocks)
      ↓
Étape 2 : Heuristique de Reconstitution (Regroupement en lignes, paragraphes et colonnes)
      ↓
Étape 3 : Traitement OCR Conditionnel (Si la page ne contient aucun texte vectoriel)
      ↓
Étape 4 : Synthèse OpenXML (.docx) (Écriture du document Word zippé conforme ISO/IEC 29500)
```

### Détail des Étapes :
1. **Extraction Géométrique** : Détection des blocs via le modèle unifié `TextBlock` (positions, dimensions, polices approchées).
2. **Détection des Tableaux** : Analyse des lignes horizontales et verticales pour identifier les grilles matricielles (`TableBlock`).
3. **Extraction des Images** : Décompression des flux XObject image sans ré-encodage destructif.
4. **Génération DOCX Native** : Génération directe de l'archive OpenXML (`word/document.xml`, `[Content_Types].xml`, `_rels`) côté Go ou Dart sans dépendance externe lourde.
