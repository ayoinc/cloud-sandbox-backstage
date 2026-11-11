// Package tlsconfig builds the transport credentials of the gRPC server.
package tlsconfig

import (
	"crypto/tls"
{% if values.enableMTLS %}
	"crypto/x509"
	"errors"
	"fmt"
{% endif %}
	"os"

	"google.golang.org/grpc/credentials"
)

// Options name the PEM files the server loads.
type Options struct {
	// CertFile and KeyFile hold the server certificate and its private key.
	CertFile string
	KeyFile  string
{% if values.enableMTLS %}
	// ClientCAFile holds the CA that signs client certificates. When set,
	// every client must present a certificate signed by it (mutual TLS).
	ClientCAFile string
{% endif %}
}

// FromEnv reads the file names from the TLS_* environment variables.
func FromEnv() Options {
	opts := Options{CertFile: os.Getenv("TLS_CERT_FILE"), KeyFile: os.Getenv("TLS_KEY_FILE")}
{% if values.enableMTLS %}
	opts.ClientCAFile = os.Getenv("TLS_CLIENT_CA_FILE")
{% endif %}
	return opts
}

// Enabled reports whether a certificate and key are configured.
func (o Options) Enabled() bool {
	return o.CertFile != "" && o.KeyFile != ""
}

// ServerCredentials loads the files named in o.
func ServerCredentials(o Options) (credentials.TransportCredentials, error) {
	cert, err := tls.LoadX509KeyPair(o.CertFile, o.KeyFile)
	if err != nil {
		return nil, err
	}
	config := &tls.Config{Certificates: []tls.Certificate{cert}, MinVersion: tls.VersionTLS13}
{% if values.enableMTLS %}
	if o.ClientCAFile != "" {
		pem, err := os.ReadFile(o.ClientCAFile)
		if err != nil {
			return nil, fmt.Errorf("read client CA: %w", err)
		}
		pool := x509.NewCertPool()
		if !pool.AppendCertsFromPEM(pem) {
			return nil, errors.New("client CA file holds no PEM certificate")
		}
		config.ClientCAs = pool
		config.ClientAuth = tls.RequireAndVerifyClientCert
	}
{% endif %}
	return credentials.NewTLS(config), nil
}
