# RAPPORT TECHNIQUE DE PRODUCTION — PHASE 5.6
## Implémentation OCR Réelle avec PaddleOCR et ONNX Runtime Android

**Date** : 9 Octobre 2026  
**Projet** : MorphPDF (Application mobile Android locale-first de traitement et conversion PDF)  
**Package Android** : `com.ghdinteractivestudio.morphpdf`  
**Dépôt GitHub** : `https://github.com/frechfanta-os/MorphPDF.git`  
**Branche** : `main`  
**Commit de référence de départ** : `981663735148f51b7d60868267ccd091e1312d8e`  
**Statut de la phase** : **RÉALISÉE AVEC SUCCÈS**

---

## 1. Classification & Vérité Technique Obligatoire

Conformément à la déontologie et aux directives d'intégrité technique du projet MorphPDF :

| Domaine | Statut Exact | Commentaire & Justification |
| :--- | :--- | :--- |
| **Modèles ONNX & Dictionnaires** | **PACKAGING & HASH VERIFIED** | Les modèles officiels PP-OCRv4 (détection, reconnaissance latine) et PP-OCRv3 (reconnaissance arabe) ainsi que les dictionnaires complets sont intégrés dans les assets avec empreintes SHA-256 validées. |
| **Pont Kotlin Android** | **BUILD & ARCHITECTURE VERIFIED** | Remplacement intégral du mock par un moteur ONNX Runtime complet : sessions ORT, DBNet post-traitement, normalisation d'images, inférence multilingue, et décodage CTC glouton. |
| **Pipeline PDFium & OCR Dart** | **INTEGRATED & VERIFIED** | Intégration dans `OcrService` et `SovereignPdfToWordConverter` : détection du texte natif en amont via PDFium, bascule automatique vers le rendu d'image et l'OCR en cas de page scannée. |
| **Tests Automatisés & Analyse** | **153/153 PASS (100%)** | 153 tests Flutter réussis (+10 nouveaux tests de pipeline ONNX/OCR), `flutter analyze` : 0 issue, Go tests & vet : PASS. |
| **Validation Matérielle ARM64** | **RUNTIME PENDING PHYSICAL ARM64** | Aucun appareil physique Android ARM64 n'étant connecté dans l'environnement de build, aucune assertion trompeuse d'exécution physique sur silicium n'est émise. L'environnement est prêt pour la vérification sur appareil. |

Le statut du composant OCR passe ainsi de **BLOCKED / MOCK** à **PACKAGING & ARCHITECTURE VERIFIED / READY FOR PHYSICAL VALIDATION**.

---

## 2. Inventaire et Provenance des Modèles ONNX & Dictionnaires

### 2.1. Spécifications et Tenseurs Vérifiés

Les modèles ONNX intégrés proviennent de la suite officielle **PaddleOCR** de Baidu, convertis au format standard ONNX (opsets 10 et 11) et validés par introspection de leurs tenseurs d'entrée et de sortie :

| Rôle | Modèle | Version / Opset | Tenseur Entrée | Tenseur Sortie | Taille | Empreinte SHA-256 |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **Détection** | `ch_PP-OCRv4_det_infer.onnx` | Opset 11 | `x` `[1, 3, H, W]` | `sigmoid_0.tmp_0` `[1, 1, H, W]` | 4,7 Mo | `30a86f5731181461d08021402766601e4302a9b9b9666be8aff402696339cdff` |
| **Reconnaissance Latine** | `en_PP-OCRv4_rec_infer.onnx` | Opset 10 | `x` `[1, 3, 48, W]` | `softmax_2.tmp_0` `[1, seq_len, 97]` | 7,6 Mo | `870d81b658bb0ba59ae4a2aecf21f879e4921002be29d208cdcdb977af6e0959` |
| **Reconnaissance Arabe** | `arabic_PP-OCRv3_rec_infer.onnx` | Opset 10 | `x` `[1, 3, 48, W]` | `softmax_2.tmp_0` `[1, seq_len, 163]` | 8,9 Mo | `1be9c242e6f4cb974ba19e75b55368eee776c8fe411a7150616f82a210b974c0` |

