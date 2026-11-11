package server

import (
	"context"
	"errors"
	"io"
	"testing"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

func TestSyncItemsAnswersEachItem(t *testing.T) {
	conn, store := startService(t)
	client := pb.New${{ values.serviceType }}Client(conn)

	stream, err := client.SyncItems(context.Background())
	if err != nil {
		t.Fatalf("SyncItems: %v", err)
	}

	if err := stream.Send(&pb.SyncItemsRequest{Item: &pb.Item{Name: "draft"}}); err != nil {
		t.Fatalf("Send: %v", err)
	}
	first, err := stream.Recv()
	if err != nil {
		t.Fatalf("Recv: %v", err)
	}
	id := first.GetItem().GetId()
	if id == "" {
		t.Fatal("the stored item has no ID")
	}

	if err := stream.Send(&pb.SyncItemsRequest{Item: &pb.Item{Id: id, Name: "final"}}); err != nil {
		t.Fatalf("Send: %v", err)
	}
	second, err := stream.Recv()
	if err != nil {
		t.Fatalf("Recv: %v", err)
	}
	if second.GetItem().GetId() != id || second.GetItem().GetName() != "final" {
		t.Fatalf("second answer = %v, want the same item renamed to final", second.GetItem())
	}

	if err := stream.CloseSend(); err != nil {
		t.Fatalf("CloseSend: %v", err)
	}
	if _, err := stream.Recv(); !errors.Is(err, io.EOF) {
		t.Fatalf("after CloseSend: got %v, want io.EOF", err)
	}
	if n := len(store.List()); n != 1 {
		t.Fatalf("store has %d items, want 1", n)
	}
}
