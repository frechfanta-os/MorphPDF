package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

var (
	// ErrAINotConfigured is returned when the OpenRouter API key is missing.
	ErrAINotConfigured = errors.New("AI provider is not configured")
	// ErrAIRateLimit is returned when OpenRouter returns HTTP 429.
	ErrAIRateLimit = errors.New("AI rate limit reached or quota exceeded")
	// ErrAIUnauthorized is returned when OpenRouter returns HTTP 401.
	ErrAIUnauthorized = errors.New("AI provider authentication failed")
	// ErrAIBadRequest is returned when OpenRouter returns HTTP 400.
	ErrAIBadRequest = errors.New("invalid AI request parameters")
	// ErrAIServerError is returned when OpenRouter returns HTTP 5xx.
	ErrAIServerError = errors.New("AI provider internal server error")
	// ErrAITimeout is returned when an AI request times out.
	ErrAITimeout = errors.New("AI request timed out")
	// ErrAIMalformedResponse is returned when the provider returns invalid JSON.
	ErrAIMalformedResponse = errors.New("malformed response received from AI provider")
)

// AIMessage represents a single chat completion message.
type AIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// AIRequest represents a chat completion request to the AI provider.
type AIRequest struct {
	Model       string      `json:"model"`
	Messages    []AIMessage `json:"messages"`
	Temperature float64     `json:"temperature,omitempty"`
	MaxTokens   int         `json:"max_tokens,omitempty"`
}

// AIChoice represents an individual completion choice.
type AIChoice struct {
	Index        int       `json:"index"`
	Message      AIMessage `json:"message"`
	FinishReason string    `json:"finish_reason"`
}

// AIUsage represents token usage statistics.
type AIUsage struct {
	PromptTokens     int `json:"prompt_tokens"`
	CompletionTokens int `json:"completion_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

// AIResponse represents the standardized provider completion response.
type AIResponse struct {
	ID      string     `json:"id"`
	Model   string     `json:"model"`
	Choices []AIChoice `json:"choices"`
	Usage   *AIUsage   `json:"usage,omitempty"`
}

// DocumentAnalysisResult represents structured information extracted from a document.
type DocumentAnalysisResult struct {
	Summary              string   `json:"summary"`
	Language             string   `json:"language"`
	DocumentType         string   `json:"document_type"`
	ImportantInformation []string `json:"important_information"`
	Dates                []string `json:"dates"`
	Amounts              []string `json:"amounts"`
	People               []string `json:"people"`
	Organizations        []string `json:"organizations"`
	Issues               []string `json:"issues"`
	Suggestions          []string `json:"suggestions"`
}

// AIProvider defines the contract for any LLM provider in MorphPDF.
type AIProvider interface {
	GetProviderName() string
	IsConfigured() bool
	Chat(ctx context.Context, request AIRequest) (*AIResponse, error)
}

// OpenRouterProvider communicates with OpenRouter API.
type OpenRouterProvider struct {
	baseURL    string
	apiKey     string
	httpClient *http.Client
}

// NewOpenRouterProvider creates a new OpenRouter AI provider.
func NewOpenRouterProvider(baseURL, apiKey string, httpClient *http.Client) *OpenRouterProvider {
	if baseURL == "" {
		baseURL = "https://openrouter.ai/api/v1"
	}
	if httpClient == nil {
		httpClient = &http.Client{
			Timeout: 45 * time.Second,
		}
	}
	return &OpenRouterProvider{
		baseURL:    strings.TrimRight(baseURL, "/"),
		apiKey:     apiKey,
		httpClient: httpClient,
	}
}

func (p *OpenRouterProvider) GetProviderName() string {
	return "OpenRouter"
}

func (p *OpenRouterProvider) IsConfigured() bool {
	return strings.TrimSpace(p.apiKey) != ""
}

func (p *OpenRouterProvider) sanitizeError(err error) error {
	if err == nil {
		return nil
	}
	msg := err.Error()
	if p.apiKey != "" && strings.Contains(msg, p.apiKey) {
		msg = strings.ReplaceAll(msg, p.apiKey, "[REDACTED_API_KEY]")
		return errors.New(msg)
	}
	return err
}

func (p *OpenRouterProvider) Chat(ctx context.Context, request AIRequest) (*AIResponse, error) {
	if !p.IsConfigured() {
		return nil, ErrAINotConfigured
	}

	url := fmt.Sprintf("%s/chat/completions", p.baseURL)

	payloadBytes, err := json.Marshal(request)
	if err != nil {
		return nil, fmt.Errorf("failed to encode AI request: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(payloadBytes))
	if err != nil {
		return nil, fmt.Errorf("failed to create AI request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", p.apiKey))
	req.Header.Set("HTTP-Referer", "https://morphpdf.ghdinteractivestudio.com")
	req.Header.Set("X-Title", "MorphPDF")

	resp, err := p.httpClient.Do(req)
	if err != nil {
		if errors.Is(ctx.Err(), context.DeadlineExceeded) {
			return nil, ErrAITimeout
		}
		return nil, p.sanitizeError(fmt.Errorf("AI provider network error: %w", err))
	}
	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(io.LimitReader(resp.Body, 1024*1024*4)) // 4MB limit
	if err != nil {
		return nil, fmt.Errorf("failed to read AI response body: %w", err)
	}

	switch resp.StatusCode {
	case http.StatusOK:
		var aiResp AIResponse
		if err := json.Unmarshal(bodyBytes, &aiResp); err != nil {
			return nil, ErrAIMalformedResponse
		}
		return &aiResp, nil
	case http.StatusBadRequest:
		return nil, ErrAIBadRequest
	case http.StatusUnauthorized:
		return nil, ErrAIUnauthorized
	case http.StatusTooManyRequests:
		return nil, ErrAIRateLimit
	default:
		if resp.StatusCode >= 500 {
			return nil, ErrAIServerError
		}
		return nil, fmt.Errorf("AI provider returned unexpected status: %d", resp.StatusCode)
	}
}
