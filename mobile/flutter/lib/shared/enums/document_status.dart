/// Represents the lifecycle status of a document in MorphPDF.
enum DocumentStatus {
  pending,
  processing,
  ready,
  error;

  String get label {
    switch (this) {
      case DocumentStatus.pending:
        return 'En attente';
      case DocumentStatus.processing:
        return 'Traitement en cours';
      case DocumentStatus.ready:
        return 'Prêt';
      case DocumentStatus.error:
        return 'Erreur';
    }
  }

  static DocumentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'processing':
        return DocumentStatus.processing;
      case 'ready':
        return DocumentStatus.ready;
      case 'error':
        return DocumentStatus.error;
      case 'pending':
      default:
        return DocumentStatus.pending;
    }
  }
}
