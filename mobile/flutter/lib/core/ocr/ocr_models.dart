import 'package:flutter/foundation.dart';

/// Operating OCR mode.
enum OcrMode {
  auto,
  arabic,
  latin,
}

/// Precise bounding box holding rectangular extents and optional quadrilateral polygon coordinates.
@immutable
class OcrBoundingBox {
  final double left;
  final double top;
  final double width;
  final double height;
  final List<List<double>>? polygonPoints; // [[x1, y1], [x2, y2], [x3, y3], [x4, y4]]

  const OcrBoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    this.polygonPoints,
  });

  double get right => left + width;
  double get bottom => top + height;

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'width': width,
        'height': height,
        if (polygonPoints != null) 'polygonPoints': polygonPoints,
      };

  factory OcrBoundingBox.fromJson(Map<String, dynamic> json) {
    List<List<double>>? polygon;
    if (json['polygonPoints'] is List) {
      polygon = (json['polygonPoints'] as List)
          .map((p) => (p as List).map((coord) => (coord as num).toDouble()).toList())
          .toList();
    }
    return OcrBoundingBox(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      polygonPoints: polygon,
    );
  }
}

/// Word-level OCR item.
@immutable
class OcrWord {
  final String text;
  final double confidence;
  final OcrBoundingBox boundingBox;

  const OcrWord({
    required this.text,
    required this.confidence,
    required this.boundingBox,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        'boundingBox': boundingBox.toJson(),
      };

  factory OcrWord.fromJson(Map<String, dynamic> json) => OcrWord(
        text: json['text'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        boundingBox: OcrBoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>),
      );
}

/// Line-level OCR segment.
@immutable
class OcrLine {
  final String text;
  final double confidence;
  final OcrBoundingBox boundingBox;
  final List<OcrWord> words;

  const OcrLine({
    required this.text,
    required this.confidence,
    required this.boundingBox,
    this.words = const [],
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'confidence': confidence,
        'boundingBox': boundingBox.toJson(),
        'words': words.map((w) => w.toJson()).toList(),
      };

  factory OcrLine.fromJson(Map<String, dynamic> json) => OcrLine(
        text: json['text'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        boundingBox: OcrBoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>),
        words: (json['words'] as List<dynamic>?)
                ?.map((w) => OcrWord.fromJson(w as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Block-level structured text entity.
@immutable
class OcrBlock {
  final String id;
  final String text;
  final double confidence;
  final OcrBoundingBox boundingBox;
  final String language;
  final List<OcrLine> lines;

  const OcrBlock({
    required this.id,
    required this.text,
    required this.confidence,
    required this.boundingBox,
    required this.language,
    this.lines = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'confidence': confidence,
        'boundingBox': boundingBox.toJson(),
        'language': language,
        'lines': lines.map((l) => l.toJson()).toList(),
      };

  factory OcrBlock.fromJson(Map<String, dynamic> json) => OcrBlock(
        id: json['id'] as String,
        text: json['text'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        boundingBox: OcrBoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>),
        language: json['language'] as String? ?? 'auto',
        lines: (json['lines'] as List<dynamic>?)
                ?.map((l) => OcrLine.fromJson(l as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

/// Complete geometric and textual OCR result for a processed document page.
@immutable
class OcrPageResult {
  final int pageIndex;
  final double imageWidth;
  final double imageHeight;
  final List<OcrBlock> blocks;
  final int processingTimeMs;
  final String engineUsed;
  final bool isRightToLeft;

  const OcrPageResult({
    required this.pageIndex,
    required this.imageWidth,
    required this.imageHeight,
    required this.blocks,
    required this.processingTimeMs,
    required this.engineUsed,
    this.isRightToLeft = false,
  });

  String get fullText => blocks.map((b) => b.text).join('\n\n');

  Map<String, dynamic> toJson() => {
        'pageIndex': pageIndex,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'processingTimeMs': processingTimeMs,
        'engineUsed': engineUsed,
        'isRightToLeft': isRightToLeft,
      };

  factory OcrPageResult.fromJson(Map<String, dynamic> json) => OcrPageResult(
        pageIndex: (json['pageIndex'] as num).toInt(),
        imageWidth: (json['imageWidth'] as num).toDouble(),
        imageHeight: (json['imageHeight'] as num).toDouble(),
        blocks: (json['blocks'] as List<dynamic>?)
                ?.map((b) => OcrBlock.fromJson(b as Map<String, dynamic>))
                .toList() ??
            const [],
        processingTimeMs: (json['processingTimeMs'] as num?)?.toInt() ?? 0,
        engineUsed: json['engineUsed'] as String? ?? 'PaddleOCR',
        isRightToLeft: json['isRightToLeft'] as bool? ?? false,
      );
}

/// Interactive progress reporting during sequential page OCR processing.
@immutable
class OcrProgress {
  final int currentPage;
  final int totalPages;
  final double fraction;
  final String statusMessage;

  const OcrProgress({
    required this.currentPage,
    required this.totalPages,
    required this.fraction,
    required this.statusMessage,
  });

  int get percentage => (fraction * 100).clamp(0, 100).round();
}

/// Token enabling user cancellation at safe boundary points.
class OcrCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}

/// Root exception for all typed OCR errors.
abstract class OcrException implements Exception {
  final String message;
  final String? details;

  const OcrException(this.message, [this.details]);

  @override
  String toString() => details != null ? 'OcrException: $message ($details)' : 'OcrException: $message';
}

class OcrModelNotFoundException extends OcrException {
  const OcrModelNotFoundException(super.message, [super.details]);
}

class OcrInferenceFailedException extends OcrException {
  const OcrInferenceFailedException(super.message, [super.details]);
}

class OcrCancelledException extends OcrException {
  const OcrCancelledException() : super('Le traitement OCR a été annulé par l\'utilisateur.');
}

class OcrImageTooLargeException extends OcrException {
  final int width;
  final int height;
  final int maxAllowed;

  const OcrImageTooLargeException({
    required this.width,
    required this.height,
    this.maxAllowed = 4096,
  }) : super(
          'Dimensions de l\'image trop volumineuses : ${width}x$height (limite maximale : ${maxAllowed}x$maxAllowed px)',
        );
}

class OcrUnsupportedLanguageException extends OcrException {
  const OcrUnsupportedLanguageException(super.message, [super.details]);
}
