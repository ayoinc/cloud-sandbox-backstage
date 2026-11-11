package server

import (
	"context"
	"errors"
	"io"
	"testing"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

func TestListItemsStreamsEveryItem(t *testing.T) {
	conn, store := startService(t)
	client := pb.New${{ values.serviceType }}Client(conn)
	store.Put(&pb.Item{Id: "a", Name: "first"})
	store.Put(&pb.Item{Id: "b", Name: "second"})

	stream, err := client.ListItems(context.Background(), &pb.ListItemsRequest{})
	if err != nil {
		t.Fatalf("ListItems: %v", err)
	}
	var names []string
	for {
		resp, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			t.Fatalf("Recv: %v", err)
		}
		names = append(names, resp.GetItem().GetName())
	}
	if len(names) != 2 || names[0] != "first" || names[1] != "second" {
		t.Fatalf("streamed %v, want [first second]", names)
	}
}
