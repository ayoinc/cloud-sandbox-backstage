package server

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

func TestImportItemsStoresEveryItem(t *testing.T) {
	conn, store := startService(t)
	client := pb.New${{ values.serviceType }}Client(conn)

	stream, err := client.ImportItems(context.Background())
	if err != nil {
		t.Fatalf("ImportItems: %v", err)
	}
	for _, name := range []string{"one", "two", "three"} {
		if err := stream.Send(&pb.ImportItemsRequest{Name: name}); err != nil {
			t.Fatalf("Send: %v", err)
		}
	}
	resp, err := stream.CloseAndRecv()
	if err != nil {
		t.Fatalf("CloseAndRecv: %v", err)
	}
	if resp.GetImportedCount() != 3 || len(store.List()) != 3 {
		t.Fatalf("imported %d items and stored %d, want 3 and 3", resp.GetImportedCount(), len(store.List()))
	}
}

func TestImportItemsRequiresName(t *testing.T) {
	conn, _ := startService(t)
	client := pb.New${{ values.serviceType }}Client(conn)

	stream, err := client.ImportItems(context.Background())
	if err != nil {
		t.Fatalf("ImportItems: %v", err)
	}
	if err := stream.Send(&pb.ImportItemsRequest{}); err != nil {
		t.Fatalf("Send: %v", err)
	}
	_, err = stream.CloseAndRecv()
	if status.Code(err) != codes.InvalidArgument {
		t.Fatalf("got %v, want InvalidArgument", err)
	}
}
