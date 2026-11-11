package server

import (
	"crypto/rand"
	"sort"
	"sync"

	"google.golang.org/protobuf/proto"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

// Store keeps items in memory. It is safe for concurrent use. Replace it with
// a database-backed implementation when items must outlive the process.
type Store struct {
	mu    sync.RWMutex
	items map[string]*pb.Item
}

// NewStore returns an empty Store.
func NewStore() *Store {
	return &Store{items: make(map[string]*pb.Item)}
}

// Put stores item and returns the stored copy. An item without an ID gets a
// new one; an item with a known ID replaces the stored item.
func (s *Store) Put(item *pb.Item) *pb.Item {
	stored := proto.Clone(item).(*pb.Item)
	if stored.GetId() == "" {
		stored.Id = rand.Text()
	}
	s.mu.Lock()
	s.items[stored.GetId()] = stored
	s.mu.Unlock()
	return proto.Clone(stored).(*pb.Item)
}

// Get returns the item with the given ID.
func (s *Store) Get(id string) (*pb.Item, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	item, ok := s.items[id]
	if !ok {
		return nil, false
	}
	return proto.Clone(item).(*pb.Item), true
}

// List returns every item, ordered by ID.
func (s *Store) List() []*pb.Item {
	s.mu.RLock()
	defer s.mu.RUnlock()
	items := make([]*pb.Item, 0, len(s.items))
	for _, item := range s.items {
		items = append(items, proto.Clone(item).(*pb.Item))
	}
	sort.Slice(items, func(i, j int) bool { return items[i].GetId() < items[j].GetId() })
	return items
}
