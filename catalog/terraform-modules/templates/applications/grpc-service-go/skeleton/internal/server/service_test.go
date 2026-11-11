package server

import (
	"context"
	"net"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"
	"google.golang.org/grpc/test/bufconn"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

// startService serves a Service over an in-memory connection and returns a
// client connection to it together with the store behind it.
func startService(t *testing.T) (*grpc.ClientConn, *Store) {
	t.Helper()
	store := NewStore()
	lis := bufconn.Listen(1 << 20)
	srv := grpc.NewServer()
	pb.Register${{ values.serviceType }}Server(srv, New(store))
	go func() { _ = srv.Serve(lis) }()
	t.Cleanup(srv.Stop)

	conn, err := grpc.NewClient("passthrough:///bufnet",
		grpc.WithContextDialer(func(ctx context.Context, _ string) (net.Conn, error) { return lis.DialContext(ctx) }),
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	return conn, store
}

func TestUndefinedMethodIsUnimplemented(t *testing.T) {
	conn, _ := startService(t)

	method := "/" + pb.${{ values.serviceType }}_ServiceDesc.ServiceName + "/Undefined"
	err := conn.Invoke(context.Background(), method, &pb.Item{}, &pb.Item{})
	if status.Code(err) != codes.Unimplemented {
		t.Fatalf("got %v, want Unimplemented", err)
	}
}
