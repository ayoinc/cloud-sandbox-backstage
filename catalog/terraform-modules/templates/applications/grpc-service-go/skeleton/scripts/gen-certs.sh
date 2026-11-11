#!/usr/bin/env bash
# Writes a development CA and the certificates signed by it to ./certs (or the
# directory given as the first argument). For local use only: production
# certificates come from your PKI or cert-manager.
set -euo pipefail

dir="${1:-certs}"
mkdir -p "$dir"
cd "$dir"

new_key() { openssl ecparam -name prime256v1 -genkey -noout -out "$1"; }

# issue <name> <extended key usage> <subject alternative names>
issue() {
  new_key "$1.key"
  openssl req -new -key "$1.key" -subj "/CN=$1" -out "$1.csr"
  printf 'extendedKeyUsage=%s\nsubjectAltName=%s\n' "$2" "$3" > "$1.ext"
  openssl x509 -req -in "$1.csr" -CA ca.crt -CAkey ca.key -CAcreateserial \
    -days 365 -sha256 -extfile "$1.ext" -out "$1.crt" 2>/dev/null
  rm -f "$1.csr" "$1.ext"
}

new_key ca.key
openssl req -x509 -new -key ca.key -sha256 -days 365 -subj "/CN=${{ values.serviceName }} development CA" -out ca.crt

issue server serverAuth "DNS:localhost,IP:127.0.0.1"
{% if values.enableMTLS %}
issue client clientAuth "DNS:client"
{% endif %}

echo "Certificates written to $dir"
