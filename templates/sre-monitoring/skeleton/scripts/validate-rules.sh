#!/bin/bash
# Validate Prometheus alerting rules
# Generated for: ${{ values.name }}

set -e

ALERTS_DIR="${ALERTS_DIR:-./alerts}"
PROMTOOL="${PROMTOOL:-promtool}"

echo "Validating Prometheus alerting rules..."

# Check if promtool is available
if ! command -v "$PROMTOOL" &> /dev/null; then
    echo "Warning: promtool not found, downloading..."
    
    # Detect OS
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
    esac
    
    PROM_VERSION="2.48.0"
    PROM_URL="https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.${OS}-${ARCH}.tar.gz"
    
    curl -sL "$PROM_URL" | tar xz --strip-components=1 -C /tmp prometheus-${PROM_VERSION}.${OS}-${ARCH}/promtool
    PROMTOOL="/tmp/promtool"
fi

# Validate each rules file
errors=0
for rules_file in "$ALERTS_DIR"/*.yaml "$ALERTS_DIR"/*.yml; do
    if [ -f "$rules_file" ]; then
        echo "Checking: $rules_file"
        if $PROMTOOL check rules "$rules_file"; then
            echo "  Valid"
        else
            echo "  Invalid"
            errors=$((errors + 1))
        fi
    fi
done

# Summary
echo ""
if [ $errors -eq 0 ]; then
    echo "All rules are valid!"
    exit 0
else
    echo "Found $errors invalid rule file(s)"
    exit 1
fi
