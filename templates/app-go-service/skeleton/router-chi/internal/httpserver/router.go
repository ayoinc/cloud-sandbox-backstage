package httpserver

import (
	"net/http"

	"github.com/go-chi/chi/v5"
)

// routes maps methods and paths to handlers with chi. Path parameters are
// read with r.PathValue, as with the standard library's ServeMux.
func (a *App) routes() http.Handler {
	router := chi.NewRouter()
	router.NotFound(a.handleNotFound)

	router.Get("/health", a.handleHealth)
	router.Get("/health/live", a.handleLive)
	router.Get("/health/ready", a.handleReady)

	router.Route("/api", func(api chi.Router) {
		api.Get("/items", a.handleListItems)
		api.Post("/items", a.handleCreateItem)
		api.Get("/items/{id}", a.handleGetItem)
	})
	return router
}
