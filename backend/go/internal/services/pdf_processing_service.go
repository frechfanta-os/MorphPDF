package services

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/pdfcpu/pdfcpu/pkg/api"
	"github.com/pdfcpu/pdfcpu/pkg/pdfcpu/model"
)

var (
	ErrEmptyInputFiles       = errors.New("input files list cannot be empty")
	ErrInsufficientFiles     = errors.New("merge requires at least two input files")
	ErrFileNotFound          = errors.New("file not found")
	ErrInvalidPageRange      = errors.New("invalid page range or page number")
	ErrInvalidRotation       = errors.New("rotation must be 90, 180, or 270 degrees")
	ErrDuplicateReorderPages = errors.New("reordered pages list contains duplicates or missing pages")
	ErrPdfEncrypted          = errors.New("document is encrypted and password is required")
)

type MergeResult struct {
	OutputFile    string `json:"output_file"`
	PageCount     int    `json:"page_count"`
	FileSizeBytes int64  `json:"file_size_bytes"`
}

type OptimizeResult struct {
	OriginalSizeBytes int64   `json:"original_size_bytes"`
	OptimizedSizeBytes int64  `json:"optimized_size_bytes"`
	ReductionPercent  float64 `json:"reduction_percent"`
	OutputFile        string  `json:"output_file"`
}

type CompressResult struct {
	OriginalSizeBytes  int64   `json:"original_size_bytes"`
	CompressedSizeBytes int64  `json:"compressed_size_bytes"`
	ReductionPercent   float64 `json:"reduction_percent"`
	OutputFile         string  `json:"output_file"`
}

type PdfInspectionResult struct {
	FileName      string `json:"file_name"`
	FileSizeBytes int64  `json:"file_size_bytes"`
	PageCount     int    `json:"page_count"`
	Version       string `json:"version"`
	Encrypted     bool   `json:"encrypted"`
}

// PdfProcessingService orchestrates local-first PDF manipulation using pdfcpu.
type PdfProcessingService struct {
	config *model.Configuration
}

// NewPdfProcessingService creates a new PDF processing service.
func NewPdfProcessingService() *PdfProcessingService {
	conf := model.NewDefaultConfiguration()
	return &PdfProcessingService{
		config: conf,
	}
}

// Inspect reads metadata and page count from a PDF file.
func (s *PdfProcessingService) Inspect(ctx context.Context, filePath string) (*PdfInspectionResult, error) {
	fi, err := os.Stat(filePath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrFileNotFound
		}
		return nil, fmt.Errorf("cannot stat file: %w", err)
	}

	pageCount, err := api.PageCountFile(ctx, filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to count pages: %w", err)
	}

	versionStr := "unknown"
	if f, err := os.Open(filePath); err == nil {
		header := make([]byte, 32)
		if n, _ := f.Read(header); n > 0 {
			str := string(header[:n])
			if strings.HasPrefix(str, "%PDF-") {
				parts := strings.Split(strings.TrimSpace(str), "\n")
				if len(parts) > 0 {
					versionStr = strings.TrimPrefix(parts[0], "%PDF-")
				}
			}
		}
		f.Close()
	}

	return &PdfInspectionResult{
		FileName:      filepath.Base(filePath),
		FileSizeBytes: fi.Size(),
		PageCount:     pageCount,
		Version:       versionStr,
		Encrypted:     false,
	}, nil
}

