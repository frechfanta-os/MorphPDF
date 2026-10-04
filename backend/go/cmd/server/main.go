package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"morphpdf/backend/internal/ai"
	"morphpdf/backend/internal/config"
	appHTTP "morphpdf/backend/internal/http"
	"morphpdf/backend/internal/services"
)

func main() {
	cfg := config.Load()

	log.Printf("[MorphPDF Backend] Starting in %s mode...", cfg.Env)
	if cfg.IsAIConfigured() {
		log.Printf("[MorphPDF Backend] AI provider (OpenRouter) is configured with model: %s", cfg.OpenRouterModel)
	} else {
		log.Println("[MorphPDF Backend] Notice: OPENROUTER_API_KEY is not set. AI endpoints will return clean 503 errors.")
	}

	healthSvc := services.NewHealthService("1.0.0")

	// Initialize OpenRouter provider & AI service
	aiProvider := ai.NewOpenRouterProvider(cfg.OpenRouterBaseURL, cfg.OpenRouterAPIKey, nil)
	aiSvc := services.NewAIService(aiProvider, cfg.OpenRouterModel)

	router := appHTTP.NewRouter(healthSvc, aiSvc)

	addr := fmt.Sprintf("%s:%s", cfg.Host, cfg.Port)
	srv := &http.Server{
		Addr:         addr,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		log.Printf("[MorphPDF Backend] HTTP API server listening on http://%s", addr)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[MorphPDF Backend] Server listen error: %v", err)
		}
	}()

	// Graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)
	<-quit

	log.Println("[MorphPDF Backend] Shutting down gracefully...")
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("[MorphPDF Backend] Forced shutdown: %v", err)
	}

	log.Println("[MorphPDF Backend] Server exited.")
}
