import 'dart:typed_data';
import 'package:morphpdf/core/docx/layout/docx_elements.dart';
import 'package:morphpdf/shared/models/text_block.dart';

/// 15 representative synthetic document fixtures for Phase 5.2 hardening and regression testing.
class SyntheticDocuments {
  /// Minimal valid 1x1 transparent PNG bytes.
  static final Uint8List samplePngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
    0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  // Standard A4 dimensions
  static const double a4Width = 595.28;
  static const double a4Height = 841.89;

  // 01_simple_french: Standard French document (title, subtitle, paragraphs, bold, italic, underline, strike)
  static DocxSection fixture01SimpleFrench() {
    return const DocxSection(
      elements: [
        DocxParagraph(
          runs: [
            DocxRun(
              text: "Rapport d'activité annuel 2026",
              isBold: true,
              fontSizePt: 22.0,
            ),
          ],
          styleId: 'Heading1',
          alignment: DocxAlignment.center,
        ),
        DocxParagraph(
          runs: [
            DocxRun(
              text: 'Direction Générale - MorphPDF',
              isItalic: true,
              fontSizePt: 14.0,
              colorHex: '2E74B5',
            ),
          ],
          styleId: 'Heading2',
        ),
        DocxParagraph(
          runs: [
            DocxRun(text: 'Le présent document constitue un rapport '),
            DocxRun(text: 'officiel et confidentiel', isBold: true),
            DocxRun(text: ' avec une analyse '),
            DocxRun(text: 'stratégique', isItalic: true),
            DocxRun(text: ' et une mention '),
            DocxRun(text: 'prioritaire', isUnderline: true),
            DocxRun(text: ' ainsi qu’un élément '),
            DocxRun(text: 'obsolète', isStrike: true),
            DocxRun(text: ' pour la gouvernance.'),
          ],
        ),
      ],
    );
  }

  // 02_arabic_rtl: Purely Arabic document (title, paragraphs, right alignment, Arabic font)
  static DocxSection fixture02ArabicRtl() {
    return const DocxSection(
      elements: [
        DocxParagraph(
          runs: [
            DocxRun(
              text: 'تقرير الأداء المالي السنوي',
              isBold: true,
              fontSizePt: 20.0,
              isRtl: true,
              csFontFamily: 'Traditional Arabic',
            ),
          ],
          styleId: 'Heading1',
          alignment: DocxAlignment.right,
          isRtl: true,
        ),
        DocxParagraph(
          runs: [
            DocxRun(
              text: 'حققت المنظومة الرقمية نتائج استثنائية خلال الربع الأخير مع التزام كامل بالسيادة الرقمية وتشفير المستندات محليا بدون خوادم سحابية.',
              isRtl: true,
              csFontFamily: 'Traditional Arabic',
            ),
          ],
          alignment: DocxAlignment.right,
          isRtl: true,
        ),
      ],
    );
  }

  // 03_mixed_bidi: Mixed bilingual French-Arabic document with alternating runs
  static DocxSection fixture03MixedBidi() {
    return const DocxSection(
      elements: [
        DocxParagraph(
          runs: [
            DocxRun(text: 'Rapport bilingue: '),
            DocxRun(
              text: 'مشروع مورف الرقمي',
              isRtl: true,
              isBold: true,
              csFontFamily: 'Traditional Arabic',
            ),
            DocxRun(text: ' pour la gestion souveraine des documents.'),
          ],
        ),
        DocxParagraph(
          runs: [
            DocxRun(
              text: 'تم إطلاق هذا الإصدار بالتعاون مع فريق ',
              isRtl: true,
              csFontFamily: 'Traditional Arabic',
            ),
            DocxRun(text: 'GHD Interactive Studio', isBold: true),
            DocxRun(
              text: ' لدعم معالجة المستندات المحلية.',
              isRtl: true,
              csFontFamily: 'Traditional Arabic',
            ),
          ],
          alignment: DocxAlignment.right,
          isRtl: true,
        ),
      ],
    );
  }

  // 04_arabic_numbers_dates: Arabic document with numbers (123, ٤٥٦), dates, and URL
  static DocxSection fixture04ArabicNumbersDates() {
    return const DocxSection(
      elements: [
        DocxParagraph(
          runs: [
            DocxRun(
              text: 'المرجع رقم 123 والمعاملة رقم ٤٥٦ بتاريخ 1446 هـ الموافق 2026/10/04 للمعاينة زوروا موقعنا: ',
              isRtl: true,
              csFontFamily: 'Traditional Arabic',
            ),
            DocxRun(
              text: 'https://morphpdf.example.com',
              hyperlinkUrl: 'https://morphpdf.example.com',
              colorHex: '0563C1',
              isUnderline: true,
            ),
          ],
          alignment: DocxAlignment.right,
          isRtl: true,
        ),
      ],
    );
  }

