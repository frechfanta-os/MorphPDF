package ai

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestProviderMissingAPIKey(t *testing.T) {
	provider := NewOpenRouterProvider("https://openrouter.ai/api/v1", "", nil)
	if provider.IsConfigured() {
		t.Errorf("expected IsConfigured() to be false with empty key")
	}

	_, err := provider.Chat(context.Background(), AIRequest{
		Model:    "meta-llama/llama-3.3-70b-instruct:free",
		Messages: []AIMessage{{Role: "user", Content: "Hello"}},
	})
	if !errors.Is(err, ErrAINotConfigured) {
		t.Errorf("expected ErrAINotConfigured, got %v", err)
	}
}

func TestProviderBaseURLConfiguration(t *testing.T) {
	provider := NewOpenRouterProvider("https://custom.openrouter.test/v1/", "test-key", nil)
	if provider.baseURL != "https://custom.openrouter.test/v1" {
		t.Errorf("expected trimmed baseURL, got %s", provider.baseURL)
	}
}

func TestProviderHeadersAndRequestBody(t *testing.T) {
	secretKey := "test-secret-key-12345"
	var receivedAuthHeader string
	var receivedContentType string
	var receivedBody AIRequest

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedAuthHeader = r.Header.Get("Authorization")
		receivedContentType = r.Header.Get("Content-Type")

		bodyBytes, _ := io.ReadAll(r.Body)
		_ = json.Unmarshal(bodyBytes, &receivedBody)

		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(AIResponse{
			ID:    "gen-123",
			Model: "test-model",
			Choices: []AIChoice{
				{
					Index:        0,
					Message:      AIMessage{Role: "assistant", Content: "Test response"},
					FinishReason: "stop",
				},
			},
		})
	}))
	defer server.Close()

	provider := NewOpenRouterProvider(server.URL, secretKey, server.Client())
	resp, err := provider.Chat(context.Background(), AIRequest{
		Model:       "test-model",
		Messages:    []AIMessage{{Role: "user", Content: "Hello"}},
		Temperature: 0.5,
		MaxTokens:   100,
	})

	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if receivedAuthHeader != "Bearer "+secretKey {
		t.Errorf("expected auth header 'Bearer %s', got '%s'", secretKey, receivedAuthHeader)
	}
	if receivedContentType != "application/json" {
		t.Errorf("expected content-type application/json, got '%s'", receivedContentType)
	}
	if receivedBody.Model != "test-model" || len(receivedBody.Messages) != 1 {
		t.Errorf("unexpected received body: %+v", receivedBody)
	}
	if len(resp.Choices) != 1 || resp.Choices[0].Message.Content != "Test response" {
		t.Errorf("unexpected response: %+v", resp)
	}
}

func TestProviderErrorCodes(t *testing.T) {
	tests := []struct {
		name        string
		statusCode  int
		response    string
		expectedErr error
	}{
		{
			name:        "HTTP 400 Bad Request",
			statusCode:  http.StatusBadRequest,
			response:    `{"error": "bad request"}`,
			expectedErr: ErrAIBadRequest,
		},
		{
			name:        "HTTP 401 Unauthorized",
			statusCode:  http.StatusUnauthorized,
			response:    `{"error": "invalid api key"}`,
			expectedErr: ErrAIUnauthorized,
		},
		{
			name:        "HTTP 429 Rate Limit",
			statusCode:  http.StatusTooManyRequests,
			response:    `{"error": "quota exceeded"}`,
			expectedErr: ErrAIRateLimit,
		},
		{
			name:        "HTTP 500 Server Error",
			statusCode:  http.StatusInternalServerError,
			response:    `{"error": "server error"}`,
			expectedErr: ErrAIServerError,
		},
		{
			name:        "Malformed JSON Response",
			statusCode:  http.StatusOK,
			response:    `{invalid json`,
			expectedErr: ErrAIMalformedResponse,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(tt.statusCode)
				_, _ = w.Write([]byte(tt.response))
			}))
			defer server.Close()

			provider := NewOpenRouterProvider(server.URL, "dummy-key", server.Client())
			_, err := provider.Chat(context.Background(), AIRequest{
				Model:    "test-model",
				Messages: []AIMessage{{Role: "user", Content: "Test"}},
			})

			if !errors.Is(err, tt.expectedErr) {
				t.Errorf("expected error %v, got %v", tt.expectedErr, err)
			}
		})
	}
}

func TestProviderTimeout(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		time.Sleep(50 * time.Millisecond)
		w.WriteHeader(http.StatusOK)
	}))
	defer server.Close()

	provider := NewOpenRouterProvider(server.URL, "dummy-key", server.Client())
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Millisecond)
	defer cancel()

	_, err := provider.Chat(ctx, AIRequest{
		Model:    "test-model",
		Messages: []AIMessage{{Role: "user", Content: "Test"}},
	})

	if !errors.Is(err, ErrAITimeout) {
		t.Errorf("expected ErrAITimeout, got %v", err)
	}
}

func TestSecretNeverLeakInErrorMessage(t *testing.T) {
	superSecretKey := "sk-or-v1-my-ultra-secret-test-key-999"
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Server returns an error echoing the header or query
		w.WriteHeader(http.StatusBadGateway)
		_, _ = w.Write([]byte("Error with token: " + r.Header.Get("Authorization")))
	}))
	defer server.Close()

	provider := NewOpenRouterProvider(server.URL, superSecretKey, server.Client())
	_, err := provider.Chat(context.Background(), AIRequest{
		Model:    "test-model",
		Messages: []AIMessage{{Role: "user", Content: "Test"}},
	})

	if err == nil {
		t.Fatalf("expected error, got nil")
	}
	if strings.Contains(err.Error(), superSecretKey) {
		t.Fatalf("SECURITY VIOLATION: Secret key leaked in error message: %s", err.Error())
	}
}
