package services

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"morphpdf/backend/internal/ai"
	"morphpdf/backend/internal/ai/prompts"
)

const (
	MaxDocumentLength = 32000 // characters safe limit
	DefaultTimeout    = 30 * time.Second
)

// AIService defines operations for AI document assistance.
type AIService interface {
	IsConfigured() bool
	GetModel() string
	Chat(ctx context.Context, userMessage string, history []ai.AIMessage) (string, error)
	AnalyzeDocument(ctx context.Context, text string, instructions string) (*ai.DocumentAnalysisResult, error)
	CorrectText(ctx context.Context, text string, contextInfo string) (string, error)
	SummarizeDocument(ctx context.Context, text string, maxLength int) (string, error)
	ExtractStructuredData(ctx context.Context, text string, schema string) (string, error)
	TranslateText(ctx context.Context, text string, targetLanguage string) (string, error)
}

type aiService struct {
	provider ai.AIProvider
	model    string
}

// NewAIService instantiates an AIService.
func NewAIService(provider ai.AIProvider, model string) AIService {
	if model == "" {
		model = "meta-llama/llama-3.3-70b-instruct:free"
	}
	return &aiService{
		provider: provider,
		model:    model,
	}
}

func (s *aiService) IsConfigured() bool {
	return s.provider.IsConfigured()
}

func (s *aiService) GetModel() string {
	return s.model
}

func (s *aiService) Chat(ctx context.Context, userMessage string, history []ai.AIMessage) (string, error) {
	if strings.TrimSpace(userMessage) == "" {
		return "", errors.New("user message cannot be empty")
	}

	messages := []ai.AIMessage{
		{Role: "system", Content: prompts.SystemPromptDocumentAssistant},
	}
	for _, m := range history {
		if strings.TrimSpace(m.Content) != "" {
			messages = append(messages, m)
		}
	}
	messages = append(messages, ai.AIMessage{Role: "user", Content: userMessage})

	ctxTimeout, cancel := context.WithTimeout(ctx, DefaultTimeout)
	defer cancel()

	resp, err := s.provider.Chat(ctxTimeout, ai.AIRequest{
		Model:       s.model,
		Messages:    messages,
		Temperature: 0.3,
		MaxTokens:   1500,
	})
	if err != nil {
		return "", err
	}
	if len(resp.Choices) == 0 {
		return "", errors.New("no completion choices returned by AI provider")
	}
	return resp.Choices[0].Message.Content, nil
}

func (s *aiService) AnalyzeDocument(ctx context.Context, text string, instructions string) (*ai.DocumentAnalysisResult, error) {
	if strings.TrimSpace(text) == "" {
		return nil, errors.New("document text cannot be empty")
	}
	if len(text) > MaxDocumentLength {
		text = text[:MaxDocumentLength]
	}

	systemPrompt, userPrompt := prompts.BuildAnalyzePrompt(text, instructions)

	ctxTimeout, cancel := context.WithTimeout(ctx, DefaultTimeout)
	defer cancel()

	resp, err := s.provider.Chat(ctxTimeout, ai.AIRequest{
		Model: s.model,
		Messages: []ai.AIMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		Temperature: 0.2,
		MaxTokens:   2000,
	})
	if err != nil {
		return nil, err
	}
	if len(resp.Choices) == 0 {
		return nil, errors.New("no analysis choices returned by AI provider")
	}

	rawContent := strings.TrimSpace(resp.Choices[0].Message.Content)
	// Strip markdown code fences if model enclosed JSON in ```json ... ```
	if strings.HasPrefix(rawContent, "```") {
		lines := strings.Split(rawContent, "\n")
		if len(lines) >= 2 {
			if strings.HasPrefix(lines[0], "```") {
				lines = lines[1:]
			}
			if len(lines) > 0 && strings.HasPrefix(lines[len(lines)-1], "```") {
				lines = lines[:len(lines)-1]
			}
			rawContent = strings.Join(lines, "\n")
		}
	}

	var result ai.DocumentAnalysisResult
	if err := json.Unmarshal([]byte(rawContent), &result); err != nil {
		// Graceful fallback: return unparsed summary rather than crashing
		return &ai.DocumentAnalysisResult{
			Summary:              rawContent,
			Language:             "auto",
			DocumentType:         "Document",
			ImportantInformation: []string{"Format brut retourné par le modèle"},
		}, nil
	}
	return &result, nil
}

