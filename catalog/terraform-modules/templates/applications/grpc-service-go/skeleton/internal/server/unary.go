package server

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

// CreateItem stores a new item and returns it with its assigned ID.
func (s *Service) CreateItem(_ context.Context, req *pb.CreateItemRequest) (*pb.CreateItemResponse, error) {
	if req.GetName() == "" {
		return nil, status.Error(codes.InvalidArgument, "name is required")
	}
	item := s.store.Put(&pb.Item{Name: req.GetName(), Description: req.GetDescription()})
	return &pb.CreateItemResponse{Item: item}, nil
}

// GetItem returns one item by ID.
func (s *Service) GetItem(_ context.Context, req *pb.GetItemRequest) (*pb.GetItemResponse, error) {
	item, ok := s.store.Get(req.GetId())
	if !ok {
		return nil, status.Errorf(codes.NotFound, "item %q not found", req.GetId())
	}
	return &pb.GetItemResponse{Item: item}, nil
}
