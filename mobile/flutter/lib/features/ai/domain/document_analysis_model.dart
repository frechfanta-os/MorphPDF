class DocumentAnalysisModel {
  final String summary;
  final String language;
  final String documentType;
  final List<String> importantInformation;
  final List<String> dates;
  final List<String> amounts;
  final List<String> people;
  final List<String> organizations;
  final List<String> issues;
  final List<String> suggestions;

  const DocumentAnalysisModel({
    required this.summary,
    this.language = 'fr',
    this.documentType = 'Document',
    this.importantInformation = const [],
    this.dates = const [],
    this.amounts = const [],
    this.people = const [],
    this.organizations = const [],
    this.issues = const [],
    this.suggestions = const [],
  });

  factory DocumentAnalysisModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val is List) {
        return val.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return DocumentAnalysisModel(
      summary: json['summary'] as String? ?? '',
      language: json['language'] as String? ?? 'fr',
      documentType: json['document_type'] as String? ?? 'Document',
      importantInformation: parseStringList(json['important_information']),
      dates: parseStringList(json['dates']),
      amounts: parseStringList(json['amounts']),
      people: parseStringList(json['people']),
      organizations: parseStringList(json['organizations']),
      issues: parseStringList(json['issues']),
      suggestions: parseStringList(json['suggestions']),
    );
  }

  Map<String, dynamic> toJson() => {
    'summary': summary,
    'language': language,
    'document_type': documentType,
    'important_information': importantInformation,
    'dates': dates,
    'amounts': amounts,
    'people': people,
    'organizations': organizations,
    'issues': issues,
    'suggestions': suggestions,
  };
}
