package handlers

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"morphpdf/backend/internal/services"
	"morphpdf/backend/pkg/response"
)

func TestHandleHealth(t *testing.T) {
	svc := services.NewHealthService("1.0.0")
	handler := NewHealthHandler(svc)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/health", nil)
	w := httptest.NewRecorder()

	handler.HandleHealth(w, req)

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}

	var resp response.APIResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to parse json response: %v", err)
	}

	if !resp.Success {
		t.Fatalf("expected success true")
	}

	dataMap, ok := resp.Data.(map[string]interface{})
	if !ok {
		t.Fatalf("expected data map, got %T", resp.Data)
	}

	if dataMap["status"] != "ok" || dataMap["service"] != "morphpdf" || dataMap["version"] != "1.0.0" {
		t.Errorf("unexpected health data: %v", dataMap)
	}
}

func TestHandleHealthMethodNotAllowed(t *testing.T) {
	svc := services.NewHealthService("1.0.0")
	handler := NewHealthHandler(svc)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/health", nil)
	w := httptest.NewRecorder()

	handler.HandleHealth(w, req)

	if w.Code != http.StatusMethodNotAllowed {
		t.Errorf("expected status 405, got %d", w.Code)
	}
}
