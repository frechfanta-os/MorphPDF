package response

import (
	"encoding/json"
	"net/http"
)

// APIError represents the standardized error payload.
type APIError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

// APIResponse represents the standardized JSON envelope.
type APIResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data"`
	Error   *APIError   `json:"error"`
}

// WriteJSON sends a JSON response with status code.
func WriteJSON(w http.ResponseWriter, status int, resp APIResponse) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(resp)
}

// WriteSuccess sends a standard success response (HTTP 200).
func WriteSuccess(w http.ResponseWriter, data interface{}) {
	WriteJSON(w, http.StatusOK, APIResponse{
		Success: true,
		Data:    data,
		Error:   nil,
	})
}

// WriteError sends a standard error response with a given HTTP status code.
func WriteError(w http.ResponseWriter, status int, code, message string) {
	WriteJSON(w, status, APIResponse{
		Success: false,
		Data:    nil,
		Error: &APIError{
			Code:    code,
			Message: message,
		},
	})
}

// WriteNotImplemented sends a standard HTTP 501 Not Implemented response.
func WriteNotImplemented(w http.ResponseWriter, endpoint string) {
	WriteJSON(w, http.StatusNotImplemented, APIResponse{
		Success: false,
		Data:    nil,
		Error: &APIError{
			Code:    "NOT_IMPLEMENTED",
			Message: "Endpoint " + endpoint + " is not implemented yet in this phase",
		},
	})
}
