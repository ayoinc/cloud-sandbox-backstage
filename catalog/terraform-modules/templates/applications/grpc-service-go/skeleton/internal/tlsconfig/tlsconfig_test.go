package tlsconfig

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"net"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/health"
	healthpb "google.golang.org/grpc/health/grpc_health_v1"
)

// serve starts a gRPC server with the credentials built from opts and returns
// its address.
func serve(t *testing.T, opts Options) string {
	t.Helper()
	creds, err := ServerCredentials(opts)
	if err != nil {
		t.Fatalf("ServerCredentials: %v", err)
	}
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	srv := grpc.NewServer(grpc.Creds(creds))
	healthpb.RegisterHealthServer(srv, health.NewServer())
	go func() { _ = srv.Serve(lis) }()
	t.Cleanup(srv.Stop)
	return lis.Addr().String()
}

// check calls the health service at addr with the given client TLS config.
func check(t *testing.T, addr string, config *tls.Config) error {
	t.Helper()
	conn, err := grpc.NewClient(addr, grpc.WithTransportCredentials(credentials.NewTLS(config)))
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer func() { _ = conn.Close() }()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	_, err = healthpb.NewHealthClient(conn).Check(ctx, &healthpb.HealthCheckRequest{})
	return err
}

func trust(ca *testCA) *x509.CertPool {
	pool := x509.NewCertPool()
	pool.AddCert(ca.cert)
	return pool
}

func TestEnabledNeedsCertificateAndKey(t *testing.T) {
	if (Options{}).Enabled() {
		t.Error("Enabled() = true without files")
	}
	if (Options{CertFile: "server.crt"}).Enabled() {
		t.Error("Enabled() = true without a key")
	}
	if !(Options{CertFile: "server.crt", KeyFile: "server.key"}).Enabled() {
		t.Error("Enabled() = false with a certificate and key")
	}
}

func TestFromEnvReadsFileNames(t *testing.T) {
	t.Setenv("TLS_CERT_FILE", "/tls/tls.crt")
	t.Setenv("TLS_KEY_FILE", "/tls/tls.key")

	opts := FromEnv()
	if opts.CertFile != "/tls/tls.crt" || opts.KeyFile != "/tls/tls.key" {
		t.Fatalf("FromEnv() = %+v", opts)
	}
}

func TestServerCredentialsServeTLS(t *testing.T) {
	ca := newTestCA(t)
	certFile, keyFile := ca.issue(t, "server", x509.ExtKeyUsageServerAuth)
	addr := serve(t, Options{CertFile: certFile, KeyFile: keyFile})

	if err := check(t, addr, &tls.Config{RootCAs: trust(ca)}); err != nil {
		t.Fatalf("call over TLS: %v", err)
	}
	if err := check(t, addr, &tls.Config{RootCAs: x509.NewCertPool()}); err == nil {
		t.Fatal("a client that does not trust the CA completed a call")
	}
}

func TestServerCredentialsRejectMissingFiles(t *testing.T) {
	if _, err := ServerCredentials(Options{CertFile: "missing.crt", KeyFile: "missing.key"}); err == nil {
		t.Fatal("ServerCredentials accepted files that do not exist")
	}
}
