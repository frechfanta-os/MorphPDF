/// Typed exceptions for MorphPDF PDF Engine operations.
sealed class PdfException implements Exception {
  final String message;
  final String? path;

  const PdfException(this.message, {this.path});

  @override
  String toString() => path != null ? '$message (path: $path)' : message;
}

class PdfFileNotFoundException extends PdfException {
  const PdfFileNotFoundException(String path)
      : super('Le fichier PDF spécifié est introuvable.', path: path);
}

class PdfInvalidDocumentException extends PdfException {
  const PdfInvalidDocumentException([
    super.message = 'Le document PDF est corrompu ou invalide.',
    String? path,
  ]) : super(path: path);
}

class PdfEncryptedException extends PdfException {
  const PdfEncryptedException([
    super.message = 'Le document est chiffré et protégé.',
    String? path,
  ]) : super(path: path);
}

class PdfPasswordRequiredException extends PdfException {
  const PdfPasswordRequiredException([
    super.message = 'Un mot de passe est requis pour ouvrir ce document.',
    String? path,
  ]) : super(path: path);
}

class PdfRenderFailedException extends PdfException {
  final int pageNumber;
  const PdfRenderFailedException(this.pageNumber, [String message = 'Échec du rendu de la page.'])
      : super('$message (Page $pageNumber)');
}

class PdfTextExtractionFailedException extends PdfException {
  final int pageNumber;
  const PdfTextExtractionFailedException(this.pageNumber, [String message = 'Échec de l\'extraction du texte.'])
      : super('$message (Page $pageNumber)');
}

class PdfPageOutOfRangeException extends PdfException {
  final int pageNumber;
  final int totalPages;
  const PdfPageOutOfRangeException(this.pageNumber, this.totalPages)
      : super('La page $pageNumber est hors limites (1 à $totalPages).');
}

class PdfResourceLimitException extends PdfException {
  const PdfResourceLimitException(super.message);
}

class PdfEngineUnavailableException extends PdfException {
  const PdfEngineUnavailableException([
    super.message = 'Le moteur PDF natif est indisponible sur cette plateforme.',
  ]);
}
