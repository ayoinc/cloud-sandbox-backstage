package server

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

func TestCreateThenGetItem(t *testing.T) {
	conn, _ := startService(t)
	client := pb.New${{ values.serviceType }}Client(conn)
	ctx := context.Background()

	created, err := client.CreateItem(ctx, &pb.CreateItemRequest{Name: "widget", Description: "a small part"})
	if err != nil {
		t.Fatalf("CreateItem: %v", err)
	}
	if created.GetItem().GetId() == "" {
		t.Fatal("CreateItem returned an item without an ID")
	}

	got, err := client.GetItem(ctx, &pb.GetItemRequest{Id: created.GetItem().GetId()})
	if err != nil {
		t.Fatalf("GetItem: %v", err)
	}
	if got.GetItem().GetName() != "widget" || got.GetItem().GetDescription() != "a small part" {
		t.Fatalf("GetItem = %v, want the created item", got.GetItem())
	}
}

func TestCreateItemRequiresName(t *testing.T) {
	conn, _ := startService(t)
	client := pb.New${{ values.serviceType }}Client(conn)

	_, err := client.CreateItem(context.Background(), &pb.CreateItemRequest{})
	if status.Code(err) != codes.InvalidArgument {
		t.Fatalf("got %v, want InvalidArgument", err)
	}
}

func TestGetItemNotFound(t *testing.T) {
	conn, _ := startService(t)
	client := pb.New${{ values.serviceType }}Client(conn)

	_, err := client.GetItem(context.Background(), &pb.GetItemRequest{Id: "missing"})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("got %v, want NotFound", err)
	}
}
