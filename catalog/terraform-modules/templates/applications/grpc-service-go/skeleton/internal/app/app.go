// Package app assembles the gRPC server from its parts.
package app

import (
	"context"
{% if values.enableMetrics %}
	"errors"
{% endif %}
{% if values.enableAuth or values.enableTracing %}
	"fmt"
{% endif %}
	"log/slog"
	"net"
{% if values.enableMetrics %}
	"net/http"
{% endif %}
	"os"
	"time"

{% if values.enableTracing %}
	"go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc"
{% endif %}
	"google.golang.org/grpc"
{% if values.enableHealthChecks %}
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
{% endif %}
	"google.golang.org/grpc/reflection"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
{% if values.enableInterceptors %}
	"${{ values.modulePath }}/internal/interceptors"
{% endif %}
{% if values.enableMetrics %}
	"${{ values.modulePath }}/internal/metrics"
{% endif %}
	"${{ values.modulePath }}/internal/server"
{% if values.enableAuth %}
	"${{ values.modulePath }}/internal/tlsconfig"
{% endif %}
{% if values.enableTracing %}
	"${{ values.modulePath }}/internal/tracing"
{% endif %}
	"${{ values.modulePath }}/internal/version"
)

// shutdownTimeout is how long in-flight calls get to finish after a stop signal.
const shutdownTimeout = 15 * time.Second

// Options configure the server. OptionsFromEnv fills them from the environment.
type Options struct {
	// Addr is the address the gRPC server listens on.
	Addr string
	// Reflection exposes the service schema to tools such as grpcurl.
	Reflection bool
{% if values.enableInterceptors %}
	// AuthToken, when set, is the bearer token every call must present.
	AuthToken string
{% endif %}
{% if values.enableAuth %}
	// TLS names the certificate files. The server uses TLS when a certificate
	// and key are set.
	TLS tlsconfig.Options
{% endif %}
{% if values.enableMetrics %}
	// MetricsAddr is the address of the Prometheus endpoint. Empty turns it off.
	MetricsAddr string
{% endif %}
}

// OptionsFromEnv reads the options from environment variables.
func OptionsFromEnv() Options {
	opts := Options{Addr: envOr("GRPC_ADDR", ":50051")}
	opts.Reflection = envOr("GRPC_REFLECTION", "true") == "true"
{% if values.enableInterceptors %}
	opts.AuthToken = os.Getenv("AUTH_TOKEN")
{% endif %}
{% if values.enableAuth %}
	opts.TLS = tlsconfig.FromEnv()
{% endif %}
{% if values.enableMetrics %}
	opts.MetricsAddr = envOr("METRICS_ADDR", ":9090")
{% endif %}
	return opts
}

func envOr(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

// App is a configured gRPC server.
type App struct {
	opts   Options
	logger *slog.Logger
	server *grpc.Server
{% if values.enableMetrics %}

	// metrics holds the Prometheus series served on Options.MetricsAddr.
	metrics *metrics.Metrics
{% endif %}
}

// New builds the server and registers its services.
func New(opts Options, logger *slog.Logger) (*App, error) {
	a := &App{opts: opts, logger: logger}
	var serverOpts []grpc.ServerOption
{% if values.enableAuth %}
	if opts.TLS.Enabled() {
		creds, err := tlsconfig.ServerCredentials(opts.TLS)
		if err != nil {
			return nil, fmt.Errorf("load TLS credentials: %w", err)
		}
		serverOpts = append(serverOpts, grpc.Creds(creds))
	} else {
		logger.Warn("TLS_CERT_FILE and TLS_KEY_FILE are not set: serving without TLS")
	}
{% endif %}
{% if values.enableTracing %}
	serverOpts = append(serverOpts, grpc.StatsHandler(otelgrpc.NewServerHandler()))
{% endif %}
{% if values.enableInterceptors or values.enableMetrics %}

	// The first interceptor is the outermost: it sees every call first and
	// every result last.
	var unary []grpc.UnaryServerInterceptor
	var stream []grpc.StreamServerInterceptor
{% endif %}
{% if values.enableMetrics %}
	a.metrics = metrics.New()
	unary = append(unary, a.metrics.UnaryInterceptor())
	stream = append(stream, a.metrics.StreamInterceptor())
{% endif %}
{% if values.enableInterceptors %}
	unary = append(unary, interceptors.UnaryLogging(logger), interceptors.UnaryRecovery(logger))
	stream = append(stream, interceptors.StreamLogging(logger), interceptors.StreamRecovery(logger))
	if opts.AuthToken != "" {
		unary = append(unary, interceptors.UnaryAuth(opts.AuthToken))
		stream = append(stream, interceptors.StreamAuth(opts.AuthToken))
	}
{% endif %}
{% if values.enableInterceptors or values.enableMetrics %}
	serverOpts = append(serverOpts, grpc.ChainUnaryInterceptor(unary...), grpc.ChainStreamInterceptor(stream...))
{% endif %}

	a.server = grpc.NewServer(serverOpts...)
	pb.Register${{ values.serviceType }}Server(a.server, server.New(server.NewStore()))
{% if values.enableHealthChecks %}
	healthServer := health.NewServer()
	healthServer.SetServingStatus(pb.${{ values.serviceType }}_ServiceDesc.ServiceName, healthpb.HealthCheckResponse_SERVING)
	healthpb.RegisterHealthServer(a.server, healthServer)
{% endif %}
	if opts.Reflection {
		reflection.Register(a.server)
	}
{% if values.enableMetrics %}
	a.metrics.Initialize(a.server)
{% endif %}
	return a, nil
}

// Serve handles calls on lis until ctx is cancelled, then lets in-flight calls
// finish before it returns.
func (a *App) Serve(ctx context.Context, lis net.Listener) error {
{% if values.enableTracing %}
	shutdownTracing, err := tracing.Setup(ctx, version.Name, version.Version)
	if err != nil {
		return fmt.Errorf("set up tracing: %w", err)
	}
	defer func() {
		flushCtx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
		defer cancel()
		if err := shutdownTracing(flushCtx); err != nil {
			a.logger.Warn("flush traces", "error", err)
		}
	}()

{% endif %}
{% if values.enableMetrics %}
	if a.opts.MetricsAddr != "" {
		metricsServer := &http.Server{
			Addr:              a.opts.MetricsAddr,
			Handler:           a.metrics.Handler(),
			ReadHeaderTimeout: 5 * time.Second,
		}
		go func() {
			if err := metricsServer.ListenAndServe(); !errors.Is(err, http.ErrServerClosed) {
				a.logger.Error("metrics server stopped", "error", err)
			}
		}()
		defer func() { _ = metricsServer.Close() }()
	}

{% endif %}
	stopped := make(chan struct{})
	go func() {
		defer close(stopped)
		<-ctx.Done()
		a.logger.Info("shutting down")
		a.stop()
	}()

	a.logger.Info("serving gRPC", "addr", lis.Addr().String(), "service", version.Name, "version", version.Version)
	if err := a.server.Serve(lis); err != nil {
		return err
	}
	<-stopped
	return nil
}

// stop waits for in-flight calls, and cuts them off after shutdownTimeout.
func (a *App) stop() {
	done := make(chan struct{})
	go func() {
		a.server.GracefulStop()
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(shutdownTimeout):
		a.server.Stop()
	}
}
