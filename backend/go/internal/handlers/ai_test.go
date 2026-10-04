package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"morphpdf/backend/internal/ai"
	"morphpdf/backend/internal/services"
	"morphpdf/backend/pkg/response"
)

type dummyAIProvider struct {
	configured bool
}

func (d *dummyAIProvider) GetProviderName() string { return "dummy" }
func (d *dummyAIProvider) IsConfigured() bool      { return d.configured }
func (d *dummyAIProvider) Chat(ctx context.Context, req ai.AIRequest) (*ai.AIResponse, error) {
	if !d.configured {
		return nil, ai.ErrAINotConfigured
	}
	return &ai.AIResponse{
		ID:    "dummy-resp",
		Model: req.Model,
		Choices: []ai.AIChoice{
			{
				Index:        0,
				Message:      ai.AIMessage{Role: "assistant", Content: `{"summary": "Test", "language": "fr", "document_type": "Note"}`},
				FinishReason: "stop",
			},
		},
	}, nil
}

func TestAIHandlerStatus(t *testing.T) {
	provider := &dummyAIProvider{configured: true}
	svc := services.NewAIService(provider, "test-model")
	handler := NewAIHandler(svc)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/ai/status", nil)
	w := httptest.NewRecorder()

	handler.HandleStatus(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}

	var resp response.APIResponse
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	if !resp.Success {
		t.Fatalf("expected success true")
	}

	dataMap := resp.Data.(map[string]interface{})
	if dataMap["configured"] != true || dataMap["model"] != "test-model" {
		t.Errorf("unexpected status data: %v", dataMap)
	}
}

func TestAIHandlerAnalyzeWhenNotConfigured(t *testing.T) {
	provider := &dummyAIProvider{configured: false}
	svc := services.NewAIService(provider, "test-model")
	handler := NewAIHandler(svc)

	body := bytes.NewReader([]byte(`{"text": "Sample text to analyze"}`))
	req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/analyze", body)
	w := httptest.NewRecorder()

	handler.HandleAnalyze(w, req)

	if w.Code != http.StatusServiceUnavailable {
		t.Fatalf("expected status 503, got %d", w.Code)
	}

	var resp response.APIResponse
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	if resp.Success {
		t.Fatalf("expected success false when not configured")
	}
	if resp.Error == nil || resp.Error.Code != "AI_NOT_CONFIGURED" {
		t.Errorf("expected error code AI_NOT_CONFIGURED, got %+v", resp.Error)
	}
}

func TestAIHandlerAnalyzeSuccess(t *testing.T) {
	provider := &dummyAIProvider{configured: true}
	svc := services.NewAIService(provider, "test-model")
	handler := NewAIHandler(svc)

	body := bytes.NewReader([]byte(`{"text": "Sample text to analyze"}`))
	req := httptest.NewRequest(http.MethodPost, "/api/v1/ai/analyze", body)
	w := httptest.NewRecorder()

	handler.HandleAnalyze(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}

	var resp response.APIResponse
	_ = json.Unmarshal(w.Body.Bytes(), &resp)
	if !resp.Success {
		t.Fatalf("expected success true")
	}
}
