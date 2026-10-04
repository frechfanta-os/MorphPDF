# OpenRouter AI Integration Guide — MorphPDF

## 1. Overview & Architecture

MorphPDF integrates Large Language Model capabilities through [OpenRouter](https://openrouter.ai).
To guarantee data privacy, local-first integrity, and key security, the mobile client **never** communicates with OpenRouter directly.

```
┌─────────────────────────────────┐
│     MorphPDF Flutter App        │
│  (Android UI / Riverpod / HTTP) │
└────────────────┬────────────────┘
                 │ HTTP (Standard DTOs, No Keys)
                 ▼
┌─────────────────────────────────┐
│       MorphPDF Go Backend       │
│    (Orchestration & Security)   │
└────────────────┬────────────────┘
                 │ Authorization: Bearer ${OPENROUTER_API_KEY}
                 ▼
┌─────────────────────────────────┐
│     OpenRouter API (v1)         │
│   (https://openrouter.ai/api/v1)│
└─────────────────────────────────┘
```

---

## 2. Environment Configuration

The backend reads configuration from environment variables or a local `.env` file (which is git-ignored).

| Variable | Description | Default Value | Required |
|---|---|---|---|
| `OPENROUTER_API_KEY` | OpenRouter API authentication secret | `""` | Yes (for AI features) |
| `OPENROUTER_BASE_URL` | OpenRouter base URL endpoint | `https://openrouter.ai/api/v1` | No |
| `OPENROUTER_MODEL` | Default LLM model identifier | `google/gemini-2.5-flash` | No |

### Sample `.env` Setup (Backend)

```bash
# In backend/go/.env (NEVER commit this file)
PORT=8080
ENV=development
OPENROUTER_API_KEY=your_openrouter_api_key_here
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_MODEL=google/gemini-2.5-flash
```

> [!WARNING]
> Never commit actual API keys or paste production keys into version control. Use dummy placeholders in all templates and documentation.

---

## 3. Endpoints & API Contracts

All AI routes are served under `/api/v1/ai`:

### `GET /api/v1/ai/status`
Returns configuration health without exposing secrets.
- **Response `200 OK`**:
```json
{
  "configured": true,
  "model": "google/gemini-2.5-flash",
  "provider": "openrouter"
}
```

### `POST /api/v1/ai/chat`
Free-form contextual conversational assistant for document workflows.
- **Request**:
```json
{
  "messages": [
    {"role": "user", "content": "How do I extract a table from this PDF?"}
  ],
  "temperature": 0.3
}
```

### `POST /api/v1/ai/analyze`
Generates structured JSON document analysis.
- **Request**:
```json
{
  "text": "Extracted document text...",
  "detail_level": "standard"
}
```
- **Response**: Returns structured insights including `document_type`, `summary`, `key_points`, `suggested_actions`, and `confidence`.

### `POST /api/v1/ai/correct`
Fixes OCR transcription errors, grammatical flaws, and formatting issues.
- **Request**:
```json
{
  "text": "D0cument t3xt with OCR erors...",
  "preserve_layout": true
}
```

### `POST /api/v1/ai/summarize`
Summarizes long document text into concise or detailed bullet points.
- **Request**:
```json
{
  "text": "Long document content...",
  "max_length": 300
}
```

### `POST /api/v1/ai/extract`
Extracts entities, key-value pairs, dates, amounts, and structured tables.
- **Request**:
```json
{
  "text": "Invoice #12345 Total: $500 Date: 2026-10-04...",
  "fields": ["invoice_number", "total_amount", "date"]
}
```

### `POST /api/v1/ai/translate`
Translates document content while preserving document context.
- **Request**:
```json
{
  "text": "Hello world",
  "target_language": "fr"
}
```

---

## 4. Security Rules & Safeguards

1. **Zero Secret Leakage**: The Flutter application code, Android manifest, build scripts, test fixtures, and logs contain zero references to OpenRouter API keys.
2. **Key Sanitization**: The Go backend `OpenRouterProvider` sanitizes and strips API keys from any outgoing log messages, error traces, or HTTP response bodies.
3. **Graceful Fallback**: When the Go backend is started without `OPENROUTER_API_KEY`, AI endpoints return a structured `503 Service Unavailable` with message `"OpenRouter API key is not configured"`. The mobile app displays an informational banner guiding the user to configure the backend without crashing.
4. **Local-First Bootstrap**: MorphPDF app splash screen preloads local persistence only; it never blocks on or queries remote AI endpoints during startup.
