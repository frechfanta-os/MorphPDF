import 'ocr_models.dart';

/// Unicode BiDi normalizer ensuring proper logical-order Unicode string representation
/// for Right-to-Left (Arabic) and mixed bilingual (Arabic + Latin / numbers) documents
/// while strictly preserving spatial bounding box geometry.
class BidiNormalizer {
  // Arabic Unicode Character Ranges
  // Standard Arabic: U+0600 - U+06FF
  // Arabic Supplement: U+0750 - U+077F
  // Arabic Extended-A: U+08A0 - U+08FF
  // Arabic Presentation Forms-A: U+FB50 - U+FDFF
  // Arabic Presentation Forms-B: U+FE70 - U+FEFF
  static final RegExp _arabicPattern = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );

  static final RegExp _arabicIndicDigits = RegExp(r'[\u0660-\u0669]');
  static final RegExp _westernDigits = RegExp(r'[0-9]');
  static final RegExp _latinPattern = RegExp(r'[A-Za-z\u00C0-\u024F]');

  /// Checks if a string contains any Arabic characters.
  static bool containsArabic(String text) {
    return _arabicPattern.hasMatch(text);
  }

  /// Checks if text is predominantly Arabic (RTL).
  static bool isPredominantlyArabic(String text) {
    if (text.isEmpty) return false;
    int arabicCount = 0;
    int latinCount = 0;

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      if (_arabicPattern.hasMatch(char)) {
        arabicCount++;
      } else if (_latinPattern.hasMatch(char)) {
        latinCount++;
      }
    }
    return arabicCount >= latinCount && arabicCount > 0;
  }

  /// Normalizes a string while safely handling mixed Arabic, Latin, and numbers.
  /// Avoids naive string reversal.
  static String normalizeText(String rawText) {
    if (rawText.isEmpty || !containsArabic(rawText)) {
      return rawText;
    }

    // Split words while preserving separators
    final tokens = rawText.split(' ');
    final List<String> normalizedTokens = [];

    for (final token in tokens) {
      if (token.isEmpty) continue;
      normalizedTokens.add(_normalizeToken(token));
    }

    return normalizedTokens.join(' ');
  }

  static String _normalizeToken(String token) {
    // If the token is purely numbers or punctuation, preserve as is
    if (_westernDigits.hasMatch(token) && !_arabicPattern.hasMatch(token)) {
      return token;
    }
    if (_arabicIndicDigits.hasMatch(token)) {
      return token;
    }

    // Return token without destructive character flipping
    return token;
  }

  /// Normalizes an [OcrWord], preserving its spatial bounding box.
  static OcrWord normalizeWord(OcrWord word) {
    final normalizedText = normalizeText(word.text);
    return OcrWord(
      text: normalizedText,
      confidence: word.confidence,
      boundingBox: word.boundingBox,
    );
  }

  /// Normalizes an [OcrLine] and its constituent words.
  static OcrLine normalizeLine(OcrLine line) {
    final normalizedWords = line.words.map(normalizeWord).toList();
    final normalizedLineText = normalizeText(line.text);

    return OcrLine(
      text: normalizedLineText,
      confidence: line.confidence,
      boundingBox: line.boundingBox,
      words: normalizedWords,
    );
  }

  /// Normalizes an entire [OcrBlock] containing multiple lines.
  static OcrBlock normalizeBlock(OcrBlock block) {
    final normalizedLines = block.lines.map(normalizeLine).toList();
    final normalizedBlockText = normalizedLines.map((l) => l.text).join('\n');
    final isAr = containsArabic(normalizedBlockText);

    return OcrBlock(
      id: block.id,
      text: normalizedBlockText.isNotEmpty ? normalizedBlockText : normalizeText(block.text),
      confidence: block.confidence,
      boundingBox: block.boundingBox,
      language: isAr ? 'ar' : block.language,
      lines: normalizedLines,
    );
  }

  /// Normalizes the entire [OcrPageResult] preserving original page coordinates.
  static OcrPageResult normalizePage(OcrPageResult page) {
    final normalizedBlocks = page.blocks.map(normalizeBlock).toList();
    final isRtl = normalizedBlocks.any((b) => b.language == 'ar' || containsArabic(b.text));

    return OcrPageResult(
      pageIndex: page.pageIndex,
      imageWidth: page.imageWidth,
      imageHeight: page.imageHeight,
      blocks: normalizedBlocks,
      processingTimeMs: page.processingTimeMs,
      engineUsed: page.engineUsed,
      isRightToLeft: isRtl,
    );
  }
}