func (s *aiService) CorrectText(ctx context.Context, text string, contextInfo string) (string, error) {
	if strings.TrimSpace(text) == "" {
		return "", errors.New("text to correct cannot be empty")
	}
	if len(text) > MaxDocumentLength {
		text = text[:MaxDocumentLength]
	}

	systemPrompt, userPrompt := prompts.BuildCorrectPrompt(text, contextInfo)

	ctxTimeout, cancel := context.WithTimeout(ctx, DefaultTimeout)
	defer cancel()

	resp, err := s.provider.Chat(ctxTimeout, ai.AIRequest{
		Model: s.model,
		Messages: []ai.AIMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		Temperature: 0.1,
		MaxTokens:   2000,
	})
	if err != nil {
		return "", err
	}
	if len(resp.Choices) == 0 {
		return "", errors.New("no completion choices returned by AI provider")
	}
	return strings.TrimSpace(resp.Choices[0].Message.Content), nil
}

func (s *aiService) SummarizeDocument(ctx context.Context, text string, maxLength int) (string, error) {
	if strings.TrimSpace(text) == "" {
		return "", errors.New("document text cannot be empty")
	}
	if len(text) > MaxDocumentLength {
		text = text[:MaxDocumentLength]
	}

	systemPrompt, userPrompt := prompts.BuildSummarizePrompt(text, maxLength)

	ctxTimeout, cancel := context.WithTimeout(ctx, DefaultTimeout)
	defer cancel()

	resp, err := s.provider.Chat(ctxTimeout, ai.AIRequest{
		Model: s.model,
		Messages: []ai.AIMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		Temperature: 0.2,
		MaxTokens:   1500,
	})
	if err != nil {
		return "", err
	}
	if len(resp.Choices) == 0 {
		return "", errors.New("no summary choices returned by AI provider")
	}
	return strings.TrimSpace(resp.Choices[0].Message.Content), nil
}

func (s *aiService) ExtractStructuredData(ctx context.Context, text string, schema string) (string, error) {
	if strings.TrimSpace(text) == "" {
		return "", errors.New("document text cannot be empty")
	}
	if len(text) > MaxDocumentLength {
		text = text[:MaxDocumentLength]
	}

	systemPrompt, userPrompt := prompts.BuildExtractPrompt(text, schema)

	ctxTimeout, cancel := context.WithTimeout(ctx, DefaultTimeout)
	defer cancel()

	resp, err := s.provider.Chat(ctxTimeout, ai.AIRequest{
		Model: s.model,
		Messages: []ai.AIMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		Temperature: 0.1,
		MaxTokens:   2000,
	})
	if err != nil {
		return "", err
	}
	if len(resp.Choices) == 0 {
		return "", errors.New("no extraction choices returned by AI provider")
	}
	return strings.TrimSpace(resp.Choices[0].Message.Content), nil
}

func (s *aiService) TranslateText(ctx context.Context, text string, targetLanguage string) (string, error) {
	if strings.TrimSpace(text) == "" {
		return "", errors.New("text to translate cannot be empty")
	}
	if strings.TrimSpace(targetLanguage) == "" {
		return "", errors.New("target language must be specified")
	}
	if len(text) > MaxDocumentLength {
		text = text[:MaxDocumentLength]
	}

	systemPrompt, userPrompt := prompts.BuildTranslatePrompt(text, targetLanguage)

	ctxTimeout, cancel := context.WithTimeout(ctx, DefaultTimeout)
	defer cancel()

	resp, err := s.provider.Chat(ctxTimeout, ai.AIRequest{
		Model: s.model,
		Messages: []ai.AIMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		Temperature: 0.2,
		MaxTokens:   2000,
	})
	if err != nil {
		return "", err
	}
	if len(resp.Choices) == 0 {
		return "", errors.New("no translation choices returned by AI provider")
	}
	return strings.TrimSpace(resp.Choices[0].Message.Content), nil
}
