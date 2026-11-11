// Package httpserver serves the HTTP API.
package httpserver

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"
	"sync/atomic"
	"time"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/trace"

	"github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/internal/store"
)

// Options are the dependencies of the API.
type Options struct {
	Logger      *slog.Logger
	Service     string
	Version     string
	Environment string
	Store       store.Store
}

// App holds the routes and their dependencies.
type App struct {
	logger      *slog.Logger
	service     string
	version     string
	environment string
	store       store.Store
	ready       atomic.Bool
}

// New returns an App that reports itself ready.
func New(opts Options) *App {
	app := &App{
		logger:      opts.Logger,
		service:     opts.Service,
		version:     opts.Version,
		environment: opts.Environment,
		store:       opts.Store,
	}
	app.ready.Store(true)
	return app
}

// SetReady changes what the readiness probe reports. The service turns it off
// before shutting down so that load balancers stop sending requests.
func (a *App) SetReady(ready bool) {
	a.ready.Store(ready)
}

// Handler returns the routes wrapped in tracing, request logging and panic
// recovery.
func (a *App) Handler() http.Handler {
	handler := a.recoverPanics(a.routes())
	handler = a.logRequests(handler)
	return otelhttp.NewHandler(handler, "http.server",
		otelhttp.WithFilter(func(r *http.Request) bool { return !isProbe(r) }),
	)
}

func isProbe(r *http.Request) bool {
	return strings.HasPrefix(r.URL.Path, "/health")
}

// statusRecorder remembers the status code a handler wrote.
type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(status int) {
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

// Unwrap lets http.ResponseController reach the underlying writer.
func (r *statusRecorder) Unwrap() http.ResponseWriter {
	return r.ResponseWriter
}

func (a *App) logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		recorder := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(recorder, r)

		// Probes are called every few seconds; they are logged at debug level.
		level := slog.LevelInfo
		if isProbe(r) {
			level = slog.LevelDebug
		}
		attrs := []slog.Attr{
			slog.String("method", r.Method),
			slog.String("path", r.URL.Path),
			slog.Int("status", recorder.status),
			slog.Duration("duration", time.Since(start)),
		}
		if span := trace.SpanContextFromContext(r.Context()); span.IsValid() {
			attrs = append(attrs, slog.String("trace_id", span.TraceID().String()))
		}
		a.logger.LogAttrs(r.Context(), level, "request", attrs...)
	})
}

func (a *App) recoverPanics(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if recovered := recover(); recovered != nil {
				a.logger.ErrorContext(r.Context(), "panic in handler",
					slog.Any("panic", recovered), slog.String("path", r.URL.Path))
				a.writeError(w, r, http.StatusInternalServerError, "Internal Server Error")
			}
		}()
		next.ServeHTTP(w, r)
	})
}

func (a *App) writeJSON(w http.ResponseWriter, r *http.Request, status int, body any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		a.logger.WarnContext(r.Context(), "write response", slog.Any("error", err))
	}
}

func (a *App) writeError(w http.ResponseWriter, r *http.Request, status int, message string) {
	a.writeJSON(w, r, status, map[string]string{"error": message})
}
