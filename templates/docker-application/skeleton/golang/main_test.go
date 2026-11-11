package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func get(t *testing.T, path string) (int, map[string]string) {
	t.Helper()
	recorder := httptest.NewRecorder()
	newMux().ServeHTTP(recorder, httptest.NewRequest(http.MethodGet, path, nil))
	var body map[string]string
	if err := json.NewDecoder(recorder.Body).Decode(&body); err != nil {
		t.Fatalf("decoding the response of %s: %v", path, err)
	}
	return recorder.Code, body
}

func TestRootReturnsTheServiceName(t *testing.T) {
	status, body := get(t, "/")
	if status != http.StatusOK || body["service"] != service {
		t.Fatalf("GET / = %d %v", status, body)
	}
}

func TestHealthReportsHealthy(t *testing.T) {
	status, body := get(t, "/health")
	if status != http.StatusOK || body["status"] != "healthy" {
		t.Fatalf("GET /health = %d %v", status, body)
	}
}

func TestUnknownPathsReturn404(t *testing.T) {
	status, _ := get(t, "/missing")
	if status != http.StatusNotFound {
		t.Fatalf("GET /missing = %d", status)
	}
}
