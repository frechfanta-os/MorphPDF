package handlers

import (
	"net/http"

	"morphpdf/backend/pkg/response"
)

// StubHandler handles stubbed endpoints for future phases with HTTP 501.
type StubHandler struct{}

// NewStubHandler creates a new StubHandler.
func NewStubHandler() *StubHandler {
	return &StubHandler{}
}

func (h *StubHandler) AnalyzeDocuments(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/documents/analyze")
}

func (h *StubHandler) ExtractOcr(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/ocr/extract")
}

func (h *StubHandler) AnalyzeAi(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/ai/analyze")
}

func (h *StubHandler) CorrectAi(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/ai/correct")
}

func (h *StubHandler) SummarizeAi(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/ai/summarize")
}

func (h *StubHandler) ExtractAi(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/ai/extract")
}

func (h *StubHandler) TranslateAi(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/ai/translate")
}

func (h *StubHandler) CleanPdf(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/pdf/clean")
}

func (h *StubHandler) MergePdf(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/pdf/merge")
}

func (h *StubHandler) SplitPdf(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/pdf/split")
}

func (h *StubHandler) ConvertPdfToWord(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/conversion/pdf-to-word")
}

func (h *StubHandler) Export(w http.ResponseWriter, r *http.Request) {
	response.WriteNotImplemented(w, "/api/v1/export")
}