### 2.2. Dictionnaires de Caractères et Vocabulaires CTC

1. **Dictionnaire Latin (`en_dict.txt`)** :
   - Contient 95 caractères (lettres minuscules, majuscules, chiffres arabes standard, symboles de ponctuation, et caractère espace).
   - Vocabulaire du tenseur de sortie : 97 classes (Index 0 = CTC Blank, Indices 1 à 95 = caractères du dictionnaire, Index 96 = jeton de fin/espace de secours).
   - Empreinte SHA-256 : `5662df9d2d03f0e8ca0d3b0649d6acbab904b6a14b3d3521463c71c37c668ce3`

2. **Dictionnaire Arabe (`arabic_dict.txt`)** :
   - Contient 161 caractères couvrant l'alphabet arabe complet, les signes diacritiques, les chiffres orientaux (`١-٩`), les chiffres occidentaux (`0-9`), et l'alphabet latin (`A-Z`, `a-z`) pour la gestion unifiée des textes bilingues et numéros de référence.
   - Vocabulaire du tenseur de sortie : 163 classes (Index 0 = CTC Blank, Indices 1 à 161 = caractères du dictionnaire, Index 162 = caractère espace).
   - Empreinte SHA-256 : `637c27c88512c22089bef927b34ada08f748dc132ac70facd68d8202384c2726`

3. **Manifeste Officiel (`models_manifest.json`)** :
   - Fichier de configuration et de vérification d'intégrité à l'exécution, spécifiant chaque version de modèle, chemin relatif, dimensions et hachages SHA-256.

---

## 3. Architecture du Moteur Kotlin Réel (`PaddleOcrBridge.kt`)

Le stub précédent simulait les réponses OCR. Il a été intégralement remplacé par une implémentation robuste utilisant l'API officielle Java/Kotlin de Microsoft ONNX Runtime (`ai.onnxruntime:onnxruntime-android:1.17.0`).

### 3.1. Gestion du Cycle de Vie et Concurrence
- **Thread Pool Dédié** : Les inférences ONNX s'exécutent sur un `ExecutorService` asynchrone mono-thread d'arrière-plan pour ne jamais saturer l'UI thread ou le thread Dart.
- **Résolution Multi-Chemins des Assets** : Le chargeur d'assets résout dynamiquement les modèles quel que soit l'emballage APK (`flutter_assets/assets/models/ocr/...`, `assets/models/ocr/...`, `models/ocr/...`).
- **Support de l'Annulation** : L'état d'annulation est suivi via `AtomicBoolean isCancelled`. Si l'utilisateur ou le service Dart annule l'opération en cours d'inférence, le pipeline s'interrompt immédiatement sans gaspillage CPU.
- **Libération Propre des Ressources (RAII)** : Méthode `dispose` assurant la fermeture synchrone des sessions (`OrtSession.close()`), de l'environnement (`OrtEnvironment.close()`), et le recyclage des `Bitmap`.

### 3.2. Pipeline de Détection (DBNet)
1. **Prétraitement & Redimensionnement** :
   - Les dimensions de l'image sont adaptées pour être des multiples stricts de 32 (contrainte convolutionnelle DBNet), avec un plafond de 960 pixels pour préserver la mémoire vive sur mobile.
   - Les pixels de l'image Android sont convertis en tenseur `FloatBuffer` de forme `[1, 3, H, W]` normalisé selon les moyennes et écarts-types ImageNet standard :
     $$\text{norm}_c = \frac{\frac{\text{val}_c}{255.0} - \text{mean}_c}{\text{std}_c}$$
2. **Inférence & Binarisation Différentiable** :
   - Inférence sur `detSession` produisant la carte de probabilités (`sigmoid_0.tmp_0`).
   - Extraction des composantes connexes par algorithme BFS (Breadth-First Search) 8-connecté sur les pixels dépassant le seuil de probabilité ($p > 0.3$).
