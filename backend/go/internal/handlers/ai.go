package handlers

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"

	"morphpdf/backend/internal/ai"
	"morphpdf/backend/internal/services"
	"morphpdf/backend/pkg/response"
)

// AIHandler processes AI assistance endpoints.
type AIHandler struct {
	aiService services.AIService
}

// NewAIHandler creates a new AIHandler.
func NewAIHandler(svc services.AIService) *AIHandler {
	return &AIHandler{aiService: svc}
}

type ChatPayload struct {
	Message string         `json:"message"`
	History []ai.AIMessage `json:"history"`
}

type AnalyzePayload struct {
	Text         string `json:"text"`
	Instructions string `json:"instructions"`
}

type CorrectPayload struct {
	Text    string `json:"text"`
	Context string `json:"context"`
}

type SummarizePayload struct {
	Text      string `json:"text"`
	MaxLength int    `json:"max_length"`
}

type ExtractPayload struct {
	Text   string `json:"text"`
	Schema string `json:"schema"`
}

type TranslatePayload struct {
	Text           string `json:"text"`
	TargetLanguage string `json:"target_language"`
}

func (h *AIHandler) mapError(w http.ResponseWriter, err error) {
	if errors.Is(err, ai.ErrAINotConfigured) {
		response.WriteError(w, http.StatusServiceUnavailable, "AI_NOT_CONFIGURED", "AI provider is not configured")
		return
	}
	if errors.Is(err, ai.ErrAIRateLimit) {
		response.WriteError(w, http.StatusTooManyRequests, "AI_RATE_LIMIT", "AI rate limit reached or quota exceeded")
		return
	}
	if errors.Is(err, ai.ErrAIUnauthorized) {
		response.WriteError(w, http.StatusUnauthorized, "AI_UNAUTHORIZED", "AI provider authentication failed")
		return
	}
	if errors.Is(err, ai.ErrAITimeout) {
		response.WriteError(w, http.StatusGatewayTimeout, "AI_TIMEOUT", "AI request timed out")
		return
	}
	if errors.Is(err, ai.ErrAIBadRequest) {
		response.WriteError(w, http.StatusBadRequest, "AI_BAD_REQUEST", err.Error())
		return
	}
	response.WriteError(w, http.StatusInternalServerError, "AI_ERROR", err.Error())
}

// HandleStatus returns the current status and model of the AI provider.
func (h *AIHandler) HandleStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	response.WriteSuccess(w, map[string]interface{}{
		"provider":   "OpenRouter",
		"configured": h.aiService.IsConfigured(),
		"model":      h.aiService.GetModel(),
		"status":     map[bool]string{true: "available", false: "not_configured"}[h.aiService.IsConfigured()],
	})
}

// HandleChat processes general conversation or document Q&A.
func (h *AIHandler) HandleChat(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, 1024*1024))
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST", "Failed to read request body")
		return
	}

	var payload ChatPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_JSON", "Invalid JSON payload")
		return
	}

	reply, err := h.aiService.Chat(r.Context(), payload.Message, payload.History)
	if err != nil {
		h.mapError(w, err)
		return
	}

	response.WriteSuccess(w, map[string]string{
		"response": reply,
	})
}

// HandleAnalyze handles POST /api/v1/ai/analyze
func (h *AIHandler) HandleAnalyze(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, 1024*1024))
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST", "Failed to read request body")
		return
	}

	var payload AnalyzePayload
	if err := json.Unmarshal(body, &payload); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_JSON", "Invalid JSON payload")
		return
	}

	res, err := h.aiService.AnalyzeDocument(r.Context(), payload.Text, payload.Instructions)
	if err != nil {
		h.mapError(w, err)
		return
	}

	response.WriteSuccess(w, res)
}

// HandleCorrect handles POST /api/v1/ai/correct
func (h *AIHandler) HandleCorrect(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, 1024*1024))
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST", "Failed to read request body")
		return
	}

	var payload CorrectPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_JSON", "Invalid JSON payload")
		return
	}

	corrected, err := h.aiService.CorrectText(r.Context(), payload.Text, payload.Context)
	if err != nil {
		h.mapError(w, err)
		return
	}

	response.WriteSuccess(w, map[string]string{
		"corrected": corrected,
	})
}

// HandleSummarize handles POST /api/v1/ai/summarize
func (h *AIHandler) HandleSummarize(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, 1024*1024))
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST", "Failed to read request body")
		return
	}

	var payload SummarizePayload
	if err := json.Unmarshal(body, &payload); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_JSON", "Invalid JSON payload")
		return
	}

	summary, err := h.aiService.SummarizeDocument(r.Context(), payload.Text, payload.MaxLength)
	if err != nil {
		h.mapError(w, err)
		return
	}

	response.WriteSuccess(w, map[string]string{
		"summary": summary,
	})
}

// HandleExtract handles POST /api/v1/ai/extract
func (h *AIHandler) HandleExtract(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, 1024*1024))
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST", "Failed to read request body")
		return
	}

	var payload ExtractPayload
	if err := json.Unmarshal(body, &payload); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_JSON", "Invalid JSON payload")
		return
	}

	extracted, err := h.aiService.ExtractStructuredData(r.Context(), payload.Text, payload.Schema)
	if err != nil {
		h.mapError(w, err)
		return
	}

	response.WriteSuccess(w, map[string]string{
		"extracted": extracted,
	})
}

// HandleTranslate handles POST /api/v1/ai/translate
func (h *AIHandler) HandleTranslate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	body, err := io.ReadAll(io.LimitReader(r.Body, 1024*1024))
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_REQUEST", "Failed to read request body")
		return
	}

	var payload TranslatePayload
	if err := json.Unmarshal(body, &payload); err != nil {
		response.WriteError(w, http.StatusBadRequest, "INVALID_JSON", "Invalid JSON payload")
		return
	}

	translated, err := h.aiService.TranslateText(r.Context(), payload.Text, payload.TargetLanguage)
	if err != nil {
		h.mapError(w, err)
		return
	}

	response.WriteSuccess(w, map[string]string{
		"translated":      translated,
		"target_language": payload.TargetLanguage,
	})
}
