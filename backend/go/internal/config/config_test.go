package config

import (
	"os"
	"testing"
)

func TestLoadDefaults(t *testing.T) {
	os.Unsetenv("MORPHPDF_ENV")
	os.Unsetenv("MORPHPDF_PORT")

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
}

func TestLoadCustomEnv(t *testing.T) {
	os.Setenv("MORPHPDF_ENV", "production")
	os.Setenv("MORPHPDF_PORT", "9090")
	defer func() {
		os.Unsetenv("MORPHPDF_ENV")
		os.Unsetenv("MORPHPDF_PORT")
	}()

	cfg := Load()
	if cfg.Env != "production" {
		t.Errorf("expected Env 'production', got %s", cfg.Env)
	}
	if cfg.Port != "9090" {
		t.Errorf("expected Port '9090', got %s", cfg.Port)
	}
}
