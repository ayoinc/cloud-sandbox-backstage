package httpserver

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/internal/store"
)

func newTestApp() *App {
	return New(Options{
		Logger:      slog.New(slog.DiscardHandler),
		Service:     "test-service",
		Version:     "test",
		Environment: "test",
		Store:       store.NewMemory(),
	})
}

func call(t *testing.T, handler http.Handler, method, path, body string) *httptest.ResponseRecorder {
	t.Helper()
	request := httptest.NewRequestWithContext(t.Context(), method, path, strings.NewReader(body))
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	return response
}

func decode[T any](t *testing.T, response *httptest.ResponseRecorder) T {
	t.Helper()
	var value T
	if err := json.Unmarshal(response.Body.Bytes(), &value); err != nil {
		t.Fatalf("response is not JSON: %v: %s", err, response.Body.String())
	}
	return value
}

func TestHealth(t *testing.T) {
	response := call(t, newTestApp().Handler(), http.MethodGet, "/health", "")
	if response.Code != http.StatusOK {
		t.Fatalf("status %d", response.Code)
	}
	body := decode[map[string]string](t, response)
	if body["status"] != "ok" || body["service"] != "test-service" || body["environment"] != "test" {
		t.Errorf("unexpected body: %v", body)
	}
}

func TestProbes(t *testing.T) {
	app := newTestApp()
	handler := app.Handler()

	if code := call(t, handler, http.MethodGet, "/health/live", "").Code; code != http.StatusOK {
		t.Errorf("live: status %d", code)
	}
	if code := call(t, handler, http.MethodGet, "/health/ready", "").Code; code != http.StatusOK {
		t.Errorf("ready: status %d", code)
	}

	app.SetReady(false)
	if code := call(t, handler, http.MethodGet, "/health/ready", "").Code; code != http.StatusServiceUnavailable {
		t.Errorf("ready while shutting down: status %d", code)
	}
	if code := call(t, handler, http.MethodGet, "/health/live", "").Code; code != http.StatusOK {
		t.Errorf("live while shutting down: status %d", code)
	}
}

func TestItems(t *testing.T) {
	handler := newTestApp().Handler()

	created := call(t, handler, http.MethodPost, "/api/items", `{"name":"  first  "}`)
	if created.Code != http.StatusCreated {
		t.Fatalf("create: status %d: %s", created.Code, created.Body.String())
	}
	item := decode[store.Item](t, created)
	if item.ID == "" || item.Name != "first" {
		t.Fatalf("unexpected item: %+v", item)
	}
	if location := created.Header().Get("Location"); location != "/api/items/"+item.ID {
		t.Errorf("Location is %q", location)
	}

	fetched := call(t, handler, http.MethodGet, "/api/items/"+item.ID, "")
	if fetched.Code != http.StatusOK || decode[store.Item](t, fetched).ID != item.ID {
		t.Errorf("get: status %d: %s", fetched.Code, fetched.Body.String())
	}

	listed := call(t, handler, http.MethodGet, "/api/items", "")
	items := decode[map[string][]store.Item](t, listed)["items"]
	if listed.Code != http.StatusOK || len(items) != 1 {
		t.Errorf("list: status %d: %s", listed.Code, listed.Body.String())
	}
}

func TestEmptyListIsAnArray(t *testing.T) {
	response := call(t, newTestApp().Handler(), http.MethodGet, "/api/items", "")
	if got := strings.TrimSpace(response.Body.String()); got != `{"items":[]}` {
		t.Errorf("got %s", got)
	}
}

func TestCreateItemRejectsInvalidInput(t *testing.T) {
	handler := newTestApp().Handler()
	for name, test := range map[string]struct {
		body string
		want int
	}{
		"not JSON":      {"name=first", http.StatusBadRequest},
		"unknown field": {`{"name":"first","admin":true}`, http.StatusBadRequest},
		"blank name":    {`{"name":"   "}`, http.StatusUnprocessableEntity},
		"long name":     {`{"name":"` + strings.Repeat("a", maxNameLength+1) + `"}`, http.StatusUnprocessableEntity},
	} {
		t.Run(name, func(t *testing.T) {
			if code := call(t, handler, http.MethodPost, "/api/items", test.body).Code; code != test.want {
				t.Errorf("status %d, want %d", code, test.want)
			}
		})
	}
}

func TestNotFound(t *testing.T) {
	handler := newTestApp().Handler()
	for _, path := range []string{"/api/items/missing", "/nowhere"} {
		response := call(t, handler, http.MethodGet, path, "")
		if response.Code != http.StatusNotFound || decode[map[string]string](t, response)["error"] == "" {
			t.Errorf("%s: status %d: %s", path, response.Code, response.Body.String())
		}
	}
}

func TestPanicBecomesInternalServerError(t *testing.T) {
	app := newTestApp()
	handler := app.recoverPanics(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		panic("boom")
	}))
	if code := call(t, handler, http.MethodGet, "/", "").Code; code != http.StatusInternalServerError {
		t.Errorf("status %d", code)
	}
}
