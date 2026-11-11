package httpserver

import "net/http"

// routes maps methods and paths to handlers with the standard library's
// ServeMux.
func (a *App) routes() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", a.handleHealth)
	mux.HandleFunc("GET /health/live", a.handleLive)
	mux.HandleFunc("GET /health/ready", a.handleReady)

	mux.HandleFunc("GET /api/items", a.handleListItems)
	mux.HandleFunc("POST /api/items", a.handleCreateItem)
	mux.HandleFunc("GET /api/items/{id}", a.handleGetItem)

	mux.HandleFunc("/", a.handleNotFound)
	return mux
}
