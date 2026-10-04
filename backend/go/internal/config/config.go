package config

import (
	"os"
)

// Config holds the application configuration loaded from environment variables.
type Config struct {
	Env              string
	Host             string
	Port             string
	OpenRouterAPIKey string
	OpenRouterBaseURL string
	StoragePath      string
	OcrEngine        string
	LogLevel         string
}

// Load reads configuration from environment variables with fallback defaults.
func Load() *Config {
	return &Config{
		Env:              getEnv("MORPHPDF_ENV", "development"),
		Host:             getEnv("MORPHPDF_HOST", "0.0.0.0"),
		Port:             getEnv("MORPHPDF_PORT", "8080"),
		OpenRouterAPIKey: getEnv("OPENROUTER_API_KEY", ""),
		OpenRouterBaseURL: getEnv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1"),
		StoragePath:      getEnv("STORAGE_PATH", "/tmp/morphpdf_storage"),
		OcrEngine:        getEnv("OCR_ENGINE", "mlkit"),
		LogLevel:         getEnv("LOG_LEVEL", "info"),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}
