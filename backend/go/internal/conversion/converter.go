package conversion

import (
	"context"
	"errors"
	"io"
)

var (
	// ErrConversionNotImplemented is returned for stub conversions in phase 1.
	ErrConversionNotImplemented = errors.New("pdf to word conversion not implemented in this phase")
)

// ConversionOptions specifies parameters for PDF to Word conversion.
type ConversionOptions struct {
	PreserveLayout bool `json:"preserveLayout"`
	ExtractImages  bool `json:"extractImages"`
	DetectTables   bool `json:"detectTables"`
	OcrScannedPages bool `json:"ocrScannedPages"`
}

// PdfToWordConverter abstracts the PDF to DOCX conversion pipeline.
type PdfToWordConverter interface {
	ConvertPdfToWord(ctx context.Context, pdfReader io.Reader, docxWriter io.Writer, opts ConversionOptions) error
}

// MockPdfToWordConverter provides a mock implementation for phase 1.
type MockPdfToWordConverter struct{}

// NewMockPdfToWordConverter creates a new mock converter.
func NewMockPdfToWordConverter() *MockPdfToWordConverter {
	return &MockPdfToWordConverter{}
}

func (m *MockPdfToWordConverter) ConvertPdfToWord(ctx context.Context, pdfReader io.Reader, docxWriter io.Writer, opts ConversionOptions) error {
	return ErrConversionNotImplemented
}