// Merge concatenates multiple PDF files into an output file.
func (s *PdfProcessingService) Merge(ctx context.Context, inFiles []string, outFile string) (*MergeResult, error) {
	if len(inFiles) < 2 {
		return nil, ErrInsufficientFiles
	}

	for _, file := range inFiles {
		if _, err := os.Stat(file); err != nil {
			if os.IsNotExist(err) {
				return nil, fmt.Errorf("%w: %s", ErrFileNotFound, file)
			}
			return nil, err
		}
	}

	if err := os.MkdirAll(filepath.Dir(outFile), 0755); err != nil {
		return nil, fmt.Errorf("failed to create output directory: %w", err)
	}

	// api.MergeCreateFile merges inFiles into outFile
	if err := api.MergeCreateFile(ctx, inFiles, outFile, false, s.config); err != nil {
		return nil, fmt.Errorf("pdfcpu merge failed: %w", err)
	}

	fi, err := os.Stat(outFile)
	if err != nil {
		return nil, fmt.Errorf("failed to stat merged file: %w", err)
	}

	pageCount, _ := api.PageCountFile(ctx, outFile)

	return &MergeResult{
		OutputFile:    outFile,
		PageCount:     pageCount,
		FileSizeBytes: fi.Size(),
	}, nil
}

// Split divides a PDF into chunks of span pages.
func (s *PdfProcessingService) Split(ctx context.Context, inFile string, outDir string, span int) ([]string, error) {
	if span <= 0 {
		span = 1
	}

	if _, err := os.Stat(inFile); err != nil {
		if os.IsNotExist(err) {
			return nil, ErrFileNotFound
		}
		return nil, err
	}

	if err := os.MkdirAll(outDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create output directory: %w", err)
	}

	if err := api.SplitFile(ctx, inFile, outDir, span, s.config); err != nil {
		return nil, fmt.Errorf("pdfcpu split failed: %w", err)
	}

	// Collect generated files in outDir
	entries, err := os.ReadDir(outDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read output directory: %w", err)
	}

	var outFiles []string
	baseName := strings.TrimSuffix(filepath.Base(inFile), filepath.Ext(inFile))
	for _, entry := range entries {
		if !entry.IsDir() && strings.HasPrefix(entry.Name(), baseName) && strings.HasSuffix(entry.Name(), ".pdf") {
			outFiles = append(outFiles, filepath.Join(outDir, entry.Name()))
		}
	}

	return outFiles, nil
}

// ExtractPages extracts specified page numbers from inFile into separate files in outDir.
func (s *PdfProcessingService) ExtractPages(ctx context.Context, inFile string, outDir string, pages []int) ([]string, error) {
	if len(pages) == 0 {
		return nil, ErrInvalidPageRange
	}

	total, err := api.PageCountFile(ctx, inFile)
	if err != nil {
		return nil, fmt.Errorf("cannot read page count: %w", err)
	}

	var pageStrs []string
	for _, p := range pages {
		if p < 1 || p > total {
			return nil, fmt.Errorf("%w: page %d out of bounds (1..%d)", ErrInvalidPageRange, p, total)
		}
		pageStrs = append(pageStrs, strconv.Itoa(p))
	}

	if err := os.MkdirAll(outDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create output directory: %w", err)
	}

	if err := api.ExtractPagesFile(ctx, inFile, outDir, pageStrs, s.config); err != nil {
		return nil, fmt.Errorf("pdfcpu extract failed: %w", err)
	}

	entries, err := os.ReadDir(outDir)
	if err != nil {
		return nil, err
	}

	var outFiles []string
	baseName := strings.TrimSuffix(filepath.Base(inFile), filepath.Ext(inFile))
	for _, entry := range entries {
		if !entry.IsDir() && strings.HasPrefix(entry.Name(), baseName) && strings.HasSuffix(entry.Name(), ".pdf") {
			outFiles = append(outFiles, filepath.Join(outDir, entry.Name()))
		}
	}

	return outFiles, nil
}

