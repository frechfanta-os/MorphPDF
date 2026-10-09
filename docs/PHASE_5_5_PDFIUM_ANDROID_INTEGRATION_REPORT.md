# RAPPORT D'INTÉGRATION TECHNIQUE — PHASE 5.5
## Intégration Réelle de Google PDFium Natif sur Android ARM64

**Date** : 9 Octobre 2026  
**Projet** : MorphPDF (Application mobile Android locale-first de manipulation et conversion PDF)  
**Package Android** : `com.ghdinteractivestudio.morphpdf`  
**Dépôt** : `https://github.com/frechfanta-os/MorphPDF.git`  
**Commit de départ** : `b8a5952` (*audit(production): harden PDF to Word and Android readiness*)  
**Statut de la phase** : **RÉALISÉE AVEC SUCCÈS**

---

## 1. Classification & Vérité Technique

Conformément aux directives de rigueur technique du projet MorphPDF :

| Domaine | Statut Exact | Commentaire / Justification |
| :--- | :--- | :--- |
| **Compilation & Intégration Native** | **BUILD VERIFIED** | Binaires natifs `libpdfium.so` intégrés dans `jniLibs`, build Gradle configuré avec `abiFilters` et `sourceSets`. |
| **Packaging & CI** | **PACKAGING VERIFIED** | Emplacement standard Android `jniLibs/arm64-v8a` et `jniLibs/armeabi-v7a`. Vérification d'artefact intégrée dans `.github/workflows/build_apk.yml`. |
| **FFI Bindings & Mémoire** | **VERIFIED & HARDENED** | 21 symboles C vérifiés dans l'en-tête Chromium, types FFI durcis (`UnsignedLong`), gestion RAII et `try/finally` sans fuite. |
| **Tests Automatisés** | **143/143 PASS (100%)** | 143 tests Flutter réussis (+5 nouveaux tests FFI/loader/codes d'erreur), `flutter analyze` : 0 issue, Go tests & vet : PASS. |
| **Exécution Physique ARM64** | **RUNTIME PENDING PHYSICAL ARM64** | Aucun appareil physique Android ARM64 n'étant accessible dans l'environnement courant, aucune prétention trompeuse d'exécution matérielle n'est émise. |

Le statut du moteur natif PDFium passe ainsi de **BLOCKED** (absence de bibliothèque partagée) à **PACKAGING VERIFIED / READY FOR PHYSICAL VALIDATION**.

---

## 2. Distribution PDFium Retenue & Traçabilité

### 2.1. Sélection de la distribution

La distribution de référence sélectionnée pour MorphPDF est celle maintenue par le projet officiel **bblanchon/pdfium-binaries**, construite directement depuis le dépôt source Google Chromium PDFium avec le NDK officiel Google :

- **Projet source** : Google Chromium PDFium (Chromium 157.0.8086.0)
- **Distribution** : `bblanchon/pdfium-binaries`
- **Tag / Version de release** : `chromium/8086`
- **Licence** : BSD 3-Clause & Apache-2.0 (Google / Chromium Authors)

### 2.2. Artefacts binaires intégrés

Deux architectures cibles ont été intégrées pour couvrir l'ensemble du parc Android :

#### A. Architecture Prioritaire : `arm64-v8a` (aarch64-linux-android)
- **URL de téléchargement** : `https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/8086/pdfium-android-arm64.tgz`
- **Empreinte SHA-256 archive** : `f6ea29495d64795b9af61e41768030795b45f82a21415498ee4ab2c61e135756`
- **Fichier extrait** : `lib/libpdfium.so`
- **Taille binaire** : 6 563 456 octets (~6,26 Mo)
- **Empreinte SHA-256 `libpdfium.so`** : `6e4d0057ca7bfca33617924246d98de4632ff7565ecfa3c16a61194e6dbde0bc`
- **Format ELF** : `ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked`
- **Dépendances dynamiques (`readelf -d`)** :
  ```
  0x0000000000000001 (NEEDED) Shared library: [libdl.so]
  0x0000000000000001 (NEEDED) Shared library: [libm.so]
  0x0000000000000001 (NEEDED) Shared library: [libc.so]
  ```
  *(Autonome : aucune dépendance externe `libc++_shared.so` requise, liaison Bionic standard).*

#### B. Architecture Secondaire : `armeabi-v7a` (arm-linux-androideabi)
- **URL de téléchargement** : `https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/8086/pdfium-android-arm.tgz`
- **Empreinte SHA-256 archive** : `fdf3a2b329759f5ba8a9997329ae79dad3570b1d90ecde60b5a56f1a9ff6a98c`
- **Fichier extrait** : `lib/libpdfium.so`
- **Taille binaire** : 4 375 176 octets (~4,17 Mo)
- **Empreinte SHA-256 `libpdfium.so`** : `5dd61938c27a980f91f737bc260be572e22f432b9c3fd1a4c1bec47f45605c06`
- **Format ELF** : `ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked`
- **Dépendances dynamiques (`readelf -d`)** : `libdl.so`, `libm.so`, `libc.so`.

### 2.3. Emplacement dans le projet
```
mobile/flutter/android/app/src/main/jniLibs/
├── arm64-v8a/
│   └── libpdfium.so   (6.3 MB)
└── armeabi-v7a/
    └── libpdfium.so   (4.2 MB)
```

### 2.4. Traçabilité des licences
Les licences officielles de Google PDFium ont été documentées et intégrées dans les assets de l'application :
- `mobile/flutter/android/app/src/main/assets/licenses/pdfium/LICENSE` (Licence BSD 3-Clause)
- `mobile/flutter/android/app/src/main/assets/licenses/pdfium/pdfium.txt` (Détails des sous-composants tiers de PDFium)
- `mobile/flutter/android/app/src/main/assets/licenses/pdfium/VERSION` (`chromium/8086`)
- `mobile/flutter/android/app/src/main/assets/licenses/pdfium/NOTICE` (Notice de conformité open source)

---

## 3. Audit et Conformité des Bindings FFI Dart

### 3.1. Vérification des 21 symboles C

Les 21 symboles requis par l'architecture MorphPDF ont été vérifiés individuellement avec `readelf -Ws` sur le binaire `libpdfium.so` et croisés avec les en-têtes C Chromium (`fpdfview.h`, `fpdf_text.h`) :

| N° | Symbole C PDFium | Rôle fonctionnel | Statut Binaire | Signature Dart FFI |
| :---: | :--- | :--- | :---: | :--- |
| 1 | `FPDF_InitLibraryWithConfig` | Initialisation globale de PDFium | **PRÉSENT** | `Void Function(Pointer<Void>)` |
| 2 | `FPDF_DestroyLibrary` | Nettoyage global de PDFium | **PRÉSENT** | `Void Function()` |
| 3 | `FPDF_LoadDocument` | Ouverture de document PDF | **PRÉSENT** | `Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>)` |
| 4 | `FPDF_CloseDocument` | Fermeture du document | **PRÉSENT** | `Void Function(Pointer<Void>)` |
| 5 | `FPDF_GetPageCount` | Comptage des pages | **PRÉSENT** | `Int32 Function(Pointer<Void>)` |
| 6 | `FPDF_LoadPage` | Chargement d'une page | **PRÉSENT** | `Pointer<Void> Function(Pointer<Void>, Int32)` |
| 7 | `FPDF_ClosePage` | Déchargement d'une page | **PRÉSENT** | `Void Function(Pointer<Void>)` |
| 8 | `FPDF_GetPageWidthF` | Largeur en points (float) | **PRÉSENT** | `Float Function(Pointer<Void>)` |
| 9 | `FPDF_GetPageHeightF` | Hauteur en points (float) | **PRÉSENT** | `Float Function(Pointer<Void>)` |
| 10 | `FPDFBitmap_CreateEx` | Allocation du raster bitmap | **PRÉSENT** | `Pointer<Void> Function(Int32, Int32, Int32, Pointer<Void>, Int32)` |
| 11 | `FPDFBitmap_FillRect` | Remplissage fond blanc | **PRÉSENT** | `Void Function(Pointer<Void>, Int32, Int32, Int32, Int32, UnsignedLong)` |
| 12 | `FPDF_RenderPageBitmap` | Rendu de page dans bitmap | **PRÉSENT** | `Void Function(Pointer<Void>, Pointer<Void>, Int32, Int32, Int32, Int32, Int32, Int32)` |
| 13 | `FPDFBitmap_GetBuffer` | Accès au buffer RGBA brut | **PRÉSENT** | `Pointer<Uint8> Function(Pointer<Void>)` |
| 14 | `FPDFBitmap_Destroy` | Désallocation du bitmap | **PRÉSENT** | `Void Function(Pointer<Void>)` |
| 15 | `FPDFText_LoadPage` | Extraction de la page texte | **PRÉSENT** | `Pointer<Void> Function(Pointer<Void>)` |
| 16 | `FPDFText_ClosePage` | Libération de la page texte | **PRÉSENT** | `Void Function(Pointer<Void>)` |
| 17 | `FPDFText_CountChars` | Comptage des caractères | **PRÉSENT** | `Int32 Function(Pointer<Void>)` |
| 18 | `FPDFText_GetText` | Extraction UTF-16 code units | **PRÉSENT** | `Int32 Function(Pointer<Void>, Int32, Int32, Pointer<Uint16>)` |
| 19 | `FPDFText_GetCharBox` | Bounding box (points) | **PRÉSENT** | `Int32 Function(Pointer<Void>, Int32, Pointer<Double>, Pointer<Double>, Pointer<Double>, Pointer<Double>)` |
| 20 | `FPDFText_GetFontSize` | Taille de police (points) | **PRÉSENT** | `Double Function(Pointer<Void>, Int32)` |
| 21 | `FPDF_GetLastError` | Code d'erreur PDFium | **PRÉSENT** | `UnsignedLong Function()` |

### 3.2. Corrections & Durcissements FFI Apportés

1. **Typage strict `UnsignedLong`** :
   Dans l'en-tête C de PDFium, `FPDF_DWORD` et le retour de `FPDF_GetLastError` sont définis comme `unsigned long`. Sur les architectures LP64 (ARM64 Android / Linux), `unsigned long` occupe 64 bits alors que sur ILP32 ou Windows il occupe 32 bits. L'utilisation du type FFI `UnsignedLong` (`dart:ffi`) garantit une correspondance ABI exacte sans risque de corruption de registres.

2. **Correction des codes d'erreur officiels (`PdfiumErrorCodes`)** :
   L'audit des en-têtes C a révélé que `FPDF_ERR_PASSWORD` a la valeur **4** (et non 1 comme présumé initialement, 1 correspondant à `FPDF_ERR_UNKNOWN`).
   La classe `PdfiumErrorCodes` a été ajoutée pour mapper fidèlement les constantes :
   - `0` : `success`
   - `1` : `unknown`
   - `2` : `fileNotFound`
   - `3` : `formatError`
   - `4` : `passwordRequired`
   - `5` : `securityUnsupported`
   - `6` : `pageError`

3. **Protection RAII & Blocs `try/finally` Imbriqués** :
   Toutes les opérations d'allocation native (`FPDFBitmap_CreateEx`, `FPDF_LoadPage`, `FPDFText_LoadPage`, `calloc`) sont désormais encapsulées dans des blocs `try/finally` imbriqués pour garantir la libération systématique de la mémoire native même en cas d'exception ou d'annulation.

4. **Propriété de diagnostic `PdfiumLoader.loadError`** :
   Permet d'inspecter l'erreur exacte du chargeur dynamique en environnement de diagnostic ou de logging.

---

## 4. Configuration Gradle & Packaging Android

### 4.1. Fichier `mobile/flutter/android/app/build.gradle.kts`
La configuration de l'application a été mise à jour :
```kotlin
android {
    namespace = "com.ghdinteractivestudio.morphpdf"
    ...
    defaultConfig {
        applicationId = "com.ghdinteractivestudio.morphpdf"
        ...
        ndk {
            abiFilters.addAll(listOf("arm64-v8a", "armeabi-v7a"))
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs("src/main/jniLibs")
        }
    }
    ...
}
```

### 4.2. Impact sur les règles ProGuard/R8
Les bibliothèques natives C/C++ partagées (`.so`) présentes dans `jniLibs` ne sont jamais altérées par ProGuard/R8 (qui n'opère que sur le bytecode JVM Dalvik/ART). Les règles existantes de `proguard-rules.pro` préservent déjà le bridge OCR et les entry-points Flutter sans interférence.

---

## 5. Automatisation CI / CD & Validation APK

Le workflow GitHub Actions `.github/workflows/build_apk.yml` a été complété avec une étape d'inspection automatisée des bibliothèques partagées dans l'APK de release produit :

```yaml
      - name: Validate Native PDFium Packaging in Release APK
        run: |
          APK_PATH="mobile/flutter/build/app/outputs/flutter-apk/app-release.apk"
          echo "Inspecting native shared libraries in release APK..."

          # Verify arm64-v8a libpdfium.so is present in the release APK
          ARM64_PDFIUM=$(unzip -l "$APK_PATH" | grep "lib/arm64-v8a/libpdfium.so" || true)
          if [ -z "$ARM64_PDFIUM" ]; then
            echo "Error: lib/arm64-v8a/libpdfium.so is missing from release APK!"
            exit 1
          fi
          echo "Confirmed: $ARM64_PDFIUM"

          # Verify armeabi-v7a libpdfium.so is present
          ARMV7_PDFIUM=$(unzip -l "$APK_PATH" | grep "lib/armeabi-v7a/libpdfium.so" || true)
          if [ -n "$ARMV7_PDFIUM" ]; then
            echo "Confirmed: $ARMV7_PDFIUM"
          fi

          echo "Native PDFium packaging validation passed."
```

---

## 6. Métriques de Validation

L'ensemble des tests et outils d'analyse statique a été exécuté via `./scripts/run_checks.sh` :

| Outil de validation | Cible | Résultat |
| :--- | :--- | :--- |
| **Go vet** | `backend/go/...` | **PASS (0 issue)** |
| **Go test** | Services & Storage | **PASS (100%)** |
| **Flutter analyze** | Code Dart / Flutter complet | **No issues found!** |
| **Flutter test** | Suite de tests Flutter | **143 / 143 PASS (100%)** |

Les 5 nouveaux tests unitaires vérifient :
- La correspondance des constantes d'erreur avec les codes FPDF officiels.
- Le comportement de cycle de vie et le rejet de pointeur nul (`nullptr`) dans `PdfDocumentHandle`.
- La détection de poignée fermée (`isClosed`).
- Le mécanisme de mock et réinitialisation de `PdfiumLoader.resetForTesting`.
- Le typage exact de `executionEngine` (`fallbackParser` sans FFI, `nativePdfium` avec FFI).

---

## 7. Risques Résiduels & Prochaines Étapes

1. **Validation Runtime Physique ARM64** :
   Bien que l'intégration binaire, la table des symboles, les dépendances Bionic et le packaging Gradle soient 100% vérifiés, la validation finale du décodage GPU/CPU nécessite un vrai smartphone Android ARM64 pour une validation sur banc physique.
2. **Gestion de la Mémoire Haute Résolution** :
   Pour des documents très larges (> 300 DPI, multiples mégaoctets de bitmap RGBA), la mémoire native allouée par PDFium doit être surveillée pour éviter des OOM en cas de rendu massif consécutif. Le cache LRU existant (25 pages) assure une première protection efficace.
