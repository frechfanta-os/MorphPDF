class TextBlock {
  final String id;
  final int pageNumber;
  final String text;
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
  final String language;

  const TextBlock({
    required this.id,
    required this.pageNumber,
    required this.text,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.confidence = 1.0,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageNumber': pageNumber,
    'text': text,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'confidence': confidence,
    'language': language,
  };

  factory TextBlock.fromJson(Map<String, dynamic> json) {
    return TextBlock(
      id: json['id'] as String? ?? '',
      pageNumber: json['pageNumber'] as int? ?? 1,
      text: json['text'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      language: json['language'] as String? ?? 'en',
    );
  }
}
