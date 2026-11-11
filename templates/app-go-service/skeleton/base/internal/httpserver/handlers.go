package httpserver

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/internal/store"
)

const (
	maxBodyBytes  = 1 << 20
	maxNameLength = 200
)

func (a *App) handleHealth(w http.ResponseWriter, r *http.Request) {
	a.writeJSON(w, r, http.StatusOK, map[string]string{
		"status":      "ok",
		"service":     a.service,
		"version":     a.version,
		"environment": a.environment,
		"timestamp":   time.Now().UTC().Format(time.RFC3339),
	})
}

func (a *App) handleLive(w http.ResponseWriter, r *http.Request) {
	a.writeJSON(w, r, http.StatusOK, map[string]bool{"alive": true})
}

func (a *App) handleReady(w http.ResponseWriter, r *http.Request) {
	if !a.ready.Load() {
		a.writeJSON(w, r, http.StatusServiceUnavailable, map[string]bool{"ready": false})
		return
	}
	a.writeJSON(w, r, http.StatusOK, map[string]bool{"ready": true})
}

func (a *App) handleListItems(w http.ResponseWriter, r *http.Request) {
	items, err := a.store.List(r.Context())
	if err != nil {
		a.internalError(w, r, "list items", err)
		return
	}
	a.writeJSON(w, r, http.StatusOK, map[string][]store.Item{"items": items})
}

func (a *App) handleGetItem(w http.ResponseWriter, r *http.Request) {
	item, err := a.store.Get(r.Context(), r.PathValue("id"))
	if errors.Is(err, store.ErrNotFound) {
		a.writeError(w, r, http.StatusNotFound, "Item not found")
		return
	}
	if err != nil {
		a.internalError(w, r, "get item", err)
		return
	}
	a.writeJSON(w, r, http.StatusOK, item)
}

func (a *App) handleCreateItem(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Name string `json:"name"`
	}
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, maxBodyBytes))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&input); err != nil {
		a.writeError(w, r, http.StatusBadRequest, "The body must be a JSON object with a name")
		return
	}
	name := strings.TrimSpace(input.Name)
	if name == "" || len(name) > maxNameLength {
		a.writeError(w, r, http.StatusUnprocessableEntity, "name must have between 1 and 200 characters")
		return
	}

	item, err := a.store.Create(r.Context(), name)
	if err != nil {
		a.internalError(w, r, "create item", err)
		return
	}
	w.Header().Set("Location", "/api/items/"+item.ID)
	a.writeJSON(w, r, http.StatusCreated, item)
}

func (a *App) handleNotFound(w http.ResponseWriter, r *http.Request) {
	a.writeError(w, r, http.StatusNotFound, "Not Found")
}

func (a *App) internalError(w http.ResponseWriter, r *http.Request, action string, err error) {
	a.logger.ErrorContext(r.Context(), "request failed", slog.String("action", action), slog.Any("error", err))
	a.writeError(w, r, http.StatusInternalServerError, "Internal Server Error")
}
