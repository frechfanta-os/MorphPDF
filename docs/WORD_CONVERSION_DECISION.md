# MorphPDF — Décision Technique : Moteur de Conversion PDF vers Word (.docx)
## Phase 5.0 — Audit Technique et Sélection de l'Architecture de Conversion

---

## 1. Executive Summary

La conversion d'un document PDF en un document Microsoft Word (.docx) véritablement éditable constitue l'un des défis les plus complexes du traitement documentaire. Le format PDF est un langage graphique de description de page statique basé sur des coordonnées cartésiennes absolues ($X, Y$), sans notion intrinsèque de paragraphe, de tableau ou de flux textuel. À l'opposé, le format DOCX (norme ECMA-376 / ISO/IEC 29500 OpenXML) est un format sémantique à flux dynamique (*flow-based*), structuré en sections, paragraphes, styles hiérarchiques et grilles tabulaires.

L'objectif de cette étude technique (Phase 5.0) est de définir l'architecture de production pour MorphPDF sans recourir à des raccourcis trompeurs (ex: simple conversion en texte brut renommé en `.docx`, injection HTML simpliste, conversion par IA dans le cloud ou boîte noire propriétaire sous licence fermée).

### Décision Clé de l'Audit :
1. **Moteur Primaire de Production** : **MorphPDF Sovereign OOXML Engine en Dart Pur** (`package:archive` + sérialisation directe de l'arborescence XML conforme ISO/IEC 29500).
   - Exécution 100% in-process côté Flutter / Dart.
   - Zéro dépendance native C/C++, zéro couche JNI/NDK supplémentaire, zéro surcoût de sérialisation IPC.
   - Prise en charge native et déterministe des balises arabes et BiDi (`<w:bidi/>`, `<w:rtl/>`), des tables en twips (`dxa`), des dimensions d'images en EMU et des styles typographiques.
2. **Moteur Secondaire / Serveur** : **Service Go OOXML Stream** (`backend/go/internal/conversion`) pour les traitements batch lourds ou serveurs/desktop futurs, partageant les mêmes spécifications d'encapsulation ZIP/XML.
3. **Cible de Fidélité Réaliste** : **Niveau 3.5 - 4 (Fidélité Structurelle et Sémantique Éditables)**. MorphPDF rejette catégoriquement le "pixel-perfect" figé à base de centaines de zones de texte flottantes absolues (*text boxes*), qui rend tout document Word inexploitable à l'édition par l'utilisateur final.

---

## 2. Requirements & Spécifications Métier

Le moteur de conversion PDF $\rightarrow$ Word de MorphPDF doit respecter le cahier des charges suivant :

- **Entrées supportées** :
  - PDFs textuels natifs (vectoriels, caractères extractibles via PDFium).
  - PDFs scannés traités via le pipeline OCR local (PaddleOCR ONNX / ML Kit).
  - Documents mixtes (pages textuelles intercalées avec des pages scannées).
- **Éléments structurels à reconstituer** :
  - Paragraphes continus avec détection des césures et des sauts de ligne.
  - Styles typographiques : graisses (gras), italiques, soulignés, tailles de police proportionnelles.
  - Hiérarchie de titres (Titre du document, Heading 1, Heading 2, Corps de texte).
  - Alignement des paragraphes : Gauche, Centré, Droite, Justifié.
  - Tableaux avec détection des lignes et colonnes, cellules fusionnées et alignements internes.
  - Images bitmaps extraites directement des flux PDF (PNG/JPEG) insérées au bon ratio.
  - Sauts de page et dimensions de page conformes (A4, Letter, marges réelles).
  - Colonnes multiples (détection des flux de lecture à 2 ou 3 colonnes).
  - Hyperliens et annotations cliquables lorsque présents dans le PDF source.
- **Support Linguistique & Script Arabe (Priorité 1)** :
  - Textes arabes natifs et bilingues (Arabe + Français / Anglais).
  - Chiffres occidentaux (0-9) et arabo-indiens (٠-٩).
  - Alignement des paragraphes RTL (`<w:bidi/>`, `<w:jc w:val="right"/>`).
  - Propriétés de run RTL (`<w:rPr><w:rtl/></w:rPr>`) assurant le rendu fluide sous Microsoft Word et LibreOffice Writer.
- **Contraintes de Plateforme** :
  - Android-first, 100% hors-ligne (*offline-first*).
  - Aucune transmission de documents vers OpenRouter, Cloudflare R2 ou tout service cloud.
  - Empreinte binaire minimale et compatibilité totale avec les builds GitHub Actions sans SDK Android local.

---

## 3. Current MorphPDF Architecture

MorphPDF dispose déjà des piliers fondamentaux nécessaires pour alimenter le convertisseur :

```
[ Fichier PDF Source ]
         │
         ├──► PDFium (Dart FFI) ──► Extraction glyphes, fontes, dimensions, images natives
         │
         └──► PaddleOCR (ONNX ARM64) ──► Détection polygones, reconnaissance Arabe/Latin, BiDi
                      │
                      ▼
             [ CoordinateConverter ] (Points PDF 72 DPI <──> Pixels image)
                      │
                      ▼
             [ Unified DocumentModel ]
             ├── PageModel (width, height, rotation)
             ├── TextBlock (x, y, w, h, text, confidence, language)
             ├── ImageBlock (x, y, w, h, source)
             └── TableBlock (x, y, w, h, rows, columns)
                      │
                      ▼
         [ Layout Reconstruction Engine ] ◄── (Phase 5.0 / 5.1)
                      │
                      ▼
         [ Native OOXML DOCX Generator ] ◄── (Phase 5.0 / 5.1)
                      │
                      ▼
               [ Document .docx ]
```

---

## 4. Candidate Libraries Audit

| Option / Bibliothèque | Langage / Runtime | Fonctionnement Local | Complétude OOXML | Support RTL / Arabe | Poids / Empreinte | Licence | Recommandation |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- | :--- |
| **Générateur Direct OOXML MorphPDF** | **Dart Pur** | **100% Local** | **Total (sur-mesure)** | **Natif (`<w:bidi/>`, `<w:rtl/>`)** | **~0.2 Mo** | **Interne / Apache-2.0** | **RETENU — PRIMAIRE** |
| **Générateur OOXML Go Pur** | Go | 100% Local | Élevé | Faisable | Moyen (IPC/lib) | Interne | **RETENU — SECONDAIRE / SERVEUR** |
| **docx_template / docx (pub.dev)** | Dart | Local | Partiel (templates) | Faible | Faible | MIT / BSD | NON RETENU (incomplet) |
| **Apache POI** | Java / Android | Local | Très élevé | Moyen | Très lourd (+40 Mo) | Apache-2.0 | NON RETENU (heap JVM, AWT bugs) |
| **pdf2docx (Python)** | Python / C++ | Local | Élevé | Moyen | Énorme (+50 Mo Chaquopy) | GPLv3 | NON RETENU (licence virale, poids) |
| **LibreOffice Headless** | C++ / Binaires | Impossible mobile | Total | Total | Géant (+500 Mo) | LGPL / MPL | NON RETENU (inapplicable mobile) |
| **Apryse / PSPDFKit / Foxit** | C++ Propriétaire | Local | Total | Élevé | Moyen | Propriétaire fermée ($$$$) | NON RETENU (coûts récurrents, fermé) |

---

## 5. Dart Evaluation

L'écosystème Dart offre un avantage structurel décisif :
- **Intégration directe** : Le modèle spatialisé (`DocumentModel`, `TextBlock`, `PageModel`) est déjà instancié en mémoire dans la machine virtuelle Dart de Flutter.
- **Absence de sérialisation IPC** : Aucun transfert JSON lourd ou via socket vers un processus externe.
- **Gestion des archives ZIP** : Le package `archive` (officiel Dart, Apache-2.0) permet de compresser des flux mémoires directement en archive ZIP sans toucher au système de fichiers ou en écrivant un fichier `.docx` unifié en un seul passage.
- **Construction XML fluide** : Génération directe de chaînes XML via `StringBuffer` ou arbre XML léger, garantissant des allocations mémoires minimes et une vitesse d'exécution optimale sur processeur ARM64 mobile.

---

## 6. Go Evaluation

La couche Go (`backend/go/internal/conversion`) est d'ores et déjà modélisée via l'interface `PdfToWordConverter`.
- **Forces** : Haute performance de manipulation concurrente de fichiers, bibliothèque standard `archive/zip` et `encoding/xml` d'une robustesse absolue.
- **Faiblesses sur terminal mobile** :
  - Exiger l'exécution d'un binaire Go sur Android implique soit la compilation Gomobile sous forme de bibliothèque partagée `.so` (alourdissant l'APK de 15 à 25 Mo), soit un processus démon local sur `127.0.0.1` sujet aux interruptions brutales par le gestionnaire d'énergie d'Android (Doze Mode).
  - Nécessite de sérialiser l'intégralité du `DocumentModel` et des images extraites par PDFium depuis Flutter vers Go.
- **Rôle arrêté** : Le moteur Go est conservé comme **moteur secondaire et serveur**. Il traitera les conversions en mode CLI, serveur déporté ou traitement par lots institutionnel.

---

## 7. Native Android Evaluation (Kotlin / Java)

- L'utilisation de bibliothèques natives Android Java telles qu'Apache POI a été analysée :
  - Apache POI dépend historiquement de classes graphiques Java Desktop (`java.awt.*`, `javax.imageio.*`) absentes du runtime Android ART. L'adaptation nécessite des ports tiers non maintenus (*poi-android*), instables et sujets aux *OutOfMemoryError* dès que le document dépasse 10 pages.
  - La compilation NDK ou l'intégration de bibliothèques C++ de conversion Word génère des conflits d'ABI et une complexité de packaging disproportionnée.
- **Conclusion** : Le recours à une couche native Android spécifique pour la génération DOCX est écarté.

---

## 8. OOXML Architecture & Standard Package Structure

Un document `.docx` valide n'est pas un fichier binaire opaque, mais une archive ZIP structurée selon la norme Open Packaging Conventions (OPC, ECMA-376) contenant les éléments XML obligatoires suivants :

```
mon_document.docx (Archive ZIP)
├── [Content_Types].xml                  (MIME types de chaque partie du package)
├── _rels/
│   └── .rels                            (Lien racine vers word/document.xml)
└── word/
    ├── document.xml                     (Corps principal : paragraphes, tables, runs)
    ├── styles.xml                       (Définition des styles : Normal, Heading 1, 2, etc.)
    ├── settings.xml                     (Paramètres du document, compatibilité Word)
    ├── fontTable.xml                    (Déclaration des polices : Calibri, Traditional Arabic, etc.)
    ├── _rels/
    │   └── document.xml.rels            (Relations vers images, styles, liens hypertextes)
    └── media/
        ├── image1.png                   (Images vectorielles ou bitmaps extraites)
        └── image2.jpeg
```

### Validité Minimale Absolue :
Tout fichier `.docx` généré par MorphPDF doit comporter au strict minimum :
1. `[Content_Types].xml` avec déclaration de `application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml`.
2. `_rels/.rels` ciblant `word/document.xml`.
3. `word/document.xml` contenant au moins un élément `<w:body>`.
4. `word/styles.xml` assurant un rendu visuel harmonieux et prévisible sur Microsoft Word (Windows/macOS/Mobile), LibreOffice et Google Docs.

---

## 9. Layout Reconstruction Engine (Le Cœur du Problème)

La restitution d'un document éditable à partir de positions cartésiennes spatiales ($X, Y, W, H$) nécessite un pipeline d'analyse heuristique en 6 étapes :

```
Points Spatiaux (TextBlocks / OcrBlocks)
         │
         ▼
[1. Détection des Colonnes et Blocs de Flux] (Clustering sur l'axe X)
         │
         ▼
[2. Tri selon l'Ordre de Lecture] (Top-to-Bottom, Left-to-Right ou Right-to-Left)
         │
         ▼
[3. Fusion des Lignes en Paragraphes] (Analyse de la distance interligne ΔY et de la ponctuation)
         │
         ▼
[4. Détection des Propriétés de Paragraphe] (Alignement, indentation de 1ère ligne, espacement)
         │
         ▼
[5. Segmentation en Runs Typographiques] (Variations de taille, graisse, couleur, écriture)
         │
         ▼
[6. Émission des Balises OpenXML] (<w:p>, <w:pPr>, <w:r>, <w:rPr>, <w:t>)
```

### Classification des Capacités de Restitution :
- **EXACTEMENT PRÉSERVÉ** :
  - Contenu textuel et caractères Unicode (Latin, Arabe, chiffres).
  - Images bitmaps d'origine extraites du PDF (ratio d'aspect et résolution).
  - Découpage des pages et sauts de page stricts (`<w:br w:type="page"/>`).
  - Marges globales de page calculées à partir de la géométrie de la page.
  - Direction d'écriture des paragraphes (RTL vs LTR).
- **APPROXIMÉ DE MANIÈRE ROBUSTE** :
  - Tailles de police (regroupement par clusters : 10pt, 12pt, 14pt, 18pt, etc.).
  - Graisse et style (détecté via les noms de police PDFium ou heuristique de taille).
  - Alignement des paragraphes (centré, justifié, gauche, droite via analyse des marges des lignes).
  - Tableaux (détection des intersections de lignes et alignements tabulaires).
  - Colonnes multiples (détection des gouttières verticales blanches).
- **NON RESTITUABLE DE MANIÈRE FIABLE SANS HYPOTHÈSE SÉMANTIQUE** :
  - Les styles Word nommés personnalisés du créateur d'origine (ex: style "MonTitrePerso").
  - Les champs dynamiques (numéros de page calculés automatiquement dans les en-têtes complexes).
  - Les lettrines et habillages de texte complexes autour d'images polygonales non rectangulaires.

---

## 10. Traitement des PDFs Textuels Natifs

Dans un PDF vectoriel, PDFium fournit la position exacte et le texte de chaque glyphe via l'API `FPDFText_*`.
- **Reconstitution des Mots et Lignes** : L'algorithme `TextGrouper` existant fusionne les glyphes voisins dont l'écart horizontal est inférieur à l'espace inter-mots moyen.
- **Gestion des Polices** :
  - Le PDF peut embarquer des polices de caractères spécifiques (ex: *HelveticaNeue-Bold*, *TimesNewRomanPSMT*, *Amiri-Regular*).
  - **Stratégie de substitution** : Microsoft Word ne dispose pas nécessairement des polices embarquées dans le PDF. MorphPDF définira des polices de substitution standard de haute qualité dans `fontTable.xml` :
    - Écritures latines sans-serif : `Calibri`, `Arial`.
    - Écritures latines serif : `Times New Roman`, `Georgia`.
    - Écritures arabes : `Traditional Arabic`, `Calibri`, `Amiri`.
  - La taille de police est extraite en points PDF et convertie en demi-points OpenXML :
    $$\text{Taille OOXML} = \text{round}(\text{font\_size\_pt} \times 2)$$

---

## 11. Traitement des PDFs Scannés (Flux OCR)

Pour les documents scannés issus du pipeline PaddleOCR (Phase 4.1) :
- Les données d'entrée proviennent de `OcrPageResult` avec des boîtes englobantes (`OcrBoundingBox`) en pixels raster.
- **Projection cartésienne** : `OcrCoordinateMapper` transpose les coordonnées en points PDF via `CoordinateConverter.pixelRectToPdfRect`.
- **Indicateur de Confiance** :
  - Les blocs dont la confiance OCR est $\ge 0.85$ sont transcrits normalement dans le flux Word.
  - Les blocs à faible confiance ($< 0.60$) ne reçoivent pas de filigrane dégradant le document, mais sont étiquetés en métadonnées de style (option de surlignage discret configurable par l'utilisateur).
- **Pages Mixtes** : MorphPDF vérifie si la page contient du texte vectoriel via PDFium (`hasText`). Si oui, le texte vectoriel est privilégié ; si la page est une image pure (scan), le résultat OCR est injecté dans le moteur de mise en page.

---

## 12. Support Arabe & RTL dans OpenXML (Spécification Précise)

L'arabe exige une gestion spécifique tant au niveau du paragraphe qu'au niveau du fragment textuel (*run*) :

### A. Au niveau du Paragraphe (`<w:pPr>`)
Pour indiquer à Word que le paragraphe se lit de droite à gauche :
```xml
<w:p>
  <w:pPr>
    <w:bidi/>
    <w:jc w:val="right"/>
  </w:pPr>
  ...
</w:p>
```
- `<w:bidi/>` active le moteur de disposition bidirectionnelle de Word.
- `<w:jc w:val="right"/>` cale l'alignement naturel du texte à droite.

### B. Au niveau du Fragment Textuel (`<w:rPr>`)
Pour indiquer que les caractères appartiennent au jeu d'écriture complexe (Complex Script) :
```xml
<w:r>
  <w:rPr>
    <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Traditional Arabic"/>
    <w:rtl/>
    <w:sz w:val="24"/>
    <w:szCs w:val="26"/>
  </w:rPr>
  <w:t>الجمهورية الجزائرية الديمقراطية الشعبية</w:t>
</w:r>
```
- `<w:rtl/>` force l'analyseur Word à appliquer la mise en forme cursive et les ligatures arabes via son moteur de rendu de texte complexe.
- `<w:szCs>` permet de spécifier une taille adaptée aux écritures arabes (souvent plus lisibles avec 1 à 2 points de plus que le texte latin adjacent).
- **Règle capitale** : Le texte stocké dans `<w:t>` **doit être dans l'ordre logique Unicode standard**. Le moteur Word effectue lui-même l'inversion visuelle et les ligatures cursives. Le module `BidiNormalizer` de MorphPDF garantit précisément cet ordre logique.

---

## 13. Reconstitution des Tableaux (`<w:tbl>`)

Les tableaux représentent l'une des structures les plus sensibles :
- **Détection** :
  - Soit via détection géométrique de lignes de séparation horizontales et verticales dans le PDF vectoriel.
  - Soit via alignement récurrent de colonnes de texte sur plusieurs lignes consécutives (`TableBlock`).
- **Représentation OpenXML** :
  ```xml
  <w:tbl>
    <w:tblPr>
      <w:tblW w:w="0" w:type="auto"/>
      <w:tblBorders>
        <w:top w:val="single" w:sz="4" w:space="0" w:color="auto"/>
        <w:left w:val="single" w:sz="4" w:space="0" w:color="auto"/>
        <w:bottom w:val="single" w:sz="4" w:space="0" w:color="auto"/>
        <w:right w:val="single" w:sz="4" w:space="0" w:color="auto"/>
        <w:insideH w:val="single" w:sz="4" w:space="0" w:color="auto"/>
        <w:insideV w:val="single" w:sz="4" w:space="0" w:color="auto"/>
      </w:tblBorders>
    </w:tblPr>
    <w:tblGrid>
      <w:gridCol w:w="4500"/>
      <w:gridCol w:w="4500"/>
    </w:tblGrid>
    <w:tr>
      <w:tc>
        <w:tcPr><w:tcW w:w="4500" w:type="dxa"/></w:tcPr>
        <w:p><w:r><w:t>Cellule 1</w:t></w:r></w:p>
      </w:tc>
      <w:tc>
        <w:tcPr><w:tcW w:w="4500" w:type="dxa"/></w:tcPr>
        <w:p><w:r><w:t>Cellule 2</w:t></w:r></w:p>
      </w:tc>
    </w:tr>
  </w:tbl>
  ```
- **Limites d'Ingénierie Claires** : Les tableaux sans bordures (espaces tabulaires implicites) sont plus difficiles à distinguer d'un texte multi-colonnes. MorphPDF privilégiera dans ce cas un tableau avec bordures invisibles (`w:val="none"`), garantissant un alignement vertical parfait sans perturber la lecture.

---

## 14. Extraction et Insertion des Images (DrawingML)

- **Extraction Native** : PDFium permet d'extraire les objets images au format natif non ré-échantillonné (`FPDFImageObj_GetImageDataDecoded`), préservant la qualité maximale du document sans altération par compression supplémentaire.
- **Stockage dans le Package** : Les images sont enregistrées sous `word/media/image_{page}_{index}.png` ou `.jpeg`.
- **Déclaration DrawingML** :
  L'image est insérée dans un paragraphe via le balisage standard DrawingML `<w:drawing>` :
  ```xml
  <w:drawing>
    <wp:inline distT="0" distB="0" distL="0" distR="0">
      <wp:extent cx="5715000" cy="3810000"/>
      <wp:docPr id="1" name="Image 1"/>
      <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
        <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
          <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
            ...
            <pic:blipFill>
              <a:blip r:embed="rIdImage1"/>
            </pic:blipFill>
            <pic:spPr>
              <a:xfrm>
                <a:off x="0" y="0"/>
                <a:ext cx="5715000" cy="3810000"/>
              </a:xfrm>
              <a:prstGeom prst="rect"/>
            </pic:spPr>
          </pic:pic>
        </a:graphicData>
      </a:graphic>
    </wp:inline>
  </w:drawing>
  ```
- **Conversion d'Échelle EMU** :
  $$\text{Largeur EMU} = \text{round}(\text{width\_pt} \times 12700)$$
  $$\text{Hauteur EMU} = \text{round}(\text{height\_pt} \times 12700)$$

---

## 15. Détection des En-têtes et Pieds de Page

- Les blocs textuels situés dans les 5% supérieurs de la page ($Y \le 0.05 \times \text{page\_height}$) ou les 5% inférieurs ($Y \ge 0.95 \times \text{page\_height}$) qui se répètent identiquement sur au moins 3 pages consécutives sont identifiés comme en-têtes et pieds de page récurrents.
- En Phase 5.1, ces blocs seront insérés en tant que paragraphes d'en-tête/pied de page de section (`word/header1.xml`, `word/footer1.xml`), évitant ainsi la répétition polluante de texte au milieu du flux éditable.

---

## 16. Listes et Numérotations

- Reconstitution heuristique des listes :
  - Détection de puces standards : `•`, `-`, `–`, `*`, `▪`.
  - Détection de numérotations régulières : `1.`, `2.`, `a)`, `I.`, etc.
  - Détection de numérotation arabe : `١-`, `٢-`.
- En OpenXML, l'application peut formater ces éléments soit sous forme de paragraphes indentés avec puce textuelle dans un run dédié, soit via la ressource `word/numbering.xml`. Pour garantir une interopérabilité maximale sur tous les lecteurs DOCX sans risque de corruption de schéma, MorphPDF utilisera une indentation de paragraphe native (`<w:ind w:left="720" w:hanging="360"/>`) avec glyphe de puce explicite en première étape.

---

## 17. Détection des Documents Multi-Colonnes

- Les journaux, rapports et articles scientifiques utilisent souvent 2 ou 3 colonnes.
- **Algorithme de Détection** :
  1. Projection sur l'axe X des coordonnées des boîtes englobantes sur la page.
  2. Détection des "vallées blanches" (espaces verticaux continus de largeur $\ge 15 \text{ pt}$ sans aucun texte).
  3. Si une vallée centrale divise la page, les blocs sont partitionnés en Colonne Gauche et Colonne Droite.
  4. L'ordre de lecture traite alors l'intégralité de la première colonne (du haut vers le bas) avant de passer à la colonne suivante (ou de droite à gauche en Arabe).
  5. En OpenXML, cela se traduit par une section à colonnes multiples (`<w:cols w:num="2" w:space="720"/>`) ou un flux de lecture séquencé correctement dans les paragraphes.

---

## 18. Hyperliens et Annotations

- PDFium expose les annotations de liens via `FPDFLink_*` ou `FPDFAnnot_*`.
- Si un lien web (`URI`) ou une référence interne est détecté dans le document source, il est converti en relation OpenXML dans `word/_rels/document.xml.rels` (`Target="https://..." Type="http://.../hyperlink"`) et enveloppé dans la balise `<w:hyperlink r:id="rIdLink...">`.

---

## 19. Gestion de la Mise en Page (Page Layout & Unités)

Le système de mesure documentaire repose sur trois échelles harmonisées :

| Concept | Unité Source (PDF) | Unité OpenXML Word | Formule de Conversion |
| :--- | :--- | :--- | :--- |
| **Dimensions de page & Marges** | Points PDF ($1/72$ pouce) | **Twips** (dxa, $1/20$ point) | $\text{dxa} = \text{round}(\text{pt} \times 20)$ |
| **Tailles de polices de caractères** | Points PDF | **Demi-points** ($1/2$ pt) | $\text{half\_pt} = \text{round}(\text{pt} \times 2)$ |
| **Dimensions d'images & graphismes** | Points PDF | **EMU** ($1/914400$ pouce) | $\text{EMU} = \text{round}(\text{pt} \times 12700)$ |

### Formats Courants Standardisés :
- **A4 Portrait** : $595.28 \times 841.89 \text{ pt} = 11906 \times 16838 \text{ dxa}$.
- **A4 Paysage (Landscape)** : $841.89 \times 595.28 \text{ pt} = 16838 \times 11906 \text{ dxa}$ avec `<w:pgSz w:orient="landscape"/>`.
- **US Letter** : $612.0 \times 792.0 \text{ pt} = 12240 \times 15840 \text{ dxa}$.

---

## 20. Sécurité et Résilience Hors-Ligne

- **Souveraineté des Données** : Aucun octet du PDF, aucun texte extrait et aucune image ne transitent par un réseau distant. L'ensemble de la génération ZIP/XML se déroule dans l'espace mémoire sandboxé de l'application sur le terminal.
- **Protection Anti-Zip Bomb** : Limitation stricte de la taille maximale des images décompressées et limitation de l'archive finale générée à 200 Mo.
- **Protection contre les Injections XML** : Tous les textes extraits sont rigoureusement échappés pour les entités XML :
  - `&` $\rightarrow$ `&amp;`
  - `<` $\rightarrow$ `&lt;`
  - `>` $\rightarrow$ `&gt;`
  - `"` $\rightarrow$ `&quot;`
  - `'` $\rightarrow$ `&apos;`
  - Les caractères de contrôle illégaux en XML 1.0 (ex: codes ASCII $0x00 \dots 0x08$, $0x0B \dots 0x0C$, $0x0E \dots 0x1F$) sont systématiquement nettoyés pour prévenir toute erreur de parsing dans Word.

---

## 21. Performances Prévisionnelles & Benchmarks Cibles

Les objectifs de performance sur terminal mobile Android standard (processeur milieu de gamme ARM64, 4 Go RAM) :

| Scénario de Test | Pages | Temps Cible Extraction | Temps Cible Reconstitution | Temps Cible Émission DOCX | Temps Total |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Document Texte Léger (A4)** | 1 | $< 50$ ms | $< 20$ ms | $< 30$ ms | **$< 100$ ms** |
| **Rapport Standard (Texte + Styles)** | 10 | $< 350$ ms | $< 120$ ms | $< 150$ ms | **$< 650$ ms** |
| **Livre / Document Volumineux** | 50 | $< 1800$ ms | $< 600$ ms | $< 800$ ms | **$< 3.5$ s** |
| **Document Scanné OCR (150 DPI)** | 1 | $< 600$ ms (OCR) | $< 30$ ms | $< 50$ ms | **$< 700$ ms** |
| **Document Riche (Arabe + Images + Tables)** | 5 | $< 400$ ms | $< 200$ ms | $< 250$ ms | **$< 900$ ms** |

---

## 22. Analyse des Licences Logicielles

- **Dart `package:archive`** : Licence Apache-2.0 $\rightarrow$ **SAFE** (compatible commercial, aucune contamination virale).
- **Dart `package:xml`** : Licence BSD-3-Clause $\rightarrow$ **SAFE**.
- **Code de Reconstitution MorphPDF** : Propriété intellectuelle interne GHD Interactive Studio $\rightarrow$ **SAFE**.
- **Bibliothèques Écartées** :
  - `pdf2docx` (Python) : GPLv3 $\rightarrow$ **NOT RECOMMENDED** (contraintes de distribution virales).
  - `unioffice` (Go) : AGPLv3 / Commercial payant $\rightarrow$ **NOT RECOMMENDED**.

---

## 23. Compatibilité Android & Packaging

- Le moteur en Dart pur ne compile aucun code C/C++ additionnel.
- Aucun fichier `.so` natif supplémentaire n'est requis dans l'APK.
- Zéro impact sur la taille de l'APK au-delà des classes Dart compilées (< 300 Ko).
- Fonctionnement garanti sur toutes les versions d'Android (API 21 à API 35+) et toutes les architectures CPU (arm64-v8a, armeabi-v7a, x86_64).

---

## 24. Reproductibilité sous GitHub Actions

- Puisque la conversion repose sur du code Dart pur standard :
  - `flutter test` exécute l'intégralité des tests de conversion sous Linux headless sans émulateur.
  - Les tests de validation de l'archive DOCX (décompression ZIP, validation de schéma XML, présence des fichiers obligatoires) s'exécutent en moins de 2 secondes dans les runners GitHub Actions Ubuntu.
  - Aucune dépendance système externe (pas besoin d'installer LibreOffice, Python ou Java spécifique dans le workflow CI).

---

## 25. Frontière et Rôle de l'Intelligence Artificielle (AI Boundary)

Conformément à la charte d'architecture de MorphPDF :
- **L'IA est strictement interdite pour la conversion nominale** : La conversion PDF $\rightarrow$ Word de base **doit fonctionner à 100% hors-ligne et sans aucun appel à OpenRouter**.
- **Rôle Optionnel Futur (Phase 6+)** : Si l'utilisateur active explicitement une fonction "Optimisation IA", le backend OpenRouter pourra uniquement suggérer des corrections sémantiques de mise en page (ex: identifier qu'une ligne en gras isolée est un "Titre de section de niveau 2" au lieu d'un paragraphe ordinaire), mais le moteur de génération DOCX reste le même.

---

## 26. Cible de Fidélité Réaliste (Fidelity Target)

MorphPDF définit formellement 5 niveaux de fidélité pour une conversion PDF $\rightarrow$ Word :

```
[ Niveau 1 : Texte Linéaire Brut ] ──► (Inacceptable : perte de toute mise en page)
         │
[ Niveau 2 : Texte + Attributs Inline ] ──► (Gras, italique, tailles, mais pas de structure)
         │
[ Niveau 3 : Structure Documentaire ] ──► (Paragraphes, titres, images, tables simples)
         │
[ Niveau 4 : Fidélité Sémantique et Éditabilité ] ◄── CIBLE MORPHPDF (NIVEAU 3.5 - 4)
  - Paragraphes continus éditables
  - Tableaux avec vraies cellules Word
  - Images intégrées au flux DrawingML
  - Arabe / RTL fluide et modifiable
  - Multi-colonnes et marges respectées
         │
[ Niveau 5 : "Pixel-Perfect" Absolu ] ──► (REJETÉ : Boîtes de texte flottantes non éditables)
```

> [!IMPORTANT]
> **Pourquoi le Niveau 5 (Pixel-Perfect) est rejeté** : Les outils qui prétendent au "pixel-perfect" créent une boîte de texte flottante (`<w:txbxContent>`) pour chaque fragment de phrase à des coordonnées millimétrées. Le résultat visuel ressemble au PDF, mais le document est **totalement inexploitable** : dès que l'utilisateur modifie un mot, le texte déborde et chevauche les éléments voisins. MorphPDF produit un **vrai document Word modifiable** (Niveau 3.5 - 4).

---

## 27. Matrice de Décision

| Critère | Solution Retenue (Dart OOXML Direct) | Option Go (Gomobile/IPC) | Option Native Android (Apache POI) | Option LibreOffice / Externe |
| :--- | :---: | :---: | :---: | :---: |
| **Fonctionnement Mobile Hors-Ligne** | ⭐⭐⭐⭐⭐ (Parfait) | ⭐⭐⭐ (Gestion Doze) | ⭐⭐⭐ (Instabilité heap) | ❌ (Impossible) |
| **Vitesse d'Exécution & Latence** | ⭐⭐⭐⭐⭐ (In-Process) | ⭐⭐⭐ (Surcoût IPC) | ⭐⭐ (Lenteur JVM) | ❌ |
| **Support Arabe / BiDi natif** | ⭐⭐⭐⭐⭐ (Total) | ⭐⭐⭐⭐ (Très bon) | ⭐⭐⭐ (Complexe) | ⭐⭐⭐⭐⭐ |
| **Empreinte Binaire APK** | ⭐⭐⭐⭐⭐ (+0.2 Mo) | ⭐⭐ (+20 Mo) | ⭐ (+40 Mo) | ❌ (+500 Mo) |
| **Simplicité de Maintenance** | ⭐⭐⭐⭐⭐ (Code unifié) | ⭐⭐⭐ (Double stack) | ⭐⭐ (Spécifique Java) | ❌ |
| **Sécurité & Confidentialité** | ⭐⭐⭐⭐⭐ (100% Local) | ⭐⭐⭐⭐⭐ (100% Local) | ⭐⭐⭐⭐⭐ (100% Local) | ⭐⭐⭐ |
| **Robustesse CI GitHub Actions** | ⭐⭐⭐⭐⭐ (100% Reproductible)| ⭐⭐⭐ (Cross-build NDK)| ⭐⭐⭐ (Setup Gradle)| ❌ |

---

## 28. Final Decision

1. **Moteur Primaire Retenu** : **MorphPDF Sovereign OOXML Engine en Dart Pur** (`package:archive` + encodeur XML OpenXML conforme ISO/IEC 29500).
2. **Moteur Secondaire Retenu** : **Go OOXML Pipeline** dans `backend/go/internal/conversion` pour le traitement par lots serveur et l'outillage CLI.
3. **Format de Sortie Garanti** : Véritable archive `.docx` valide, lisible et éditable sans avertissement de corruption sur Microsoft Word (Desktop/Web/Mobile), LibreOffice Writer, Google Docs et Apple Pages.

---

## 29. Architecture Proposée (Composants à Développer en Phase 5.1)

```
mobile/flutter/lib/core/docx/
├── ooxml_builder.dart                 // Générateur des fichiers XML (document.xml, styles.xml, rels, etc.)
├── ooxml_package.dart                 // Assemblage de l'archive ZIP OPC via package:archive
├── ooxml_units.dart                   // Conversions mathématiques Points <-> Twips <-> Half-Points <-> EMU
├── ooxml_styles.dart                  // Définition des styles typographiques et polices de secours
└── layout/
    ├── layout_reconstructor.dart      // Partitionnement des TextBlocks en paragraphes et colonnes
    ├── table_reconstructor.dart       // Agrégation matricielle des TableBlocks en grilles OpenXML
    ├── image_reconstructor.dart       // Intégration DrawingML des ImageBlocks
    └── rtl_flow_manager.dart          // Application des balises <w:bidi/> et <w:rtl/> via BidiNormalizer
```

---

## 30. Plan d'Implémentation Phase 5.1

- **Étape 1 : Fondations OOXML & Package ZIP** : Implémentation du constructeur d'archives OPC conforme ISO/IEC 29500 (`[Content_Types].xml`, `_rels/.rels`, `word/document.xml`, `word/styles.xml`).
- **Étape 2 : Moteur de Reconstitution Géométrique** : Algorithme de regroupement vertical des lignes en paragraphes continus, détection des titres et des listes.
- **Étape 3 : Module Arabe & BiDi Avancé** : Injection rigoureuse des balises `<w:bidi/>`, `<w:rtl/>` et polices arabes adaptées.
- **Étape 4 : Module Tableaux & Images** : Reconstitution des grilles `<w:tbl>` avec largeurs en twips et insertion DrawingML des flux images.
- **Étape 5 : Intégration de l'Abstraction `PdfToWordConverter`** : Raccordement du service Flutter et des interfaces de progression.
- **Étape 6 : Suite de Tests Automatisés** : Tests de validité ZIP, validation de conformité XML et tests de non-régression.

---

## 31. Risques et Stratégies d'Atténuation

| Risque Identifié | Impact | Probabilité | Stratégie d'Atténuation |
| :--- | :---: | :---: | :--- |
| **Avertissement de corruption Word à l'ouverture** | Majeur | Faible | Validation stricte des schémas XSD OpenXML et tests de décompression systématiques. |
| **Mélange de lecture dans les textes multi-colonnes** | Moyen | Moyen | Algorithme de détection des gouttières blanches préalablement au tri Y. |
| **Inversion visuelle des textes arabes sous Word** | Majeur | Faible | Utilisation stricte de l'ordre logique Unicode fourni par `BidiNormalizer` + balisage `<w:rtl/>`. |
| **Débordement mémoire sur documents scannés lourds** | Moyen | Faible | Écriture des images en streaming compressé sans mise en cache simultanée de toutes les pages. |

---

## 32. Plan de Validation

La validation de la Phase 5.1 s'effectuera par étapes automatisées :
1. **Validation ZIP** : L'archive générée doit se décompresser sans erreur via `unzip -t`.
2. **Validation XML** : Tous les fichiers `.xml` extraits doivent être exempts d'erreurs de syntaxe XML.
3. **Vérification des Parties Obligatoires** : Présence impérative de `[Content_Types].xml`, `_rels/.rels`, `word/document.xml`, `word/styles.xml`, `word/_rels/document.xml.rels`.
4. **Validation de Rendu Réel** : Ouverture du document sous Microsoft Word et LibreOffice Writer pour vérifier l'éditabilité réelle, l'absence de chevauchement et la conformité du sens de lecture arabe.
