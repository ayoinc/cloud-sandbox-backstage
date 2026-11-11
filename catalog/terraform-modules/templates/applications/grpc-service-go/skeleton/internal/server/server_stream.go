package server

import (
	"google.golang.org/grpc"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

// ListItems streams every stored item to the caller.
func (s *Service) ListItems(_ *pb.ListItemsRequest, stream grpc.ServerStreamingServer[pb.ListItemsResponse]) error {
	for _, item := range s.store.List() {
		if err := stream.Send(&pb.ListItemsResponse{Item: item}); err != nil {
			return err
		}
	}
	return nil
}
