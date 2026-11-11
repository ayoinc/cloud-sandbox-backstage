// Package metrics exposes Prometheus metrics for the gRPC server.
package metrics

import (
	"net/http"

	grpcprom "github.com/grpc-ecosystem/go-grpc-middleware/providers/prometheus"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/collectors"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"google.golang.org/grpc"
)

// Metrics counts and times the calls of a gRPC server, next to the usual Go
// runtime and process metrics.
type Metrics struct {
	registry *prometheus.Registry
	server   *grpcprom.ServerMetrics
}

// New returns Metrics with their own registry.
func New() *Metrics {
	server := grpcprom.NewServerMetrics(grpcprom.WithServerHandlingTimeHistogram())
	registry := prometheus.NewRegistry()
	registry.MustRegister(
		server,
		collectors.NewGoCollector(),
		collectors.NewProcessCollector(collectors.ProcessCollectorOpts{}),
	)
	return &Metrics{registry: registry, server: server}
}

// UnaryInterceptor records unary calls.
func (m *Metrics) UnaryInterceptor() grpc.UnaryServerInterceptor {
	return m.server.UnaryServerInterceptor()
}

// StreamInterceptor records streaming calls.
func (m *Metrics) StreamInterceptor() grpc.StreamServerInterceptor {
	return m.server.StreamServerInterceptor()
}

// Initialize creates the series of every method registered on srv with value
// zero, so dashboards and alerts see them before the first call.
func (m *Metrics) Initialize(srv *grpc.Server) {
	m.server.InitializeMetrics(srv)
}

// Handler serves the metrics in the Prometheus exposition format on /metrics.
func (m *Metrics) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.Handle("/metrics", promhttp.HandlerFor(m.registry, promhttp.HandlerOpts{Registry: m.registry}))
	return mux
}
