package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestLoggingMiddleware(t *testing.T) {
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusTeapot)
	})

	loggedHandler := Logging(handler)
	req := httptest.NewRequest(http.MethodGet, "/test", nil)
	w := httptest.NewRecorder()

	loggedHandler.ServeHTTP(w, req)

	if w.Code != http.StatusTeapot {
		t.Errorf("expected status %d, got %d", http.StatusTeapot, w.Code)
	}
}
