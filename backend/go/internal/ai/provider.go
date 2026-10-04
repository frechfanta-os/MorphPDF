package ai

import (
	"context"
	"errors"
)

var (
	// ErrAiNotImplemented is returned for stub AI operations in phase 1.
	ErrAiNotImplemented = errors.New("ai provider operation not implemented in this phase")
)

// AnalysisResult holds structured output from document analysis.
type AnalysisResult struct {
	Summary   string            `json:"summary"`
	Entities  []string          `json:"entities"`
	Keywords  []string          `json:"keywords"`
	Language  string            `json:"language"`
	Metadata  map[string]string `json:"metadata"`
}

// AiProvider abstracts LLM interactions (e.g. OpenRouter).
type AiProvider interface {
	GetProviderName() string
	AnalyzeDocument(ctx context.Context, text string, instructions string) (*AnalysisResult, error)
	CorrectText(ctx context.Context, text string, context string) (string, error)
	SummarizeDocument(ctx context.Context, text string, maxLength int) (string, error)
	ExtractStructuredData(ctx context.Context, text string, schema string) (string, error)
	TranslateText(ctx context.Context, text string, targetLanguage string) (string, error)
}

// OpenRouterProviderMock is a mock implementation of OpenRouter for Phase 1.
type OpenRouterProviderMock struct {
	BaseURL string
	APIKey  string
}

// NewOpenRouterProviderMock creates a new mock OpenRouter provider.
func NewOpenRouterProviderMock(baseURL, apiKey string) *OpenRouterProviderMock {
	return &OpenRouterProviderMock{
		BaseURL: baseURL,
		APIKey:  apiKey,
	}
}

func (p *OpenRouterProviderMock) GetProviderName() string {
	return "openrouter-mock"
}

func (p *OpenRouterProviderMock) AnalyzeDocument(ctx context.Context, text string, instructions string) (*AnalysisResult, error) {
	return nil, ErrAiNotImplemented
}

func (p *OpenRouterProviderMock) CorrectText(ctx context.Context, text string, context string) (string, error) {
	return "", ErrAiNotImplemented
}

func (p *OpenRouterProviderMock) SummarizeDocument(ctx context.Context, text string, maxLength int) (string, error) {
	return "", ErrAiNotImplemented
}

func (p *OpenRouterProviderMock) ExtractStructuredData(ctx context.Context, text string, schema string) (string, error) {
	return "", ErrAiNotImplemented
}

func (p *OpenRouterProviderMock) TranslateText(ctx context.Context, text string, targetLanguage string) (string, error) {
	return "", ErrAiNotImplemented
}
