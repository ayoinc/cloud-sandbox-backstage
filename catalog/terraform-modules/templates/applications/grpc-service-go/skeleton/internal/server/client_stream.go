package server

import (
	"errors"
	"io"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

// ImportItems stores each item it receives and returns how many it stored.
func (s *Service) ImportItems(stream grpc.ClientStreamingServer[pb.ImportItemsRequest, pb.ImportItemsResponse]) error {
	var imported int32
	for {
		req, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			return stream.SendAndClose(&pb.ImportItemsResponse{ImportedCount: imported})
		}
		if err != nil {
			return err
		}
		if req.GetName() == "" {
			return status.Error(codes.InvalidArgument, "name is required")
		}
		s.store.Put(&pb.Item{Name: req.GetName(), Description: req.GetDescription()})
		imported++
	}
}
