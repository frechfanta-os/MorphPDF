package handlers

import (
	"encoding/json"
	"net/http"

	"morphpdf/backend/internal/services"
	"morphpdf/backend/pkg/response"
)

// PdfHandler handles PDF processing API requests using PdfProcessingService.
type PdfHandler struct {
	service *services.PdfProcessingService
}

// NewPdfHandler creates a new PdfHandler.
func NewPdfHandler(service *services.PdfProcessingService) *PdfHandler {
	return &PdfHandler{
		service: service,
	}
}

type MergeRequest struct {
	Files      []string `json:"files"`
	OutputPath string   `json:"output_path"`
}

func (h *PdfHandler) Merge(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	var req MergeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid request body")
		return
	}

	res, err := h.service.Merge(r.Context(), req.Files, req.OutputPath)
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "PDF_MERGE_ERROR", err.Error())
		return
	}

	response.WriteSuccess(w, res)
}

type SplitRequest struct {
	File      string `json:"file"`
	OutputDir string `json:"output_dir"`
	Span      int    `json:"span"`
}

func (h *PdfHandler) Split(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	var req SplitRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid request body")
		return
	}

	outFiles, err := h.service.Split(r.Context(), req.File, req.OutputDir, req.Span)
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "PDF_SPLIT_ERROR", err.Error())
		return
	}

	response.WriteSuccess(w, map[string]interface{}{
		"files": outFiles,
		"count": len(outFiles),
	})
}

type ExtractPagesRequest struct {
	File      string `json:"file"`
	OutputDir string `json:"output_dir"`
	Pages     []int  `json:"pages"`
}

func (h *PdfHandler) Extract(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	var req ExtractPagesRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid request body")
		return
	}

	outFiles, err := h.service.ExtractPages(r.Context(), req.File, req.OutputDir, req.Pages)
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "PDF_EXTRACT_ERROR", err.Error())
		return
	}

	response.WriteSuccess(w, map[string]interface{}{
		"files": outFiles,
		"count": len(outFiles),
	})
}

type ReorderRequest struct {
	File         string `json:"file"`
	OutputPath   string `json:"output_path"`
	OrderedPages []int  `json:"ordered_pages"`
}

func (h *PdfHandler) Reorder(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	var req ReorderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid request body")
		return
	}

	if err := h.service.Reorder(r.Context(), req.File, req.OutputPath, req.OrderedPages); err != nil {
		response.WriteError(w, http.StatusBadRequest, "PDF_REORDER_ERROR", err.Error())
		return
	}

	response.WriteSuccess(w, map[string]interface{}{
		"output_file": req.OutputPath,
		"status":      "success",
	})
}

type RotateRequest struct {
	File       string `json:"file"`
	OutputPath string `json:"output_path"`
	Rotation   int    `json:"rotation"`
	Pages      []int  `json:"pages"`
}

func (h *PdfHandler) Rotate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	var req RotateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid request body")
		return
	}

	if err := h.service.Rotate(r.Context(), req.File, req.OutputPath, req.Rotation, req.Pages); err != nil {
		response.WriteError(w, http.StatusBadRequest, "PDF_ROTATE_ERROR", err.Error())
		return
	}

	response.WriteSuccess(w, map[string]interface{}{
		"output_file": req.OutputPath,
		"rotation":    req.Rotation,
		"status":      "success",
	})
}

type OptimizeRequest struct {
	File       string `json:"file"`
	OutputPath string `json:"output_path"`
}

func (h *PdfHandler) Optimize(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	var req OptimizeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid request body")
		return
	}

	res, err := h.service.Optimize(r.Context(), req.File, req.OutputPath)
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "PDF_OPTIMIZE_ERROR", err.Error())
		return
	}

	response.WriteSuccess(w, res)
}

func (h *PdfHandler) Compress(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	var req OptimizeRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.WriteError(w, http.StatusBadRequest, "BAD_REQUEST", "Invalid request body")
		return
	}

	res, err := h.service.Compress(r.Context(), req.File, req.OutputPath)
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "PDF_COMPRESS_ERROR", err.Error())
		return
	}

	response.WriteSuccess(w, res)
}

func (h *PdfHandler) Inspect(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}

	filePath := r.URL.Query().Get("file")
	if filePath == "" {
		response.WriteError(w, http.StatusBadRequest, "BAD_REQUEST", "Missing 'file' query parameter")
		return
	}

	res, err := h.service.Inspect(r.Context(), filePath)
	if err != nil {
		response.WriteError(w, http.StatusBadRequest, "PDF_INSPECT_ERROR", err.Error())
		return
	}

	response.WriteSuccess(w, res)
}
