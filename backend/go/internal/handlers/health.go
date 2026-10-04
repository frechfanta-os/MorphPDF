package handlers

import (
	"net/http"

	"morphpdf/backend/internal/services"
	"morphpdf/backend/pkg/response"
)

// HealthHandler handles health check requests.
type HealthHandler struct {
	healthService services.HealthService
}

// NewHealthHandler creates a new HealthHandler.
func NewHealthHandler(s services.HealthService) *HealthHandler {
	return &HealthHandler{healthService: s}
}

// HandleHealth handles GET /api/v1/health.
func (h *HealthHandler) HandleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		response.WriteError(w, http.StatusMethodNotAllowed, "METHOD_NOT_ALLOWED", "Method not allowed")
		return
	}
	status := h.healthService.Check()
	response.WriteSuccess(w, status)
}
