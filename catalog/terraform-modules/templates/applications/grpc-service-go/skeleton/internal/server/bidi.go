package server

import (
	"errors"
	"io"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

// SyncItems stores each item it receives and answers with the stored item.
func (s *Service) SyncItems(stream grpc.BidiStreamingServer[pb.SyncItemsRequest, pb.SyncItemsResponse]) error {
	for {
		req, err := stream.Recv()
		if errors.Is(err, io.EOF) {
			return nil
		}
		if err != nil {
			return err
		}
		if req.GetItem().GetName() == "" {
			return status.Error(codes.InvalidArgument, "item.name is required")
		}
		if err := stream.Send(&pb.SyncItemsResponse{Item: s.store.Put(req.GetItem())}); err != nil {
			return err
		}
	}
}
