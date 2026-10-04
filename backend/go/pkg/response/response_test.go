package response

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWriteSuccess(t *testing.T) {
	w := httptest.NewRecorder()
	WriteSuccess(w, map[string]string{"foo": "bar"})

	if w.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d", w.Code)
	}

	var resp APIResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if !resp.Success {
		t.Errorf("expected success to be true")
	}
	if resp.Error != nil {
		t.Errorf("expected error to be nil")
	}
}

func TestWriteError(t *testing.T) {
	w := httptest.NewRecorder()
	WriteError(w, http.StatusBadRequest, "INVALID_INPUT", "Bad request payload")

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got %d", w.Code)
	}

	var resp APIResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Success {
		t.Errorf("expected success to be false")
	}
	if resp.Error == nil || resp.Error.Code != "INVALID_INPUT" {
		t.Errorf("expected error code INVALID_INPUT, got %v", resp.Error)
	}
}

func TestWriteNotImplemented(t *testing.T) {
	w := httptest.NewRecorder()
	WriteNotImplemented(w, "/api/v1/ocr/extract")

	if w.Code != http.StatusNotImplemented {
		t.Fatalf("expected status 501, got %d", w.Code)
	}

	var resp APIResponse
	if err := json.Unmarshal(w.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}

	if resp.Success {
		t.Errorf("expected success to be false")
	}
	if resp.Error == nil || resp.Error.Code != "NOT_IMPLEMENTED" {
		t.Errorf("expected error code NOT_IMPLEMENTED, got %v", resp.Error)
	}
}
