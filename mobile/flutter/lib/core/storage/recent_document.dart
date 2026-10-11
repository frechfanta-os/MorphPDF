class RecentDocument {
  final String path;
  final String fileName;
  final int fileSize;
  final int pageCount;
  final DateTime lastOpened;

  const RecentDocument({
    required this.path,
    required this.fileName,
    required this.fileSize,
    required this.pageCount,
    required this.lastOpened,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'fileName': fileName,
        'fileSize': fileSize,
        'pageCount': pageCount,
        'lastOpened': lastOpened.toIso8601String(),
      };

  factory RecentDocument.fromJson(Map<String, dynamic> json) => RecentDocument(
        path: json['path'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        fileSize: json['fileSize'] as int? ?? 0,
        pageCount: json['pageCount'] as int? ?? 1,
        lastOpened: json['lastOpened'] != null
            ? DateTime.tryParse(json['lastOpened'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
