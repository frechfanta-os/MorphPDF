import '../../../core/ocr/ocr_models.dart';
import '../../../shared/models/text_block.dart';
import '../domain/ocr_engine.dart';

class MlKitEngineMock implements OcrEngine {
  @override
  String get engineName => 'Google ML Kit (Local Android)';

  @override
  List<String> get supportedLanguages => ['en', 'fr', 'es', 'de', 'it', 'pt'];

  @override
  Future<List<TextBlock>> recognizeText(String imagePath, {String lang = 'en'}) async {
    return [
      TextBlock(
        id: 'mlkit-mock-1',
        pageNumber: 1,
        text: 'Exemple de texte extrait via ML Kit',
        x: 10,
        y: 20,
        width: 300,
        height: 40,
        confidence: 0.98,
        language: lang,
      ),
    ];
  }

  @override
  Future<OcrPageResult> recognizePage({
    required String imagePath,
    required int pageIndex,
    OcrMode mode = OcrMode.auto,
    int maxDimension = 4096,
    OcrCancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled == true) {
      throw const OcrCancelledException();
    }

    return OcrPageResult(
      pageIndex: pageIndex,
      imageWidth: 800,
      imageHeight: 1200,
      processingTimeMs: 45,
      engineUsed: engineName,
      isRightToLeft: false,
      blocks: [
        OcrBlock(
          id: 'mlkit_block_$pageIndex',
          text: 'Exemple de texte extrait via ML Kit',
          confidence: 0.98,
          language: 'fr',
          boundingBox: const OcrBoundingBox(left: 20, top: 40, width: 300, height: 40),
          lines: [
            OcrLine(
              text: 'Exemple de texte extrait via ML Kit',
              confidence: 0.98,
              boundingBox: const OcrBoundingBox(left: 20, top: 40, width: 300, height: 40),
              words: [
                const OcrWord(
                  text: 'Exemple',
                  confidence: 0.99,
                  boundingBox: OcrBoundingBox(left: 20, top: 40, width: 70, height: 40),
                ),
                const OcrWord(
                  text: 'ML Kit',
                  confidence: 0.98,
                  boundingBox: OcrBoundingBox(left: 100, top: 40, width: 80, height: 40),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class PaddleOcrEngineMock implements OcrEngine {
  @override
  String get engineName => 'PaddleOCR (Multilingue & Arabe)';

  @override
  List<String> get supportedLanguages => ['ar', 'ch', 'ja', 'ko', 'en', 'fr'];

  @override
  Future<List<TextBlock>> recognizeText(String imagePath, {String lang = 'en'}) async {
    return [
      TextBlock(
        id: 'paddle-mock-1',
        pageNumber: 1,
        text: 'نص تجريبي مستخرج بواسطة PaddleOCR',
        x: 20,
        y: 30,
        width: 250,
        height: 35,
        confidence: 0.95,
        language: lang,
      ),
    ];
  }

  @override
  Future<OcrPageResult> recognizePage({
    required String imagePath,
    required int pageIndex,
    OcrMode mode = OcrMode.auto,
    int maxDimension = 4096,
    OcrCancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled == true) {
      throw const OcrCancelledException();
    }

    final isArabic = mode == OcrMode.arabic || (mode == OcrMode.auto && imagePath.contains('arabic'));

    return OcrPageResult(
      pageIndex: pageIndex,
      imageWidth: 1000,
      imageHeight: 1400,
      processingTimeMs: 120,
      engineUsed: engineName,
      isRightToLeft: isArabic,
      blocks: [
        OcrBlock(
          id: 'paddle_block_$pageIndex',
          text: isArabic
              ? 'الجمهورية الجزائرية الديمقراطية'
              : 'MorphPDF Document Numérique',
          confidence: 0.97,
          language: isArabic ? 'ar' : 'fr',
          boundingBox: const OcrBoundingBox(left: 50, top: 80, width: 400, height: 50),
          lines: [
            OcrLine(
              text: isArabic
                  ? 'الجمهورية الجزائرية الديمقراطية'
                  : 'MorphPDF Document Numérique',
              confidence: 0.97,
              boundingBox: const OcrBoundingBox(left: 50, top: 80, width: 400, height: 50),
              words: isArabic
                  ? [
                      const OcrWord(
                        text: 'الجمهورية',
                        confidence: 0.97,
                        boundingBox: OcrBoundingBox(left: 50, top: 80, width: 120, height: 50),
                      ),
                      const OcrWord(
                        text: 'الجزائرية',
                        confidence: 0.98,
                        boundingBox: OcrBoundingBox(left: 180, top: 80, width: 120, height: 50),
                      ),
                    ]
                  : [
                      const OcrWord(
                        text: 'MorphPDF',
                        confidence: 0.99,
                        boundingBox: OcrBoundingBox(left: 50, top: 80, width: 120, height: 50),
                      ),
                    ],
            ),
          ],
        ),
      ],
    );
  }
}

