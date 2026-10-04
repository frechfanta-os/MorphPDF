import 'dart:io';
import 'pdf_corpus_builder.dart';

/// Manages and generates the deterministic 15-file real PDF test corpus for Phase 5.3.
class RealPdfCorpus {
  static const String corpusDir = 'test/fixtures/corpus';

  /// Generates all 15 deterministic PDF files if they do not already exist on disk.
  static Future<Map<String, String>> ensureCorpusGenerated() async {
    final paths = <String, String>{};
    await Directory(corpusDir).create(recursive: true);

    // 01_simple_french.pdf
    paths['01_simple_french'] = '$corpusDir/01_simple_french.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['01_simple_french']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "Rapport d'activite officiel 2026", x: 50, y: 780, fontSize: 20),
            PdfTextItem(text: "Direction Generale - MorphPDF", x: 50, y: 740, fontSize: 14),
            PdfTextItem(text: "Le present document certifie la conversion souveraine sans perte.", x: 50, y: 700, fontSize: 12),
            PdfTextItem(text: "Toutes les operations s'executent en local sur l'appareil.", x: 50, y: 660, fontSize: 12),
          ],
        ],
      ),
    );

    // 02_arabic_rtl.pdf
    paths['02_arabic_rtl'] = '$corpusDir/02_arabic_rtl.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['02_arabic_rtl']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "تقرير الأداء المالي السنوي", x: 50, y: 780, fontSize: 20),
            PdfTextItem(text: "حققت المنظومة الرقمية نتائج استثنائية خلال الربع الأخير.", x: 50, y: 740, fontSize: 12),
            PdfTextItem(text: "الالتزام الكامل بالسيادة الرقمية وتشفير المستندات محليا.", x: 50, y: 700, fontSize: 12),
          ],
        ],
      ),
    );

    // 03_mixed_arabic_french.pdf
    paths['03_mixed_arabic_french'] = '$corpusDir/03_mixed_arabic_french.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['03_mixed_arabic_french']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "Rapport bilingue: مشروع مورف الرقمي", x: 50, y: 780, fontSize: 18),
            PdfTextItem(text: "Architecture locale avec support bilingue pour l'analyse.", x: 50, y: 740, fontSize: 12),
            PdfTextItem(text: "تم إطلاق هذا الإصدار بالتعاون مع فريق GHD Interactive Studio.", x: 50, y: 700, fontSize: 12),
          ],
        ],
      ),
    );

    // 04_two_columns.pdf
    paths['04_two_columns'] = '$corpusDir/04_two_columns.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['04_two_columns']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            // Left column (X: 50)
            PdfTextItem(text: "Colonne Gauche Ligne 1", x: 50, y: 700, fontSize: 12),
            PdfTextItem(text: "Colonne Gauche Ligne 2", x: 50, y: 660, fontSize: 12),
            // Right column (X: 350)
            PdfTextItem(text: "Colonne Droite Ligne 1", x: 350, y: 700, fontSize: 12),
            PdfTextItem(text: "Colonne Droite Ligne 2", x: 350, y: 660, fontSize: 12),
          ],
        ],
      ),
    );

    // 05_heading_document.pdf
    paths['05_heading_document'] = '$corpusDir/05_heading_document.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['05_heading_document']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "1. Architecture Globale", x: 50, y: 780, fontSize: 20),
            PdfTextItem(text: "Introduction aux composants techniques de MorphPDF.", x: 50, y: 740, fontSize: 12),
            PdfTextItem(text: "1.1 Moteur OOXML Local", x: 50, y: 700, fontSize: 15),
            PdfTextItem(text: "Generation native sans serveur ni service tiers.", x: 50, y: 660, fontSize: 12),
            PdfTextItem(text: "1.1.1 Serialisation ECMA-376", x: 50, y: 620, fontSize: 13),
            PdfTextItem(text: "Conformite stricte aux specifications internationales.", x: 50, y: 580, fontSize: 12),
          ],
        ],
      ),
    );

    // 06_bullets_numbering.pdf
    paths['06_bullets_numbering'] = '$corpusDir/06_bullets_numbering.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['06_bullets_numbering']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "Fonctionnalites du systeme :", x: 50, y: 780, fontSize: 14),
            PdfTextItem(text: "• Extraction native PDFium sans perte", x: 50, y: 740, fontSize: 12),
            PdfTextItem(text: "• Normalisation BiDi pour l'arabe", x: 50, y: 710, fontSize: 12),
            PdfTextItem(text: "1. Initialisation du document PDF", x: 50, y: 670, fontSize: 12),
            PdfTextItem(text: "2. Reconstruction spatiale du layout", x: 50, y: 640, fontSize: 12),
            PdfTextItem(text: "3. Generation de l'archive DOCX", x: 50, y: 610, fontSize: 12),
          ],
        ],
      ),
    );

    // 07_table.pdf
    paths['07_table'] = '$corpusDir/07_table.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['07_table']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "Tableau recapitulatif des technologies :", x: 50, y: 780, fontSize: 14),
            PdfTextItem(text: "Composant: PDFium, Version: v122, Statut: Operationnel", x: 50, y: 730, fontSize: 12),
            PdfTextItem(text: "Composant: PaddleOCR, Version: v4 ONNX, Statut: Pret", x: 50, y: 690, fontSize: 12),
            PdfTextItem(text: "Composant: Sovereign OOXML, Version: v1.0, Statut: Valide", x: 50, y: 650, fontSize: 12),
          ],
        ],
      ),
    );

    // 08_table_rtl.pdf
    paths['08_table_rtl'] = '$corpusDir/08_table_rtl.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['08_table_rtl']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "جدول الميزانية التشغيلية :", x: 50, y: 780, fontSize: 16),
            PdfTextItem(text: "البند: الإيرادات العامة، القيمة: ١٠٠٠٠٠ ريال", x: 50, y: 730, fontSize: 12),
            PdfTextItem(text: "البند: المصروفات، القيمة: ٥٠٠٠٠ ريال", x: 50, y: 690, fontSize: 12),
          ],
        ],
      ),
    );

    // 09_images.pdf
    paths['09_images'] = '$corpusDir/09_images.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['09_images']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "Document avec illustration integree", x: 50, y: 780, fontSize: 18),
            PdfTextItem(text: "Image descriptive et schema d'architecture souveraine.", x: 50, y: 740, fontSize: 12),
          ],
        ],
      ),
    );

    // 10_header_footer.pdf (2 pages with matching header and footer)
    paths['10_header_footer'] = '$corpusDir/10_header_footer.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['10_header_footer']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "MorphPDF Enterprise Report", x: 50, y: 800, fontSize: 10),
            PdfTextItem(text: "Page 1 - Contenu de synthese de la premiere section.", x: 50, y: 600, fontSize: 12),
            PdfTextItem(text: "Confidentiel & Souverain", x: 50, y: 40, fontSize: 10),
          ],
          const [
            PdfTextItem(text: "MorphPDF Enterprise Report", x: 50, y: 800, fontSize: 10),
            PdfTextItem(text: "Page 2 - Suite de l'analyse et conclusions techniques.", x: 50, y: 600, fontSize: 12),
            PdfTextItem(text: "Confidentiel & Souverain", x: 50, y: 40, fontSize: 10),
          ],
        ],
      ),
    );

    // 11_landscape.pdf (width=842, height=595)
    paths['11_landscape'] = '$corpusDir/11_landscape.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['11_landscape']!,
      PdfCorpusBuilder.buildPdf(
        width: 842.0,
        height: 595.0,
        pages: [
          const [
            PdfTextItem(text: "Tableau de bord paysage A4", x: 50, y: 520, fontSize: 20),
            PdfTextItem(text: "Format panoramique avec affichage etendu des donnees.", x: 50, y: 470, fontSize: 12),
          ],
        ],
      ),
    );

    // 12_multi_page.pdf (3 pages)
    paths['12_multi_page'] = '$corpusDir/12_multi_page.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['12_multi_page']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [PdfTextItem(text: "Document Multi-Page - Premiere Page", x: 50, y: 780, fontSize: 16)],
          const [PdfTextItem(text: "Document Multi-Page - Deuxieme Page", x: 50, y: 780, fontSize: 16)],
          const [PdfTextItem(text: "Document Multi-Page - Troisieme Page", x: 50, y: 780, fontSize: 16)],
        ],
      ),
    );

    // 13_mixed_complex.pdf (Combined document)
    paths['13_mixed_complex'] = '$corpusDir/13_mixed_complex.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['13_mixed_complex']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "Synthese Globale MorphPDF", x: 50, y: 780, fontSize: 22),
            PdfTextItem(text: "1. Presentation Multilingue", x: 50, y: 740, fontSize: 16),
            PdfTextItem(text: "Le moteur gere l'arabe avec le plus grand soin: تقرير سنوي شامل", x: 50, y: 700, fontSize: 12),
            PdfTextItem(text: "• Item 1: Traitement local", x: 50, y: 660, fontSize: 12),
            PdfTextItem(text: "• Item 2: Zero dependance externe", x: 50, y: 630, fontSize: 12),
          ],
        ],
      ),
    );

    // 14_url_text.pdf (Text with URL)
    paths['14_url_text'] = '$corpusDir/14_url_text.pdf';
    await PdfCorpusBuilder.writePdfFile(
      paths['14_url_text']!,
      PdfCorpusBuilder.buildPdf(
        pages: [
          const [
            PdfTextItem(text: "Portail Officiel et Documentation", x: 50, y: 780, fontSize: 18),
            PdfTextItem(text: "Pour plus d'informations consultez https://morphpdf.example.com en ligne.", x: 50, y: 730, fontSize: 12),
          ],
        ],
      ),
    );

    // 15_stress_document.pdf (10 pages multi-page stress document)
    paths['15_stress_document'] = '$corpusDir/15_stress_document.pdf';
    final stressPages = List.generate(10, (index) {
      final pNum = index + 1;
      return [
        PdfTextItem(text: "MorphPDF Stress Benchmark - Page $pNum", x: 50, y: 780, fontSize: 18),
        PdfTextItem(text: "Section analytique $pNum avec contenu de charge de travail.", x: 50, y: 740, fontSize: 12),
        PdfTextItem(text: "Traitement sequentiel des flux de texte et verification d'integrite.", x: 50, y: 700, fontSize: 12),
      ];
    });
    await PdfCorpusBuilder.writePdfFile(
      paths['15_stress_document']!,
      PdfCorpusBuilder.buildPdf(pages: stressPages),
    );

    return paths;
  }
}
