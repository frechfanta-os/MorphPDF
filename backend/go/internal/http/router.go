package http

import (
	"net/http"

	"morphpdf/backend/internal/handlers"
	"morphpdf/backend/internal/middleware"
	"morphpdf/backend/internal/services"
)

// NewRouter sets up routes for the MorphPDF API.
func NewRouter(healthSvc services.HealthService, aiSvc services.AIService, pdfSvc ...*services.PdfProcessingService) http.Handler {
	mux := http.NewServeMux()

	healthH := handlers.NewHealthHandler(healthSvc)
	aiH := handlers.NewAIHandler(aiSvc)
	stubsH := handlers.NewStubHandler()

	var actualPdfSvc *services.PdfProcessingService
	if len(pdfSvc) > 0 && pdfSvc[0] != nil {
		actualPdfSvc = pdfSvc[0]
	} else {
		actualPdfSvc = services.NewPdfProcessingService()
	}
	pdfH := handlers.NewPdfHandler(actualPdfSvc)

	// Health endpoint
	mux.HandleFunc("/api/v1/health", healthH.HandleHealth)

	// AI Endpoints
	mux.HandleFunc("/api/v1/ai/status", aiH.HandleStatus)
	mux.HandleFunc("/api/v1/ai/chat", aiH.HandleChat)
	mux.HandleFunc("/api/v1/ai/analyze", aiH.HandleAnalyze)
	mux.HandleFunc("/api/v1/ai/correct", aiH.HandleCorrect)
	mux.HandleFunc("/api/v1/ai/summarize", aiH.HandleSummarize)
	mux.HandleFunc("/api/v1/ai/extract", aiH.HandleExtract)
	mux.HandleFunc("/api/v1/ai/translate", aiH.HandleTranslate)

	// PDF Endpoints (pdfcpu powered)
	mux.HandleFunc("/api/v1/pdf/merge", pdfH.Merge)
	mux.HandleFunc("/api/v1/pdf/split", pdfH.Split)
	mux.HandleFunc("/api/v1/pdf/extract", pdfH.Extract)
	mux.HandleFunc("/api/v1/pdf/reorder", pdfH.Reorder)
	mux.HandleFunc("/api/v1/pdf/rotate", pdfH.Rotate)
	mux.HandleFunc("/api/v1/pdf/optimize", pdfH.Optimize)
	mux.HandleFunc("/api/v1/pdf/compress", pdfH.Compress)
	mux.HandleFunc("/api/v1/pdf/clean", pdfH.Optimize)
	mux.HandleFunc("/api/v1/pdf/inspect", pdfH.Inspect)

	// Future endpoints (stubs with HTTP 501)
	mux.HandleFunc("/api/v1/documents/analyze", stubsH.AnalyzeDocuments)
	mux.HandleFunc("/api/v1/ocr/extract", stubsH.ExtractOcr)
	mux.HandleFunc("/api/v1/conversion/pdf-to-word", stubsH.ConvertPdfToWord)
	mux.HandleFunc("/api/v1/export", stubsH.Export)

	return middleware.Logging(mux)
}
