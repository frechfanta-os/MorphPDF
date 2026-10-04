abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Erreur serveur']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Erreur d’accès au stockage']);
}

class DocumentFailure extends Failure {
  const DocumentFailure([super.message = 'Erreur de traitement du document']);
}

class OcrFailure extends Failure {
  const OcrFailure([super.message = 'Erreur lors de la reconnaissance OCR']);
}

class AiFailure extends Failure {
  const AiFailure([super.message = 'Erreur lors de l’analyse IA']);
}
