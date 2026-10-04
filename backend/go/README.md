# MorphPDF — Go Backend API

API HTTP et moteur d'orchestration pour l'application Android **MorphPDF**.

## Responsabilités
- Gestion sécurisée des clés API (OpenRouter) : le client mobile Flutter ne stocke aucun secret.
- Interface d'orchestration pour les moteurs PDF, OCR, IA et Conversion Word.
- Gestion des endpoints HTTP standardisés `/api/v1/*`.

## Architecture Interne

```
HTTP Handler
     ↓
  Service
     ↓
Repository / Engine (PDF, OCR, AI, Conversion, Storage)
```

## Configuration

Copiez `.env.example` en `.env` :
```bash
cp .env.example .env
```

Variables disponibles :
- `MORPHPDF_ENV` : Environnement (`development`, `testing`, `production`).
- `MORPHPDF_HOST` : Adresse d'écoute (défaut: `0.0.0.0`).
- `MORPHPDF_PORT` : Port d'écoute (défaut: `8080`).
- `OPENROUTER_API_KEY` : Clé secrète OpenRouter.
- `OPENROUTER_BASE_URL` : URL de base de l'API OpenRouter.
- `STORAGE_PATH` : Répertoire de stockage local.
- `OCR_ENGINE` : Moteur OCR actif (`mlkit`, `paddleocr`, etc.).
- `LOG_LEVEL` : Niveau de log (`debug`, `info`, `warn`, `error`).

## Lancement

```bash
go run cmd/server/main.go
```

## Tests

```bash
go test ./...
go vet ./...
```