  // 05_two_columns: 2-column spatial text blocks
  static List<TextBlock> fixture05TwoColumnsBlocks() {
    return const [
      // Left column (X: 50..250)
      TextBlock(id: 'col_l1', pageNumber: 1, text: 'Colonne Gauche - Ligne 1', x: 50, y: 700, width: 180, height: 12),
      TextBlock(id: 'col_l2', pageNumber: 1, text: 'Colonne Gauche - Ligne 2', x: 50, y: 660, width: 180, height: 12),
      // Right column (X: 350..550, Gutter: 100pt in middle)
      TextBlock(id: 'col_r1', pageNumber: 1, text: 'Colonne Droite - Ligne 1', x: 350, y: 700, width: 180, height: 12),
      TextBlock(id: 'col_r2', pageNumber: 1, text: 'Colonne Droite - Ligne 2', x: 350, y: 660, width: 180, height: 12),
    ];
  }

  // 06_headings_hierarchy: Heading 1, 2, 3 and body text
  static DocxSection fixture06HeadingsHierarchy() {
    return const DocxSection(
      elements: [
        DocxParagraph(
          runs: [DocxRun(text: '1. Architecture Générale', isBold: true, fontSizePt: 18.0)],
          styleId: 'Heading1',
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Introduction au système documentaire et aux modules principaux.')],
        ),
        DocxParagraph(
          runs: [DocxRun(text: '1.1 Moteur Local OOXML', isBold: true, fontSizePt: 14.0)],
          styleId: 'Heading2',
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Détail de la génération native sans dépendances externes.')],
        ),
        DocxParagraph(
          runs: [DocxRun(text: '1.1.1 Sérialisation ECMA-376', isBold: true, fontSizePt: 12.5)],
          styleId: 'Heading3',
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Assemblage des flux XML et de l’archive OPC.')],
        ),
      ],
    );
  }

  // 07_bullet_list: Bullet list items
  static DocxSection fixture07BulletList() {
    return const DocxSection(
      elements: [
        DocxParagraph(
          runs: [DocxRun(text: 'Liste des fonctionnalités souveraines :')],
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Extraction native PDFium sans perte')],
          isList: true,
          listNumId: 1,
          listLevel: 0,
          indentTwips: 720,
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Normalisation BiDi pour l’arabe')],
          isList: true,
          listNumId: 1,
          listLevel: 0,
          indentTwips: 720,
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Compression ZIP conforme Open Packaging Conventions')],
          isList: true,
          listNumId: 1,
          listLevel: 0,
          indentTwips: 720,
        ),
      ],
    );
  }

  // 08_numbered_list: Ordered list items
  static DocxSection fixture08NumberedList() {
    return const DocxSection(
      elements: [
        DocxParagraph(
          runs: [DocxRun(text: 'Étapes du processus de conversion :')],
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Chargement du document PDF')],
          isList: true,
          listNumId: 2,
          listLevel: 0,
          indentTwips: 720,
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Reconstruction du layout spatial')],
          isList: true,
          listNumId: 2,
          listLevel: 0,
          indentTwips: 720,
        ),
        DocxParagraph(
          runs: [DocxRun(text: 'Génération du package .docx final')],
          isList: true,
          listNumId: 2,
          listLevel: 0,
          indentTwips: 720,
        ),
      ],
    );
  }

