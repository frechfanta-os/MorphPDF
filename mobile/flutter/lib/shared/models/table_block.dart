class TableBlock {
  final String id;
  final int pageNumber;
  final double x;
  final double y;
  final double width;
  final double height;
  final int rows;
  final int columns;

  const TableBlock({
    required this.id,
    required this.pageNumber,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rows,
    required this.columns,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageNumber': pageNumber,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rows': rows,
    'columns': columns,
  };

  factory TableBlock.fromJson(Map<String, dynamic> json) {
    return TableBlock(
      id: json['id'] as String? ?? '',
      pageNumber: json['pageNumber'] as int? ?? 1,
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      rows: json['rows'] as int? ?? 0,
      columns: json['columns'] as int? ?? 0,
    );
  }
}
