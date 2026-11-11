// Package store holds the items the API serves.
package store

import (
	"context"
	"crypto/rand"
	"errors"
	"sort"
	"sync"
	"time"
)

// ErrNotFound is returned when no item has the requested ID.
var ErrNotFound = errors.New("item not found")

// Item is the resource served under /api/items.
type Item struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	CreatedAt time.Time `json:"createdAt"`
}

// Store is what the HTTP handlers need from a repository. Implement it on a
// database to replace the in-memory store.
type Store interface {
	List(ctx context.Context) ([]Item, error)
	Get(ctx context.Context, id string) (Item, error)
	Create(ctx context.Context, name string) (Item, error)
}

// Memory keeps items in process memory. Its content is lost on restart and is
// not shared between replicas.
type Memory struct {
	mu    sync.RWMutex
	items map[string]Item
}

// NewMemory returns an empty in-memory store.
func NewMemory() *Memory {
	return &Memory{items: make(map[string]Item)}
}

// List returns every item, oldest first.
func (m *Memory) List(_ context.Context) ([]Item, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	items := make([]Item, 0, len(m.items))
	for _, item := range m.items {
		items = append(items, item)
	}
	sort.Slice(items, func(i, j int) bool {
		if items[i].CreatedAt.Equal(items[j].CreatedAt) {
			return items[i].ID < items[j].ID
		}
		return items[i].CreatedAt.Before(items[j].CreatedAt)
	})
	return items, nil
}

// Get returns the item with the given ID or ErrNotFound.
func (m *Memory) Get(_ context.Context, id string) (Item, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	item, ok := m.items[id]
	if !ok {
		return Item{}, ErrNotFound
	}
	return item, nil
}

// Create stores a new item under a random ID.
func (m *Memory) Create(_ context.Context, name string) (Item, error) {
	item := Item{ID: rand.Text(), Name: name, CreatedAt: time.Now().UTC()}

	m.mu.Lock()
	defer m.mu.Unlock()
	m.items[item.ID] = item
	return item, nil
}
