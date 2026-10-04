package http

import (
	"net/http"

	"morphpdf/backend/internal/handlers"
	"morphpdf/backend/internal/middleware"
	"morphpdf/backend/internal/services"
)

// NewRouter sets up routes for the MorphPDF API.
func NewRouter(healthSvc services.HealthService, aiSvc services.AIService) http.Handler {
	mux := http.NewServeMux()

	healthH := handlers.NewHealthHandler(healthSvc)
	aiH := handlers.NewAIHandler(aiSvc)
	stubsH := handlers.NewStubHandler()

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

	// Future endpoints (stubs with HTTP 501)
	mux.HandleFunc("/api/v1/documents/analyze", stubsH.AnalyzeDocuments)
	mux.HandleFunc("/api/v1/ocr/extract", stubsH.ExtractOcr)
	mux.HandleFunc("/api/v1/pdf/clean", stubsH.CleanPdf)
	mux.HandleFunc("/api/v1/pdf/merge", stubsH.MergePdf)
	mux.HandleFunc("/api/v1/pdf/split", stubsH.SplitPdf)
	mux.HandleFunc("/api/v1/conversion/pdf-to-word", stubsH.ConvertPdfToWord)
	mux.HandleFunc("/api/v1/export", stubsH.Export)

	return middleware.Logging(mux)
}