  // 09_simple_table: 3x3 table with headers
  static DocxSection fixture09SimpleTable() {
    return const DocxSection(
      elements: [
        DocxTable(
          gridColTwips: [2500, 2500, 2500],
          hasBorders: true,
          rows: [
            DocxTableRow(
              isHeader: true,
              cells: [
                DocxTableCell(
                  widthTwips: 2500,
                  shadingColorHex: 'E0E0E0',
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Composant', isBold: true)])],
                ),
                DocxTableCell(
                  widthTwips: 2500,
                  shadingColorHex: 'E0E0E0',
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Version', isBold: true)])],
                ),
                DocxTableCell(
                  widthTwips: 2500,
                  shadingColorHex: 'E0E0E0',
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Statut', isBold: true)])],
                ),
              ],
            ),
            DocxTableRow(
              cells: [
                DocxTableCell(
                  widthTwips: 2500,
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'PDFium')])],
                ),
                DocxTableCell(
                  widthTwips: 2500,
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'v122')])],
                ),
                DocxTableCell(
                  widthTwips: 2500,
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Opérationnel')])],
                ),
              ],
            ),
            DocxTableRow(
              cells: [
                DocxTableCell(
                  widthTwips: 2500,
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'PaddleOCR')])],
                ),
                DocxTableCell(
                  widthTwips: 2500,
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'v4 ONNX')])],
                ),
                DocxTableCell(
                  widthTwips: 2500,
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Prêt')])],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 10_table_empty_cells: Table containing empty cells (verifying valid empty <w:p/> in <w:tc>)
  static DocxSection fixture10TableEmptyCells() {
    return const DocxSection(
      elements: [
        DocxTable(
          gridColTwips: [3500, 3500],
          hasBorders: true,
          rows: [
            DocxTableRow(
              cells: [
                DocxTableCell(
                  widthTwips: 3500,
                  paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Cellule Remplie')])],
                ),
                DocxTableCell(
                  widthTwips: 3500,
                  paragraphs: [], // Empty cell
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 11_table_rtl: Arabic table with RTL visual and right alignment
  static DocxSection fixture11TableRtl() {
    return const DocxSection(
      elements: [
        DocxTable(
          gridColTwips: [3500, 3500],
          isRtl: true,
          hasBorders: true,
          rows: [
            DocxTableRow(
              isHeader: true,
              cells: [
                DocxTableCell(
                  widthTwips: 3500,
                  paragraphs: [
                    DocxParagraph(
                      runs: [
                        DocxRun(
                          text: 'البند',
                          isBold: true,
                          isRtl: true,
                          csFontFamily: 'Traditional Arabic',
                        ),
                      ],
                      alignment: DocxAlignment.right,
                      isRtl: true,
                    ),
                  ],
                ),
                DocxTableCell(
                  widthTwips: 3500,
                  paragraphs: [
                    DocxParagraph(
                      runs: [
                        DocxRun(
                          text: 'القيمة',
                          isBold: true,
                          isRtl: true,
                          csFontFamily: 'Traditional Arabic',
                        ),
                      ],
                      alignment: DocxAlignment.right,
                      isRtl: true,
                    ),
                  ],
                ),
              ],
            ),
            DocxTableRow(
              cells: [
                DocxTableCell(
                  widthTwips: 3500,
                  paragraphs: [
                    DocxParagraph(
                      runs: [
                        DocxRun(
                          text: 'الإيرادات التشغيلية',
                          isRtl: true,
                          csFontFamily: 'Traditional Arabic',
                        ),
                      ],
                      alignment: DocxAlignment.right,
                      isRtl: true,
                    ),
                  ],
                ),
                DocxTableCell(
                  widthTwips: 3500,
                  paragraphs: [
                    DocxParagraph(
                      runs: [
                        DocxRun(
                          text: '100,000 ريال',
                          isRtl: true,
                          csFontFamily: 'Traditional Arabic',
                        ),
                      ],
                      alignment: DocxAlignment.right,
                      isRtl: true,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 12_image_document: Document containing an embedded raster image
  static DocxSection fixture12ImageDocument() {
    return DocxSection(
      elements: [
        const DocxParagraph(
          runs: [DocxRun(text: 'Document avec Image Intégrée', isBold: true, fontSizePt: 16.0)],
        ),
        DocxImage(
          bytes: samplePngBytes,
          extension: 'png',
          widthPt: 200,
          heightPt: 150,
          altText: 'Logo MorphPDF Transparent',
        ),
      ],
    );
  }

  // 13_header_footer: Multi-page document with header and footer
  static List<DocxSection> fixture13HeaderFooter() {
    const header = DocxHeader(
      paragraphs: [
        DocxParagraph(
          runs: [
            DocxRun(
              text: 'MorphPDF Enterprise Edition - Rapport Confidentiel',
              fontSizePt: 9.0,
              colorHex: '7F7F7F',
            ),
          ],
          alignment: DocxAlignment.center,
          styleId: 'Header',
        ),
      ],
    );

    const footer = DocxFooter(
      paragraphs: [
        DocxParagraph(
          runs: [
            DocxRun(
              text: 'Page 1 sur 2 - Tous droits réservés',
              fontSizePt: 9.0,
              colorHex: '7F7F7F',
            ),
          ],
          alignment: DocxAlignment.center,
          styleId: 'Footer',
        ),
      ],
    );

    return const [
      DocxSection(
        header: header,
        footer: footer,
        elements: [
          DocxParagraph(runs: [DocxRun(text: 'Page 1 - Contenu principal.')]),
        ],
      ),
      DocxSection(
        header: header,
        footer: footer,
        elements: [
          DocxParagraph(runs: [DocxRun(text: 'Page 2 - Suite du rapport.')]),
        ],
      ),
    ];
  }

  // 14_landscape_multipage: Multi-page document in landscape format
  static List<DocxSection> fixture14LandscapeMultipage() {
    return const [
      DocxSection(
        pageWidthPt: a4Height, // 841.89 pt
        pageHeightPt: a4Width, // 595.28 pt
        isLandscape: true,
        elements: [
          DocxParagraph(
            runs: [DocxRun(text: 'Tableau de bord paysage - Page 1', isBold: true, fontSizePt: 18.0)],
          ),
        ],
      ),
      DocxSection(
        pageWidthPt: a4Height,
        pageHeightPt: a4Width,
        isLandscape: true,
        elements: [
          DocxParagraph(
            runs: [DocxRun(text: 'Graphiques analytiques - Page 2', isBold: true, fontSizePt: 18.0)],
          ),
        ],
      ),
    ];
  }

  // 15_mixed_document: Complex document combining headings, columns, table, image, Arabic RTL, and lists
  static List<DocxSection> fixture15MixedDocument() {
    const header = DocxHeader(
      paragraphs: [
        DocxParagraph(
          runs: [DocxRun(text: 'MorphPDF Sovereign Suite - Dossier Complet', colorHex: '595959')],
          alignment: DocxAlignment.center,
          styleId: 'Header',
        ),
      ],
    );

    const footer = DocxFooter(
      paragraphs: [
        DocxParagraph(
          runs: [DocxRun(text: 'Confidentiel & Souverain', colorHex: '7F7F7F')],
          alignment: DocxAlignment.center,
          styleId: 'Footer',
        ),
      ],
    );

    return [
      DocxSection(
        header: header,
        footer: footer,
        elements: [
          const DocxParagraph(
            runs: [
              DocxRun(text: 'Dossier Technique & Stratégique', isBold: true, fontSizePt: 22.0),
            ],
            styleId: 'Heading1',
            alignment: DocxAlignment.center,
          ),
          const DocxParagraph(
            runs: [
              DocxRun(text: '1. Module Multilingue et BiDi', isBold: true, fontSizePt: 16.0),
            ],
            styleId: 'Heading2',
          ),
          const DocxParagraph(
            runs: [
              DocxRun(
                text: 'تم تصميم النظام ليعمل بشكل مستقل بالكامل مع دعم الخطوط العربية: ',
                isRtl: true,
                csFontFamily: 'Traditional Arabic',
              ),
              DocxRun(
                text: 'Traditional Arabic',
                isBold: true,
              ),
            ],
            alignment: DocxAlignment.right,
            isRtl: true,
          ),
          const DocxParagraph(
            runs: [
              DocxRun(text: '2. Liste des composants vérifiés', isBold: true, fontSizePt: 14.0),
            ],
            styleId: 'Heading2',
          ),
          const DocxParagraph(
            runs: [DocxRun(text: 'PDFium FFI Engine')],
            isList: true,
            listNumId: 1,
            listLevel: 0,
            indentTwips: 720,
          ),
          const DocxParagraph(
            runs: [DocxRun(text: 'PaddleOCR ONNX Runtime')],
            isList: true,
            listNumId: 1,
            listLevel: 0,
            indentTwips: 720,
          ),
          const DocxParagraph(
            runs: [DocxRun(text: 'Sovereign OOXML Builder')],
            isList: true,
            listNumId: 1,
            listLevel: 0,
            indentTwips: 720,
          ),
          const DocxTable(
            gridColTwips: [3600, 3600],
            hasBorders: true,
            rows: [
              DocxTableRow(
                isHeader: true,
                cells: [
                  DocxTableCell(
                    widthTwips: 3600,
                    shadingColorHex: 'F2F2F2',
                    paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Critère', isBold: true)])],
                  ),
                  DocxTableCell(
                    widthTwips: 3600,
                    shadingColorHex: 'F2F2F2',
                    paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Validation', isBold: true)])],
                  ),
                ],
              ),
              DocxTableRow(
                cells: [
                  DocxTableCell(
                    widthTwips: 3600,
                    paragraphs: [DocxParagraph(runs: [DocxRun(text: 'Sécurité Hors-Ligne')])],
                  ),
                  DocxTableCell(
                    widthTwips: 3600,
                    paragraphs: [DocxParagraph(runs: [DocxRun(text: '100% Local')])],
                  ),
                ],
              ),
            ],
          ),
          DocxImage(
            bytes: samplePngBytes,
            extension: 'png',
            widthPt: 180,
            heightPt: 120,
            altText: 'Logo Sceau MorphPDF',
          ),
        ],
      ),
    ];
  }
}
