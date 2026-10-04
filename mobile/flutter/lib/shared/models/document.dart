import '../enums/document_status.dart';

class DocumentModel {
  final String id;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final int pageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DocumentStatus status;

  const DocumentModel({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.pageCount,
    required this.createdAt,
    required this.updatedAt,
    this.status = DocumentStatus.pending,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'mimeType': mimeType,
    'fileSize': fileSize,
    'pageCount': pageCount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'status': status.name,
  };

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/pdf',
      fileSize: json['fileSize'] as int? ?? 0,
      pageCount: json['pageCount'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] != null
          ? DocumentStatus.fromString(json['status'] as String)
          : DocumentStatus.pending,
    );
  }

  DocumentModel copyWith({
    String? id,
    String? fileName,
    String? mimeType,
    int? fileSize,
    int? pageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DocumentStatus? status,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }
}
