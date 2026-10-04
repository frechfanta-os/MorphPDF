package pdf

import (
	"context"
	"errors"
	"io"
	"morphpdf/backend/internal/models"
)

var (
	// ErrPdfEngineNotImplemented is returned when an engine operation is called in stub mode.
	ErrPdfEngineNotImplemented = errors.New("pdf engine operation not implemented in this phase")
)

// PdfEngine abstracts PDF inspection, manipulation, rendering, and export.
type PdfEngine interface {
	Inspect(ctx context.Context, reader io.Reader) (*models.Document, []models.Page, error)
	ExtractText(ctx context.Context, reader io.Reader, page int) (string, error)
	RenderPage(ctx context.Context, reader io.Reader, page int, dpi int) ([]byte, error)
	Merge(ctx context.Context, readers []io.Reader, output io.Writer) error
	Split(ctx context.Context, reader io.Reader, pages []int, output io.Writer) error
	Clean(ctx context.Context, reader io.Reader, output io.Writer) error
	Compress(ctx context.Context, reader io.Reader, quality int, output io.Writer) error
	Export(ctx context.Context, reader io.Reader, format string, output io.Writer) error
}

// MockPdfEngine provides a stubbed implementation for phase 1.
type MockPdfEngine struct{}

// NewMockPdfEngine creates a new mock PDF engine.
func NewMockPdfEngine() *MockPdfEngine {
	return &MockPdfEngine{}
}

func (m *MockPdfEngine) Inspect(ctx context.Context, reader io.Reader) (*models.Document, []models.Page, error) {
	return nil, nil, ErrPdfEngineNotImplemented
}

func (m *MockPdfEngine) ExtractText(ctx context.Context, reader io.Reader, page int) (string, error) {
	return "", ErrPdfEngineNotImplemented
}

func (m *MockPdfEngine) RenderPage(ctx context.Context, reader io.Reader, page int, dpi int) ([]byte, error) {
	return nil, ErrPdfEngineNotImplemented
}

func (m *MockPdfEngine) Merge(ctx context.Context, readers []io.Reader, output io.Writer) error {
	return ErrPdfEngineNotImplemented
}

func (m *MockPdfEngine) Split(ctx context.Context, reader io.Reader, pages []int, output io.Writer) error {
	return ErrPdfEngineNotImplemented
}

func (m *MockPdfEngine) Clean(ctx context.Context, reader io.Reader, output io.Writer) error {
	return ErrPdfEngineNotImplemented
}

func (m *MockPdfEngine) Compress(ctx context.Context, reader io.Reader, quality int, output io.Writer) error {
	return ErrPdfEngineNotImplemented
}

func (m *MockPdfEngine) Export(ctx context.Context, reader io.Reader, format string, output io.Writer) error {
	return ErrPdfEngineNotImplemented
}