// Reorder rearranges the pages of inFile in the given orderedPages sequence.
func (s *PdfProcessingService) Reorder(ctx context.Context, inFile string, outFile string, orderedPages []int) error {
	total, err := api.PageCountFile(ctx, inFile)
	if err != nil {
		return fmt.Errorf("cannot read page count: %w", err)
	}

	if len(orderedPages) != total {
		return fmt.Errorf("%w: expected %d pages, got %d", ErrDuplicateReorderPages, total, len(orderedPages))
	}

	seen := make(map[int]bool)
	var pageStrs []string
	for _, p := range orderedPages {
		if p < 1 || p > total {
			return fmt.Errorf("%w: page %d out of bounds (1..%d)", ErrInvalidPageRange, p, total)
		}
		if seen[p] {
			return fmt.Errorf("%w: page %d is duplicated", ErrDuplicateReorderPages, p)
		}
		seen[p] = true
		pageStrs = append(pageStrs, strconv.Itoa(p))
	}

	if err := os.MkdirAll(filepath.Dir(outFile), 0755); err != nil {
		return fmt.Errorf("failed to create output dir: %w", err)
	}

	// TrimFile extracts and orders pages as specified in pageStrs
	if err := api.TrimFile(ctx, inFile, outFile, pageStrs, s.config); err != nil {
		return fmt.Errorf("pdfcpu reorder (trim) failed: %w", err)
	}

	return nil
}

// Rotate rotates selected pages (or all if pages is empty) by 90, 180, or 270 degrees.
func (s *PdfProcessingService) Rotate(ctx context.Context, inFile string, outFile string, rotation int, pages []int) error {
	if rotation != 90 && rotation != 180 && rotation != 270 {
		return ErrInvalidRotation
	}

	if _, err := os.Stat(inFile); err != nil {
		if os.IsNotExist(err) {
			return ErrFileNotFound
		}
		return err
	}

	total, err := api.PageCountFile(ctx, inFile)
	if err != nil {
		return fmt.Errorf("cannot read page count: %w", err)
	}

	var pageStrs []string
	for _, p := range pages {
		if p < 1 || p > total {
			return fmt.Errorf("%w: page %d out of bounds", ErrInvalidPageRange, p)
		}
		pageStrs = append(pageStrs, strconv.Itoa(p))
	}

	if err := os.MkdirAll(filepath.Dir(outFile), 0755); err != nil {
		return fmt.Errorf("failed to create output dir: %w", err)
	}

	if err := api.RotateFile(ctx, inFile, outFile, rotation, pageStrs, s.config); err != nil {
		return fmt.Errorf("pdfcpu rotate failed: %w", err)
	}

	return nil
}

// Optimize removes redundant objects and compacts the cross-reference table.
func (s *PdfProcessingService) Optimize(ctx context.Context, inFile string, outFile string) (*OptimizeResult, error) {
	fi, err := os.Stat(inFile)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, ErrFileNotFound
		}
		return nil, err
	}
	originalSize := fi.Size()

	if err := os.MkdirAll(filepath.Dir(outFile), 0755); err != nil {
		return nil, fmt.Errorf("failed to create output dir: %w", err)
	}

	if err := api.OptimizeFile(ctx, inFile, outFile, s.config, nil); err != nil {
		return nil, fmt.Errorf("pdfcpu optimize failed: %w", err)
	}

	fiOut, err := os.Stat(outFile)
	if err != nil {
		return nil, fmt.Errorf("failed to stat optimized file: %w", err)
	}
	optimizedSize := fiOut.Size()

	reduction := 0.0
	if originalSize > 0 {
		reduction = float64(originalSize-optimizedSize) / float64(originalSize) * 100.0
	}

	return &OptimizeResult{
		OriginalSizeBytes:  originalSize,
		OptimizedSizeBytes: optimizedSize,
		ReductionPercent:   reduction,
		OutputFile:         outFile,
	}, nil
}

// Compress performs lossless stream compression and object deduplication.
func (s *PdfProcessingService) Compress(ctx context.Context, inFile string, outFile string) (*CompressResult, error) {
	// In pdfcpu, optimization with default config reapplies Flate encoding to all uncompressed or suboptimal streams
	optResult, err := s.Optimize(ctx, inFile, outFile)
	if err != nil {
		return nil, err
	}

	return &CompressResult{
		OriginalSizeBytes:   optResult.OriginalSizeBytes,
		CompressedSizeBytes: optResult.OptimizedSizeBytes,
		ReductionPercent:    optResult.ReductionPercent,
		OutputFile:          optResult.OutputFile,
	}, nil
}
