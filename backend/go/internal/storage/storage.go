package storage

import (
	"errors"
	"io"
	"os"
	"path/filepath"
)

var (
	// ErrFileNotFound indicates the requested file does not exist.
	ErrFileNotFound = errors.New("file not found")
)

// StorageService manages local file storage paths and operations.
type StorageService interface {
	SaveTemp(name string, r io.Reader) (string, error)
	GetTemp(name string) (io.ReadCloser, error)
	DeleteTemp(name string) error
	GetExportPath(name string) string
	GetCachePath(name string) string
	GetOcrTempPath(name string) string
}

// LocalStorageService implements StorageService using local filesystem directories.
type LocalStorageService struct {
	basePath string
}

// NewLocalStorageService initializes storage subdirectories.
func NewLocalStorageService(basePath string) (*LocalStorageService, error) {
	dirs := []string{
		filepath.Join(basePath, "temp"),
		filepath.Join(basePath, "recents"),
		filepath.Join(basePath, "exports"),
		filepath.Join(basePath, "cache"),
		filepath.Join(basePath, "ocr_temp"),
	}

	for _, d := range dirs {
		if err := os.MkdirAll(d, 0755); err != nil {
			return nil, err
		}
	}

	return &LocalStorageService{basePath: basePath}, nil
}

func (s *LocalStorageService) SaveTemp(name string, r io.Reader) (string, error) {
	dstPath := filepath.Join(s.basePath, "temp", name)
	f, err := os.Create(dstPath)
	if err != nil {
		return "", err
	}
	defer f.Close()

	if _, err := io.Copy(f, r); err != nil {
		return "", err
	}
	return dstPath, nil
}

func (s *LocalStorageService) GetTemp(name string) (io.ReadCloser, error) {
	filePath := filepath.Join(s.basePath, "temp", name)
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		return nil, ErrFileNotFound
	}
	return os.Open(filePath)
}

func (s *LocalStorageService) DeleteTemp(name string) error {
	filePath := filepath.Join(s.basePath, "temp", name)
	return os.Remove(filePath)
}

func (s *LocalStorageService) GetExportPath(name string) string {
	return filepath.Join(s.basePath, "exports", name)
}

func (s *LocalStorageService) GetCachePath(name string) string {
	return filepath.Join(s.basePath, "cache", name)
}

func (s *LocalStorageService) GetOcrTempPath(name string) string {
	return filepath.Join(s.basePath, "ocr_temp", name)
}
