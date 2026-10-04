package ocr

import (
	"context"
	"errors"
	"io"
	"morphpdf/backend/internal/models"
)

var (
	// ErrOcrNotImplemented is returned for stub OCR operations in phase 1.
	ErrOcrNotImplemented = errors.New("ocr engine operation not implemented in this phase")
)

// OcrEngine defines the abstraction for optical character recognition.
type OcrEngine interface {
	GetEngineName() string
	SupportedLanguages() []string
	ExtractText(ctx context.Context, imageReader io.Reader, lang string) (string, []models.TextBlock, error)
}

// MockOcrEngine is a mock implementation of OcrEngine.
type MockOcrEngine struct {
	Name string
}

// NewMockOcrEngine returns a mock OCR engine.
func NewMockOcrEngine(name string) *MockOcrEngine {
	return &MockOcrEngine{Name: name}
}

func (m *MockOcrEngine) GetEngineName() string {
	if m.Name != "" {
		return m.Name
	}
	return "mock-ocr"
}

func (m *MockOcrEngine) SupportedLanguages() []string {
	return []string{"en", "fr", "ar", "es", "de"}
}

func (m *MockOcrEngine) ExtractText(ctx context.Context, imageReader io.Reader, lang string) (string, []models.TextBlock, error) {
	return "", nil, ErrOcrNotImplemented
}
