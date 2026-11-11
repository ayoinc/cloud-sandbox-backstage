// Command server runs the HTTP service.
package main

import (
	"context"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/internal/config"
	"github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/internal/httpserver"
	"github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/internal/store"
	"github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/internal/telemetry"
)

// version is set at build time with -ldflags "-X main.version=...".
var version = "dev"

func main() {
	if err := run(); err != nil {
		slog.Error("service stopped", slog.Any("error", err))
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load(os.Getenv)
	if err != nil {
		return fmt.Errorf("load configuration: %w", err)
	}

	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: cfg.LogLevel})).
		With(slog.String("service", config.ServiceName), slog.String("version", version))
	slog.SetDefault(logger)

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	shutdownTelemetry, err := telemetry.Setup(ctx, config.ServiceName, version)
	if err != nil {
		return fmt.Errorf("set up telemetry: %w", err)
	}

	app := httpserver.New(httpserver.Options{
		Logger:      logger,
		Service:     config.ServiceName,
		Version:     version,
		Environment: cfg.Environment,
		Store:       store.NewMemory(),
	})

	srv := &http.Server{
		Addr:              net.JoinHostPort("", strconv.Itoa(cfg.Port)),
		Handler:           app.Handler(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	serveErr := make(chan error, 1)
	go func() {
		logger.Info("listening", slog.String("addr", srv.Addr), slog.String("environment", cfg.Environment))
		serveErr <- srv.ListenAndServe()
	}()

	select {
	case err := <-serveErr:
		return fmt.Errorf("serve: %w", err)
	case <-ctx.Done():
	}

	// A second signal ends the process immediately.
	stop()
	logger.Info("shutting down", slog.Duration("timeout", cfg.ShutdownTimeout))
	app.SetReady(false)

	shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		return fmt.Errorf("shut down server: %w", err)
	}
	if err := shutdownTelemetry(shutdownCtx); err != nil {
		return fmt.Errorf("shut down telemetry: %w", err)
	}
	logger.Info("stopped")
	return nil
}
