package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
)

func get(t *testing.T, handler http.Handler, path string) *httptest.ResponseRecorder {
	t.Helper()
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, path, nil))
	return recorder
}

func decode(t *testing.T, recorder *httptest.ResponseRecorder) map[string]string {
	t.Helper()
	var body map[string]string
	if err := json.NewDecoder(recorder.Body).Decode(&body); err != nil {
		t.Fatalf("decoding the response: %v", err)
	}
	return body
}

func TestRootReturnsTheServiceNameAndEnvironment(t *testing.T) {
	response := get(t, newHandler(), "/")
	body := decode(t, response)
	if response.Code != http.StatusOK || body["service"] != service || body["environment"] != environment() {
		t.Fatalf("GET / = %d %v", response.Code, body)
	}
}

func TestHealthReportsHealthy(t *testing.T) {
	response := get(t, newHandler(), "/health")
	if body := decode(t, response); response.Code != http.StatusOK || body["status"] != "healthy" {
		t.Fatalf("GET /health = %d %v", response.Code, body)
	}
}

func TestReadyReportsReady(t *testing.T) {
	response := get(t, newHandler(), "/ready")
	if body := decode(t, response); response.Code != http.StatusOK || body["status"] != "ready" {
		t.Fatalf("GET /ready = %d %v", response.Code, body)
	}
}

func TestMetricsCountsRequests(t *testing.T) {
	handler := newHandler()
	get(t, handler, "/health")
	response := get(t, handler, "/metrics")
	if response.Code != http.StatusOK || !regexp.MustCompile(`(?m)^http_requests_total 2$`).MatchString(response.Body.String()) {
		t.Fatalf("GET /metrics = %d %s", response.Code, response.Body.String())
	}
}

func TestUnknownPathsReturn404(t *testing.T) {
	if response := get(t, newHandler(), "/missing"); response.Code != http.StatusNotFound {
		t.Fatalf("GET /missing = %d", response.Code)
	}
}
