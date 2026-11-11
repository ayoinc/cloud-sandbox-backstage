package app

import (
	"context"
	"io"
	"log/slog"
	"net"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/status"

	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

func TestServeAnswersCallsAndStopsOnCancel(t *testing.T) {
	a, err := New(Options{Reflection: true}, slog.New(slog.NewTextHandler(io.Discard, nil)))
	if err != nil {
		t.Fatalf("New: %v", err)
	}
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatalf("listen: %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	served := make(chan error, 1)
	go func() { served <- a.Serve(ctx, lis) }()

	conn, err := grpc.NewClient(lis.Addr().String(), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	defer func() { _ = conn.Close() }()

	// A method the service does not define is answered by the service itself,
	// which shows the server is up and the service is registered.
	callCtx, cancelCall := context.WithTimeout(ctx, 5*time.Second)
	defer cancelCall()
	method := "/" + pb.${{ values.serviceType }}_ServiceDesc.ServiceName + "/Undefined"
	err = conn.Invoke(callCtx, method, &pb.Item{}, &pb.Item{})
	if status.Code(err) != codes.Unimplemented || !strings.Contains(status.Convert(err).Message(), "unknown method") {
		t.Fatalf("call to an undefined method: got %v, want Unimplemented for an unknown method", err)
	}

	cancel()
	select {
	case err := <-served:
		if err != nil {
			t.Fatalf("Serve: %v", err)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("Serve did not return after the context was cancelled")
	}
}

func TestOptionsFromEnv(t *testing.T) {
	t.Setenv("GRPC_ADDR", "127.0.0.1:6000")
	t.Setenv("GRPC_REFLECTION", "false")

	opts := OptionsFromEnv()
	if opts.Addr != "127.0.0.1:6000" {
		t.Errorf("Addr = %q, want 127.0.0.1:6000", opts.Addr)
	}
	if opts.Reflection {
		t.Error("Reflection = true, want false")
	}
}
