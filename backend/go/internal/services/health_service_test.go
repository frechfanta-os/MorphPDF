package services

import "testing"

func TestHealthServiceCheck(t *testing.T) {
	svc := NewHealthService("1.0.0")
	status := svc.Check()

	if status.Status != "ok" {
		t.Errorf("expected status 'ok', got '%s'", status.Status)
	}
	if status.Service != "morphpdf" {
		t.Errorf("expected service 'morphpdf', got '%s'", status.Service)
	}
	if status.Version != "1.0.0" {
		t.Errorf("expected version '1.0.0', got '%s'", status.Version)
	}
}