3. **Expansion et Filtrage Polygonal (Unclip)** :
   - Application d'un facteur d'expansion de boîte (unclip ratio de 1.5) basé sur le rapport périmètre/aire de Vatti.
   - Élimination des artefacts et bruits dont les dimensions ou la surface sont inférieures à 6 pixels.

### 3.3. Pipeline de Reconnaissance Multilingue & Décodage CTC
1. **Recadrage et Normalisation Géométrique** :
   - Chaque boîte de texte détectée est découpée dans l'image source avec marge de sécurité.
   - L'image de la ligne est redimensionnée à une hauteur fixe de 48 pixels (standard PP-OCRv4/v3) en conservant le ratio d'aspect.
   - Conversion en tenseur `[1, 3, 48, W]` avec normalisation symétrique $[-1.0, 1.0]$.
2. **Aiguillage de Modèle** :
   - Détection de la langue cible : si l'arabe est sélectionné, le modèle `recArabicSession` et `arabic_dict.txt` sont sollicités ; sinon, `recLatinSession` et `en_dict.txt` sont employés.
3. **Décodage CTC Glouton (Greedy CTC Decoding)** :
   - Parcours de la dimension temporelle (`seq_len`) de la sortie softmax.
   - Détection de la classe de probabilité maximale pour chaque pas temporel.
   - Élimination des répétitions consécutives et du jeton vide (CTC Blank = 0).
   - Conversion des indices en caractères Unicode et calcul de la confiance moyenne géométrique.
4. **Hiérarchisation Structurelle & Lecture** :
   - Structuration en mots (`OcrWordResult`), lignes (`OcrLineResult`), et blocs (`OcrBlockResult`).
   - Tri géométrique respectant l'ordre de lecture (haut-vers-bas, et droite-vers-gauche si arabe).

---

## 4. Intégration PDFium Natif & Moteur OOXML Word

### 4.1. Stratégie Hybride d'Extraction dans `OcrService`
Le nouveau mécanisme `extractTextFromPdfPage` implémente la chaîne de décision optimale :
```
Page PDF
  │
  ▼
Inspection & Extraction Native PDFium (FPDFText_GetText)
  │
  ├─► [Texte présent (> 10 caractères)] ──────────► Utilisation directe du texte natif
  │                                                  (Qualité 100%, 0 latence OCR)
  │
  └─► [Page scannée ou texte absent] ─────────────► Rendu image via PDFium (FPDF_RenderPageBitmap)
                                                     │
                                                     ▼
                                                    Inférence PaddleOCR ONNX Android
                                                     │
                                                     ▼
                                                    BidiNormalizer & OcrCoordinateMapper
                                                     │
                                                     ▼
                                                    Génération de blocs textuels positionnés
```

### 4.2. Intégration au Moteur Sovereign PDF → Word (`SovereignPdfToWordConverter`)
- Le paramètre `ocrScannedPages` a été introduit dans `ConversionOptions` (avec les modes `OcrMode.auto`, `OcrMode.force`, `OcrMode.disabled`).
- Lors de la conversion d'un document PDF vers DOCX :
  - Si une page ne contient aucun texte vectoriel natif, le convertisseur appelle automatiquement `ocrService.extractTextFromPdfPage`.
  - Les blocs de texte issus de l'OCR sont projetés de l'espace pixels à l'espace points PDF (72 DPI) via `OcrCoordinateMapper`.
  - Le `LayoutReconstructor` reconstruit la géométrie (colonnes, paragraphes, tableaux) et `OoxmlBuilder` produit le fichier `.docx` final éditable sans aucune dépendance vers un service cloud ou une IA externe.

### 4.3. Préservation BiDi et Ordre Logique Unicode
- Le composant `BidiNormalizer` garantit que le texte arabe issu de l'OCR conserve son ordre de frappe logique (Logical Order) lors de l'injection dans les balises Word (`w:r/w:t` avec propriété `w:rtl`).
- Aucun renversement destructif (Visual Order inversion) n'est appliqué, ce qui assure un affichage naturel et un curseur éditable fluide dans Microsoft Word et LibreOffice.

