package services_test

import (
	"context"
	"os"
	"path/filepath"
	"testing"

	"morphpdf/backend/internal/services"
)

func TestPdfProcessingService_Merge(t *testing.T) {
	svc := services.NewPdfProcessingService()
	ctx := context.Background()

	file1 := "../../testdata/doc_single_page.pdf"
	file2 := "../../testdata/doc_multipage.pdf" // 3 pages

	tmpDir := t.TempDir()
	outFile := filepath.Join(tmpDir, "merged.pdf")

	result, err := svc.Merge(ctx, []string{file1, file2}, outFile)
	if err != nil {
		t.Fatalf("unexpected merge error: %v", err)
	}

	if result.PageCount != 4 {
		t.Errorf("expected 4 pages, got %d", result.PageCount)
	}
	if result.FileSizeBytes <= 0 {
		t.Errorf("expected positive file size, got %d", result.FileSizeBytes)
	}

	// Insufficient files error
	_, err = svc.Merge(ctx, []string{file1}, outFile)
	if err != services.ErrInsufficientFiles {
		t.Errorf("expected ErrInsufficientFiles, got %v", err)
	}
}

func TestPdfProcessingService_Split(t *testing.T) {
	svc := services.NewPdfProcessingService()
	ctx := context.Background()

	file := "../../testdata/doc_multipage.pdf" // 3 pages
	tmpDir := t.TempDir()

	outFiles, err := svc.Split(ctx, file, tmpDir, 1)
	if err != nil {
		t.Fatalf("unexpected split error: %v", err)
	}

	if len(outFiles) != 3 {
		t.Errorf("expected 3 split files, got %d", len(outFiles))
	}
}

func TestPdfProcessingService_ExtractPages(t *testing.T) {
	svc := services.NewPdfProcessingService()
	ctx := context.Background()

	file := "../../testdata/doc_multipage.pdf" // 3 pages
	tmpDir := t.TempDir()

	outFiles, err := svc.ExtractPages(ctx, file, tmpDir, []int{1, 3})
	if err != nil {
		t.Fatalf("unexpected extract error: %v", err)
	}

	if len(outFiles) != 2 {
		t.Errorf("expected 2 extracted files, got %d", len(outFiles))
	}

	// Invalid page
	_, err = svc.ExtractPages(ctx, file, tmpDir, []int{99})
	if err == nil {
		t.Errorf("expected error for page out of bounds, got nil")
	}
}

func TestPdfProcessingService_Reorder(t *testing.T) {
	svc := services.NewPdfProcessingService()
	ctx := context.Background()

	file := "../../testdata/doc_multipage.pdf" // 3 pages
	tmpDir := t.TempDir()
	outFile := filepath.Join(tmpDir, "reordered.pdf")

	// Reverse order: 3, 2, 1
	err := svc.Reorder(ctx, file, outFile, []int{3, 2, 1})
	if err != nil {
		t.Fatalf("unexpected reorder error: %v", err)
	}

	info, err := svc.Inspect(ctx, outFile)
	if err != nil {
		t.Fatalf("cannot inspect reordered file: %v", err)
	}
	if info.PageCount != 3 {
		t.Errorf("expected 3 pages, got %d", info.PageCount)
	}

	// Duplicate page error
	err = svc.Reorder(ctx, file, outFile, []int{1, 1, 3})
	if err == nil {
		t.Errorf("expected error on duplicate page, got nil")
	}
}

func TestPdfProcessingService_Rotate(t *testing.T) {
	svc := services.NewPdfProcessingService()
	ctx := context.Background()

	file := "../../testdata/doc_single_page.pdf"
	tmpDir := t.TempDir()
	outFile := filepath.Join(tmpDir, "rotated.pdf")

	err := svc.Rotate(ctx, file, outFile, 90, []int{1})
	if err != nil {
		t.Fatalf("unexpected rotate error: %v", err)
	}

	if _, err := os.Stat(outFile); err != nil {
		t.Errorf("output file does not exist: %v", err)
	}

	// Invalid rotation
	err = svc.Rotate(ctx, file, outFile, 45, []int{1})
	if err != services.ErrInvalidRotation {
		t.Errorf("expected ErrInvalidRotation, got %v", err)
	}
}

func TestPdfProcessingService_OptimizeAndCompress(t *testing.T) {
	svc := services.NewPdfProcessingService()
	ctx := context.Background()

	file := "../../testdata/doc_multipage.pdf"
	tmpDir := t.TempDir()
	outFileOpt := filepath.Join(tmpDir, "optimized.pdf")
	outFileComp := filepath.Join(tmpDir, "compressed.pdf")

	opt, err := svc.Optimize(ctx, file, outFileOpt)
	if err != nil {
		t.Fatalf("unexpected optimize error: %v", err)
	}
	if opt.OptimizedSizeBytes <= 0 {
		t.Errorf("expected positive optimized size, got %d", opt.OptimizedSizeBytes)
	}

	comp, err := svc.Compress(ctx, file, outFileComp)
	if err != nil {
		t.Fatalf("unexpected compress error: %v", err)
	}
	if comp.CompressedSizeBytes <= 0 {
		t.Errorf("expected positive compressed size, got %d", comp.CompressedSizeBytes)
	}
}

func TestPdfProcessingService_Inspect(t *testing.T) {
	svc := services.NewPdfProcessingService()
	ctx := context.Background()

	file := "../../testdata/doc_single_page.pdf"
	info, err := svc.Inspect(ctx, file)
	if err != nil {
		t.Fatalf("unexpected inspect error: %v", err)
	}

	if info.FileName != "doc_single_page.pdf" {
		t.Errorf("expected doc_single_page.pdf, got %s", info.FileName)
	}
	if info.PageCount != 1 {
		t.Errorf("expected 1 page, got %d", info.PageCount)
	}
}
