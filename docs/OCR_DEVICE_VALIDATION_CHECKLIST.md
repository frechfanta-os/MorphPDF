# MorphPDF — Protocole de Validation Matérielle OCR sur Terminal Physique ARM64
## Phase 4.1.1 — Checklist & Fiche d'Exécution Matérielle Future

Ce document définit les étapes rigoureuses et non négociables à exécuter dès qu'un terminal Android physique 64 bits (ARM64-v8a) est raccordé au banc de test.

---

## 1. Fiche Signalétique du Terminal de Test (À Remplir)

| Paramètre | Valeur Relevée / Spécification |
| :--- | :--- |
| **Modèle du terminal** | `[Ex: Google Pixel 7 / Samsung Galaxy S23]` |
| **Fabricant** | `[Ex: Google / Samsung / Xiaomi]` |
| **Version Android / API Level** | `[Ex: Android 14 / API 34]` |
| **Architecture processeur (ABI)** | `[Doit être arm64-v8a obligatoire]` |
| **Mémoire RAM totale disponible** | `[Ex: 8 Go LPDDR5]` |
| **Densité d'affichage (DPI)** | `[Ex: 420 dpi / xxhdpi]` |
| **Numéro de build / Patch de sécurité** | `[Ex: UP1A.231005.007]` |
| **Date d'exécution du test** | `[AAAA-MM-JJ HH:MM]` |
| **Opérateur / Ingénieur de validation** | `[Nom & Organisation]` |

---

## 2. Checklist d'Exécution Séquentielle (18 Jalons Obligatoires)

| Étape | Description & Commande | Critère d'Acceptation Strict | Résultat (PASS/FAIL) | Temps / Mesure |
| :---: | :--- | :--- | :---: | :---: |
| **1** | **Détection ADB**<br>`adb devices -l` | Terminal détecté en mode `device` sans état `unauthorized`. | `[ ]` | N/A |
| **2** | **Vérification ABI ARM64**<br>`adb shell getprop ro.product.cpu.abi` | Sortie exacte : `arm64-v8a`. (Rejeter armeabi-v7a ou x86_64). | `[ ]` | N/A |
| **3** | **Installation du package APK**<br>`adb install -r -d app-release.apk` | Sortie `Success`. Aucune erreur d'incompatibilité native. | `[ ]` | ... s |
| **4** | **Lancement de MorphPDF**<br>`adb shell am start -n com.ghdinteractivestudio.morphpdf/.MainActivity` | Démarrage propre du splash officiel GHD, sans ANR ni crash. | `[ ]` | ... ms |
| **5** | **Chargement de la bibliothèque ONNX** | Chargement réussi de `libonnxruntime.so` sans `UnsatisfiedLinkError`. | `[ ]` | ... ms |
| **6** | **Initialisation des sessions modèles** | `ch_PP-OCRv4_det` et `arabic_PP-OCRv3_rec` alloués en mémoire sans OOM. | `[ ]` | ... ms |
| **7** | **Inférence OCR Français (Latin)** | Détection et transcription exacte des caractères accentués (é, è, à, ç). | `[ ]` | ... ms |
| **8** | **Inférence OCR Anglais (Latin)** | Transcription exacte de documents alphanumériques et ponctuation. | `[ ]` | ... ms |
| **9** | **Inférence OCR Arabe pur** | Transcription exacte de l'écriture naskhi / standard avec `arabic_dict.txt`. | `[ ]` | ... ms |
| **10** | **Inférence Arabe + Latin bilingue** | Reconnaissance sans confusion ni superposition des segments mixtes. | `[ ]` | ... ms |
| **11** | **Normalisation logique BiDi** | Ordre logique des caractères préservé sans altération des boîtes englobantes. | `[ ]` | ... ms |
| **12** | **Projection spatiale des coordonnées** | Bounding boxes alignées avec précision sub-millimétrique sur le calque PDF. | `[ ]` | < 1 pt delta |
| **13** | **Gestion des rotations (90°, 180°, 270°)** | Orientation détectée et repère cartésien PDF inversé conformément. | `[ ]` | ... ms |
| **14** | **Traitement séquentiel multi-pages ($N=1$)** | Traitement page après page. Concurrence ONNX strictement égale à 1. | `[ ]` | ... s/page |
| **15** | **Annulation interactive (`cancel`)** | Arrêt immédiat sous 200 ms à la demande de l'utilisateur, mémoire libérée. | `[ ]` | < 200 ms |
| **16** | **Empreinte mémoire RAM & fuites**<br>`adb shell dumpsys meminfo com.ghdinteractivestudio.morphpdf` | Consommation stable, absence de fuite après 10 pages consécutives. | `[ ]` | ... Mo PSS |
| **17** | **Garantie 100% Hors-ligne (Avion)** | Mode avion activé. 0 appel réseau émis. Zéro paquet sortant. | `[ ]` | 0 requêtes |
| **18** | **Validation Build Release & R8** | Exécution stable sous APK minifié/obfusqué (règles keep vérifiées). | `[ ]` | Stable |

---

## 3. Matrice de Mesure et Résultats d'Inférence

| Métrique de Performance | Valeur Cible | Valeur Réelle Mesurée sur Terminal |
| :--- | :--- | :--- |
| **Temps d'inférence détection (`det`) / page** | $\le 600$ ms | `... ms` |
| **Temps d'inférence reconnaissance (`rec`) / ligne** | $\le 80$ ms | `... ms` |
| **Temps total page standard A4 (150 DPI)** | $\le 2500$ ms | `... ms` |
| **Pic de mémoire vive allouée (PSS)** | $\le 350$ Mo | `... Mo` |
| **Taux de précision textuelle Arabe (CER/WER)** | $\ge 95\%$ | `... %` |
| **Taux de précision textuelle Français (CER/WER)** | $\ge 97\%$ | `... %` |

---

## 4. Règle de Clôture

Le statut `PASS — RUNTIME VERIFIED` ne pourra être accordé que si l'intégralité des 18 jalons ci-dessus est cochée `PASS` avec les mesures correspondantes dûment consignées.
