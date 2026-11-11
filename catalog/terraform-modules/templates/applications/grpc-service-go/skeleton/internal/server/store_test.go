package server

import (
	"testing"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

func TestStorePutAssignsIDAndReplaces(t *testing.T) {
	store := NewStore()

	created := store.Put(&pb.Item{Name: "first"})
	if created.GetId() == "" {
		t.Fatal("Put did not assign an ID")
	}

	store.Put(&pb.Item{Id: created.GetId(), Name: "renamed"})
	got, ok := store.Get(created.GetId())
	if !ok || got.GetName() != "renamed" {
		t.Fatalf("Get after replace = %v, %v; want the renamed item", got, ok)
	}
	if n := len(store.List()); n != 1 {
		t.Fatalf("List has %d items, want 1", n)
	}
}

func TestStoreReturnsCopies(t *testing.T) {
	store := NewStore()
	created := store.Put(&pb.Item{Name: "original"})

	created.Name = "changed by the caller"
	got, _ := store.Get(created.GetId())
	if got.GetName() != "original" {
		t.Fatalf("stored item was changed through a returned copy: %q", got.GetName())
	}
}

func TestStoreListIsOrderedByID(t *testing.T) {
	store := NewStore()
	store.Put(&pb.Item{Id: "b", Name: "second"})
	store.Put(&pb.Item{Id: "a", Name: "first"})

	items := store.List()
	if len(items) != 2 || items[0].GetId() != "a" || items[1].GetId() != "b" {
		t.Fatalf("List = %v, want items a then b", items)
	}
}
