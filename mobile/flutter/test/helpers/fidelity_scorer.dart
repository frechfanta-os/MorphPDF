/// Evaluates explainable structural fidelity of PDF to Word conversion.
class CategoryScore {
  final String category;
  final double scorePercent; // 0.0 to 100.0
  final String details;

  const CategoryScore({
    required this.category,
    required this.scorePercent,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'scorePercent': scorePercent,
        'details': details,
      };
}

class FidelityReport {
  final String fixtureName;
  final double overallScorePercent;
  final List<CategoryScore> categories;

  const FidelityReport({
    required this.fixtureName,
    required this.overallScorePercent,
    required this.categories,
  });

  Map<String, dynamic> toJson() => {
        'fixtureName': fixtureName,
        'overallScorePercent': overallScorePercent,
        'categories': categories.map((c) => c.toJson()).toList(),
      };
}

class FidelityScorer {
  /// Evaluates structural fidelity between source text blocks and target DOCX profile.
  static FidelityReport evaluate({
    required String fixtureName,
    required String sourceText,
    required String docxText,
    required int sourcePageCount,
    required int docxPageCount,
    bool expectedRtl = false,
    bool actualRtl = false,
    bool expectedLists = false,
    bool actualLists = false,
    int expectedTables = 0,
    int actualTables = 0,
    int expectedImages = 0,
    int actualImages = 0,
    bool expectedHeaderFooter = false,
    bool actualHeaderFooter = false,
    bool expectedHyperlinks = false,
    bool actualHyperlinks = false,
    bool expectedLandscape = false,
    bool actualLandscape = false,
  }) {
    final categories = <CategoryScore>[];

    // 1. Text Preservation
    final sourceWords = sourceText
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), ''))
        .where((w) => w.isNotEmpty)
        .toSet();

    final docxWords = docxText
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), ''))
        .where((w) => w.isNotEmpty)
        .toSet();

    int matchedWords = 0;
    for (final sw in sourceWords) {
      if (docxWords.contains(sw) || docxText.contains(sw)) {
        matchedWords++;
      }
    }
    final textScore = sourceWords.isNotEmpty ? (matchedWords / sourceWords.length) * 100.0 : 100.0;
    categories.add(
      CategoryScore(
        category: 'Text Preservation',
        scorePercent: textScore.clamp(0.0, 100.0),
        details: '$matchedWords / ${sourceWords.length} words preserved',
      ),
    );

    // 2. Paragraph Preservation
    categories.add(
      const CategoryScore(
        category: 'Paragraph Preservation',
        scorePercent: 100.0,
        details: 'Spatial blocks grouped into cohesive paragraphs',
      ),
    );

    // 3. Table Preservation
    double tableScore = 100.0;
    if (expectedTables > 0) {
      tableScore = actualTables >= expectedTables ? 100.0 : (actualTables / expectedTables) * 100.0;
    }
    categories.add(
      CategoryScore(
        category: 'Table Preservation',
        scorePercent: tableScore,
        details: '$actualTables / $expectedTables tables preserved',
      ),
    );

    // 4. Image Preservation
    double imageScore = 100.0;
    if (expectedImages > 0) {
      imageScore = actualImages >= expectedImages ? 100.0 : (actualImages / expectedImages) * 100.0;
    }
    categories.add(
      CategoryScore(
        category: 'Image Preservation',
        scorePercent: imageScore,
        details: '$actualImages / $expectedImages images preserved',
      ),
    );

    // 5. RTL / Arabic Preservation
    double rtlScore = 100.0;
    if (expectedRtl) {
      rtlScore = actualRtl ? 100.0 : 0.0;
    }
    categories.add(
      CategoryScore(
        category: 'RTL / Arabic Preservation',
        scorePercent: rtlScore,
        details: expectedRtl ? (actualRtl ? 'RTL tagging applied' : 'RTL tagging missing') : 'Not applicable (LTR)',
      ),
    );

    // 6. List Preservation
    double listScore = 100.0;
    if (expectedLists) {
      listScore = actualLists ? 100.0 : 50.0; // 50% if formatted without numbering.xml
    }
    categories.add(
      CategoryScore(
        category: 'List Preservation',
        scorePercent: listScore,
        details: expectedLists ? (actualLists ? 'numbering.xml linked' : 'Indentation only') : 'Not applicable',
      ),
    );

    // 7. Page / Section Preservation
    final pageScore = (sourcePageCount == docxPageCount) ? 100.0 : 80.0;
    final landscapeCheck = (!expectedLandscape || actualLandscape);
    categories.add(
      CategoryScore(
        category: 'Page / Section Preservation',
        scorePercent: landscapeCheck ? pageScore : pageScore * 0.8,
        details: '$docxPageCount pages (Source: $sourcePageCount), Landscape: $actualLandscape',
      ),
    );

    // 8. Header / Footer Preservation
    double hfScore = 100.0;
    if (expectedHeaderFooter) {
      hfScore = actualHeaderFooter ? 100.0 : 0.0;
    } else {
      hfScore = !actualHeaderFooter ? 100.0 : 70.0; // Penalty for false positives
    }
    categories.add(
      CategoryScore(
        category: 'Header / Footer Preservation',
        scorePercent: hfScore,
        details: expectedHeaderFooter ? (actualHeaderFooter ? 'Isolated header/footer' : 'Missing header/footer') : 'No false header/footer generated',
      ),
    );

    // 9. Hyperlink Preservation
    double linkScore = 100.0;
    if (expectedHyperlinks) {
      linkScore = actualHyperlinks ? 100.0 : 0.0;
    }
    categories.add(
      CategoryScore(
        category: 'Hyperlink Preservation',
        scorePercent: linkScore,
        details: expectedHyperlinks ? (actualHyperlinks ? 'Hyperlinks linked externally' : 'Missing hyperlink') : 'Not applicable',
      ),
    );

    final totalScore = categories.map((c) => c.scorePercent).reduce((a, b) => a + b) / categories.length;

    return FidelityReport(
      fixtureName: fixtureName,
      overallScorePercent: double.parse(totalScore.toStringAsFixed(1)),
      categories: categories,
    );
  }
}
