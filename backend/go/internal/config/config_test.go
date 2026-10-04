package config

import (
	"os"
	"testing"
)

func TestLoadDefaults(t *testing.T) {
	os.Unsetenv("MORPHPDF_ENV")
	os.Unsetenv("MORPHPDF_PORT")
	os.Unsetenv("OPENROUTER_API_KEY")
	os.Unsetenv("OPENROUTER_MODEL")

	cfg := Load()
	if cfg.Env != "development" {
		t.Errorf("expected default Env 'development', got %s", cfg.Env)
	}
	if cfg.Port != "8080" {
		t.Errorf("expected default Port '8080', got %s", cfg.Port)
	}
	if cfg.Host != "0.0.0.0" {
		t.Errorf("expected default Host '0.0.0.0', got %s", cfg.Host)
	}
	if cfg.OpenRouterModel != "meta-llama/llama-3.3-70b-instruct:free" {
		t.Errorf("expected default OpenRouterModel, got %s", cfg.OpenRouterModel)
	}
	if cfg.IsAIConfigured() {
		t.Errorf("expected IsAIConfigured() to be false when key is unset")
	}
}

func TestLoadCustomEnv(t *testing.T) {
	os.Setenv("MORPHPDF_ENV", "production")
	os.Setenv("MORPHPDF_PORT", "9090")
	os.Setenv("OPENROUTER_API_KEY", "dummy-key-for-test")
	os.Setenv("OPENROUTER_MODEL", "custom-model")
	defer func() {
		os.Unsetenv("MORPHPDF_ENV")
		os.Unsetenv("MORPHPDF_PORT")
		os.Unsetenv("OPENROUTER_API_KEY")
		os.Unsetenv("OPENROUTER_MODEL")
	}()

	cfg := Load()
	if cfg.Env != "production" {
		t.Errorf("expected Env 'production', got %s", cfg.Env)
	}
	if cfg.Port != "9090" {
		t.Errorf("expected Port '9090', got %s", cfg.Port)
	}
	if !cfg.IsAIConfigured() {
		t.Errorf("expected IsAIConfigured() to be true when key is set")
	}
	if cfg.OpenRouterModel != "custom-model" {
		t.Errorf("expected OpenRouterModel 'custom-model', got %s", cfg.OpenRouterModel)
	}
}
