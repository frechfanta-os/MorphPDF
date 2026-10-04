package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"

	"morphpdf/backend/internal/handlers"
	"morphpdf/backend/internal/services"
)

func setupPdfHandler() (*handlers.PdfHandler, *services.PdfProcessingService) {
	svc := services.NewPdfProcessingService()
	h := handlers.NewPdfHandler(svc)
	return h, svc
}

func TestPdfHandler_Merge(t *testing.T) {
	h, _ := setupPdfHandler()

	tmpDir := t.TempDir()
	outFile := filepath.Join(tmpDir, "out_merge.pdf")

	reqBody := handlers.MergeRequest{
		Files: []string{
			"../../testdata/doc_single_page.pdf",
			"../../testdata/doc_multipage.pdf",
		},
		OutputPath: outFile,
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/pdf/merge", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	h.Merge(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
	}

	var resp map[string]interface{}
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("cannot decode response: %v", err)
	}

	if resp["success"] != true {
		t.Errorf("expected success: true, got %v", resp["success"])
	}
}

func TestPdfHandler_Split(t *testing.T) {
	h, _ := setupPdfHandler()

	tmpDir := t.TempDir()
	reqBody := handlers.SplitRequest{
		File:      "../../testdata/doc_multipage.pdf",
		OutputDir: tmpDir,
		Span:      1,
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/pdf/split", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	h.Split(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestPdfHandler_Extract(t *testing.T) {
	h, _ := setupPdfHandler()

	tmpDir := t.TempDir()
	reqBody := handlers.ExtractPagesRequest{
		File:      "../../testdata/doc_multipage.pdf",
		OutputDir: tmpDir,
		Pages:     []int{1, 2},
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/pdf/extract", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	h.Extract(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestPdfHandler_Reorder(t *testing.T) {
	h, _ := setupPdfHandler()

	tmpDir := t.TempDir()
	outFile := filepath.Join(tmpDir, "out_reorder.pdf")

	reqBody := handlers.ReorderRequest{
		File:         "../../testdata/doc_multipage.pdf",
		OutputPath:   outFile,
		OrderedPages: []int{3, 2, 1},
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/pdf/reorder", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	h.Reorder(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestPdfHandler_Rotate(t *testing.T) {
	h, _ := setupPdfHandler()

	tmpDir := t.TempDir()
	outFile := filepath.Join(tmpDir, "out_rotate.pdf")

	reqBody := handlers.RotateRequest{
		File:       "../../testdata/doc_single_page.pdf",
		OutputPath: outFile,
		Rotation:   90,
		Pages:      []int{1},
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/pdf/rotate", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	h.Rotate(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestPdfHandler_Optimize(t *testing.T) {
	h, _ := setupPdfHandler()

	tmpDir := t.TempDir()
	outFile := filepath.Join(tmpDir, "out_opt.pdf")

	reqBody := handlers.OptimizeRequest{
		File:       "../../testdata/doc_multipage.pdf",
		OutputPath: outFile,
	}
	bodyBytes, _ := json.Marshal(reqBody)

	req := httptest.NewRequest(http.MethodPost, "/api/v1/pdf/optimize", bytes.NewReader(bodyBytes))
	rec := httptest.NewRecorder()

	h.Optimize(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
	}
}

func TestPdfHandler_Inspect(t *testing.T) {
	h, _ := setupPdfHandler()

	req := httptest.NewRequest(http.MethodGet, "/api/v1/pdf/inspect?file=../../testdata/doc_single_page.pdf", nil)
	rec := httptest.NewRecorder()

	h.Inspect(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected status 200, got %d: %s", rec.Code, rec.Body.String())
	}
}