---

## 5. Renforcement de la CI/CD (`build_apk.yml`)

Le workflow GitHub Actions `.github/workflows/build_apk.yml` a été enrichi d'une étape de contrôle qualité automatisée après le build de l'APK Release :

```yaml
- name: Validate OCR Model & Dictionary Packaging in Release APK
  run: |
    APK_PATH="mobile/flutter/build/app/outputs/flutter-apk/app-release.apk"
    echo "Inspecting OCR assets in release APK..."

    DET_MODEL=$(unzip -l "$APK_PATH" | grep "ch_PP-OCRv4_det_infer.onnx" || true)
    # Vérification présence modèle de détection
    ...
    LATIN_MODEL=$(unzip -l "$APK_PATH" | grep "en_PP-OCRv4_rec_infer.onnx" || true)
    # Vérification présence modèle latin
    ...
    ARABIC_MODEL=$(unzip -l "$APK_PATH" | grep "arabic_PP-OCRv3_rec_infer.onnx" || true)
    # Vérification présence modèle arabe
    ...
    DICT_CHECK=$(unzip -l "$APK_PATH" | grep "arabic_dict.txt" || true)
    # Vérification présence dictionnaires
```

Cette étape empêche formellement la publication ou la génération d'un APK dont les modèles ou dictionnaires auraient été exclus accidentellement lors de la compilation des assets.

---

## 6. Résultats des Tests et Validation Automatisée

### 6.1. Nouvelle Suite de Tests (`real_ocr_onnx_pipeline_test.dart`)
10 nouveaux tests dédiés valident :
1. La présence et la validité du fichier `models_manifest.json`.
2. L'intégrité et la taille sur disque des 3 binaires ONNX (`ch_PP-OCRv4_det_infer.onnx`, `en_PP-OCRv4_rec_infer.onnx`, `arabic_PP-OCRv3_rec_infer.onnx`).
3. Le décompte exact des classes des dictionnaires latin (95 lignes) et arabe (161 lignes).
4. La préservation prioritaire du texte natif PDFium sans sollicitation inutile de l'OCR.
5. La bascule transparente vers l'OCR en cas de page blanche / image scannée.
6. Le respect des jetons d'annulation (`CancellationToken`).
7. La conformité de `BidiNormalizer` sur les textes mixtes arabes/français.
8. La précision de projection de `OcrCoordinateMapper` (pixel -> point PDF).
9. L'intégration sans régression du convertisseur Sovereign Word sur les documents natifs.
10. La conversion complète d'un document scanné vers un véritable package `.docx` ZIP/XML valide.

### 6.2. Bilan Global des Contrôles Qualité
- **Tests Flutter** : **153 / 153 tests réussis (100% PASS)**
- **Analyse Statique Flutter (`flutter analyze`)** : **0 issue (No issues found!)**
- **Tests Unitaires Go Backend (`go test ./...`)** : **100% PASS**
- **Analyse Statique Go (`go vet ./...`)** : **0 anomalie**
- **Vérification Globale (`./scripts/run_checks.sh`)** : **4/4 étapes validées avec succès**

---

## 7. Synthèse et Prochaines Étapes

Grâce à la Phase 5.6 :
- Le composant OCR de MorphPDF dispose désormais d'un moteur ONNX Runtime complet, robuste, multilingue et entièrement hors-ligne.
- Les modèles réels PaddleOCR (détection DBNet + reconnaissance bilingue latin/arabe) sont embarqués et vérifiés.
- Le convertisseur PDF vers Word dispose d'un fallback OCR automatique et unifié pour traiter les documents scannés.
- Toutes les étapes de validation statique, unitaire, et d'empaquetage CI sont au vert.

La prochaine étape consistera à effectuer les tests de validation physique sur appareil Android ARM64 réel selon la procédure documentée dans `docs/OCR_DEVICE_VALIDATION_CHECKLIST.md`.
