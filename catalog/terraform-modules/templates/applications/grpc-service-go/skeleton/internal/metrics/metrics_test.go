package metrics

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
)

func TestHandlerServesSeriesOfRegisteredMethods(t *testing.T) {
	m := New()
	srv := grpc.NewServer(grpc.ChainUnaryInterceptor(m.UnaryInterceptor()), grpc.ChainStreamInterceptor(m.StreamInterceptor()))
	healthpb.RegisterHealthServer(srv, health.NewServer())
	m.Initialize(srv)

	rec := httptest.NewRecorder()
	m.Handler().ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/metrics", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("GET /metrics = %d, want 200", rec.Code)
	}
	body := rec.Body.String()
	for _, want := range []string{
		`grpc_server_started_total{grpc_method="Check",grpc_service="grpc.health.v1.Health",grpc_type="unary"} 0`,
		"go_goroutines",
	} {
		if !strings.Contains(body, want) {
			t.Errorf("metrics output lacks %q", want)
		}
	}
}
