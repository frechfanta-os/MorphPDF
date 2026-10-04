# Contrat d'API MorphPDF (v1)

MorphPDF utilise une API REST structurée selon une enveloppe JSON stricte.

## Format Standardisé

### Réponse Succès (HTTP 200)
```json
{
  "success": true,
  "data": { ... },
  "error": null
}
```

### Réponse Erreur (HTTP 4xx / 5xx)
```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "CODE_ERREUR",
    "message": "Message lisible décrivant le problème"
  }
}
```

---

## Endpoints

### 1. Santé du Service
- **GET** `/api/v1/health`
  - Réponse HTTP 200 :
    ```json
    {
      "success": true,
      "data": {
        "status": "ok",
        "service": "morphpdf",
        "version": "1.0.0"
      },
      "error": null
    }
    ```

### 2. Endpoints Documents & Moteurs (Stubs Phase 1 - HTTP 501 Not Implemented)
- **POST** `/api/v1/documents/analyze` : Analyse structurelle globale.
- **POST** `/api/v1/ocr/extract` : Extraction optique de texte.
- **POST** `/api/v1/ai/analyze` : Analyse sémantique par LLM.
- **POST** `/api/v1/ai/correct` : Correction et amélioration de texte.
- **POST** `/api/v1/ai/summarize` : Résumé automatique de document.
- **POST** `/api/v1/ai/extract` : Extraction de données structurées.
- **POST** `/api/v1/ai/translate` : Traduction assistée par IA.
- **POST** `/api/v1/pdf/clean` : Nettoyage et suppression des métadonnées.
- **POST** `/api/v1/pdf/merge` : Fusion de plusieurs fichiers PDF.
- **POST** `/api/v1/pdf/split` : Division ou extraction de pages.
- **POST** `/api/v1/conversion/pdf-to-word` : Conversion vers format DOCX.
- **POST** `/api/v1/export` : Exportation multi-formats.
