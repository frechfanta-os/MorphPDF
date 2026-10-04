package services

import (
	"context"
	"testing"

	"morphpdf/backend/internal/ai"
)

type mockAIProvider struct {
	configured bool
	response   string
	err        error
}

func (m *mockAIProvider) GetProviderName() string {
	return "mock"
}

func (m *mockAIProvider) IsConfigured() bool {
	return m.configured
}

func (m *mockAIProvider) Chat(ctx context.Context, request ai.AIRequest) (*ai.AIResponse, error) {
	if m.err != nil {
		return nil, m.err
	}
	return &ai.AIResponse{
		ID:    "mock-id",
		Model: request.Model,
		Choices: []ai.AIChoice{
			{
				Index:        0,
				Message:      ai.AIMessage{Role: "assistant", Content: m.response},
				FinishReason: "stop",
			},
		},
	}, nil
}

func TestAIServiceChat(t *testing.T) {
	mock := &mockAIProvider{
		configured: true,
		response:   "Ceci est une réponse d'assistance.",
	}
	svc := NewAIService(mock, "test-model")

	res, err := svc.Chat(context.Background(), "Bonjour", nil)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if res != "Ceci est une réponse d'assistance." {
		t.Errorf("unexpected chat response: %s", res)
	}
}

func TestAIServiceAnalyzeStructuredJSON(t *testing.T) {
	validJSON := `{
		"summary": "Résumé de contrat",
		"language": "fr",
		"document_type": "Contrat",
		"important_information": ["Clause 1"],
		"dates": ["2026-10-04"],
		"amounts": ["5000 EUR"],
		"people": ["Alice"],
		"organizations": ["GHD Studio"],
		"issues": [],
		"suggestions": ["Signer le document"]
	}`

	mock := &mockAIProvider{
		configured: true,
		response:   "```json\n" + validJSON + "\n```",
	}
	svc := NewAIService(mock, "test-model")

	result, err := svc.AnalyzeDocument(context.Background(), "Contenu du contrat...", "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.DocumentType != "Contrat" || result.Language != "fr" {
		t.Errorf("unexpected document analysis result: %+v", result)
	}
	if len(result.Amounts) != 1 || result.Amounts[0] != "5000 EUR" {
		t.Errorf("unexpected amounts: %v", result.Amounts)
	}
}

func TestAIServiceEmptyInputValidation(t *testing.T) {
	mock := &mockAIProvider{configured: true}
	svc := NewAIService(mock, "test-model")

	_, err := svc.AnalyzeDocument(context.Background(), "", "")
	if err == nil {
		t.Errorf("expected error for empty document text")
	}

	_, err = svc.CorrectText(context.Background(), "   ", "")
	if err == nil {
		t.Errorf("expected error for empty text to correct")
	}

	_, err = svc.TranslateText(context.Background(), "Hello", "")
	if err == nil {
		t.Errorf("expected error for missing target language")
	}
}
