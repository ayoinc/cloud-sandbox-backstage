package tlsconfig

import (
	"crypto/tls"
	"crypto/x509"
	"os"
	"path/filepath"
	"testing"
)

func TestClientCARequiresClientCertificate(t *testing.T) {
	ca := newTestCA(t)
	certFile, keyFile := ca.issue(t, "server", x509.ExtKeyUsageServerAuth)
	addr := serve(t, Options{CertFile: certFile, KeyFile: keyFile, ClientCAFile: ca.certFile})

	if err := check(t, addr, &tls.Config{RootCAs: trust(ca)}); err == nil {
		t.Fatal("a client without a certificate completed a call")
	}

	clientCertFile, clientKeyFile := ca.issue(t, "client", x509.ExtKeyUsageClientAuth)
	clientCert, err := tls.LoadX509KeyPair(clientCertFile, clientKeyFile)
	if err != nil {
		t.Fatalf("load client certificate: %v", err)
	}
	if err := check(t, addr, &tls.Config{RootCAs: trust(ca), Certificates: []tls.Certificate{clientCert}}); err != nil {
		t.Fatalf("call with a client certificate: %v", err)
	}
}

func TestClientCARejectsCertificateFromAnotherCA(t *testing.T) {
	ca := newTestCA(t)
	certFile, keyFile := ca.issue(t, "server", x509.ExtKeyUsageServerAuth)
	addr := serve(t, Options{CertFile: certFile, KeyFile: keyFile, ClientCAFile: ca.certFile})

	otherCertFile, otherKeyFile := newTestCA(t).issue(t, "client", x509.ExtKeyUsageClientAuth)
	otherCert, err := tls.LoadX509KeyPair(otherCertFile, otherKeyFile)
	if err != nil {
		t.Fatalf("load client certificate: %v", err)
	}
	if err := check(t, addr, &tls.Config{RootCAs: trust(ca), Certificates: []tls.Certificate{otherCert}}); err == nil {
		t.Fatal("a client certificate from another CA was accepted")
	}
}

func TestClientCAFileMustHoldCertificate(t *testing.T) {
	ca := newTestCA(t)
	certFile, keyFile := ca.issue(t, "server", x509.ExtKeyUsageServerAuth)
	empty := filepath.Join(t.TempDir(), "empty.crt")
	if err := os.WriteFile(empty, nil, 0o600); err != nil {
		t.Fatalf("write: %v", err)
	}

	if _, err := ServerCredentials(Options{CertFile: certFile, KeyFile: keyFile, ClientCAFile: empty}); err == nil {
		t.Fatal("ServerCredentials accepted a client CA file without a certificate")
	}
}
