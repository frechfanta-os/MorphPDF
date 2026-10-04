class PageModel {
  final int pageNumber;
  final double width;
  final double height;
  final int rotation;

  const PageModel({
    required this.pageNumber,
    required this.width,
    required this.height,
    this.rotation = 0,
  });

  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'width': width,
    'height': height,
    'rotation': rotation,
  };

  factory PageModel.fromJson(Map<String, dynamic> json) {
    return PageModel(
      pageNumber: json['pageNumber'] as int? ?? 1,
      width: (json['width'] as num?)?.toDouble() ?? 595.0,
      height: (json['height'] as num?)?.toDouble() ?? 842.0,
      rotation: json['rotation'] as int? ?? 0,
    );
  }
}
