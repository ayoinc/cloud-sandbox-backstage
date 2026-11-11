package interceptors

import (
	"bytes"
	"context"
	"errors"
	"log/slog"
	"strings"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

var unaryInfo = &grpc.UnaryServerInfo{FullMethod: "/example.v1.Example/Call"}

// fakeStream is a server stream that only carries a context.
type fakeStream struct {
	grpc.ServerStream
	ctx context.Context
}

func (s fakeStream) Context() context.Context { return s.ctx }

func withToken(token string) context.Context {
	return metadata.NewIncomingContext(context.Background(), metadata.Pairs("authorization", "Bearer "+token))
}

func TestUnaryLoggingRecordsMethodAndCode(t *testing.T) {
	var out bytes.Buffer
	interceptor := UnaryLogging(slog.New(slog.NewTextHandler(&out, nil)))

	_, err := interceptor(context.Background(), nil, unaryInfo, func(context.Context, any) (any, error) {
		return nil, status.Error(codes.NotFound, "no such thing")
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("the handler error was not passed through: %v", err)
	}
	logged := out.String()
	if !strings.Contains(logged, "method=/example.v1.Example/Call") || !strings.Contains(logged, "code=NotFound") {
		t.Fatalf("log line lacks the method or code: %s", logged)
	}
}

func TestStreamLoggingRecordsMethodAndCode(t *testing.T) {
	var out bytes.Buffer
	interceptor := StreamLogging(slog.New(slog.NewTextHandler(&out, nil)))
	info := &grpc.StreamServerInfo{FullMethod: "/example.v1.Example/Watch"}

	err := interceptor(nil, fakeStream{ctx: context.Background()}, info, func(any, grpc.ServerStream) error { return nil })
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	logged := out.String()
	if !strings.Contains(logged, "method=/example.v1.Example/Watch") || !strings.Contains(logged, "code=OK") {
		t.Fatalf("log line lacks the method or code: %s", logged)
	}
}

func TestUnaryRecoveryTurnsPanicIntoInternal(t *testing.T) {
	var out bytes.Buffer
	interceptor := UnaryRecovery(slog.New(slog.NewTextHandler(&out, nil)))

	_, err := interceptor(context.Background(), nil, unaryInfo, func(context.Context, any) (any, error) {
		panic("boom")
	})
	if status.Code(err) != codes.Internal {
		t.Fatalf("got %v, want Internal", err)
	}
	if !strings.Contains(out.String(), "boom") {
		t.Fatalf("the panic value was not logged: %s", out.String())
	}
}

func TestStreamRecoveryTurnsPanicIntoInternal(t *testing.T) {
	var out bytes.Buffer
	interceptor := StreamRecovery(slog.New(slog.NewTextHandler(&out, nil)))
	info := &grpc.StreamServerInfo{FullMethod: "/example.v1.Example/Watch"}

	err := interceptor(nil, fakeStream{ctx: context.Background()}, info, func(any, grpc.ServerStream) error {
		panic(errors.New("boom"))
	})
	if status.Code(err) != codes.Internal {
		t.Fatalf("got %v, want Internal", err)
	}
}

func TestUnaryAuth(t *testing.T) {
	interceptor := UnaryAuth("s3cret")
	handler := func(context.Context, any) (any, error) { return "ok", nil }

	tests := []struct {
		name   string
		ctx    context.Context
		method string
		want   codes.Code
	}{
		{"valid token", withToken("s3cret"), unaryInfo.FullMethod, codes.OK},
		{"wrong token", withToken("guess"), unaryInfo.FullMethod, codes.Unauthenticated},
		{"no metadata", context.Background(), unaryInfo.FullMethod, codes.Unauthenticated},
		{"health check without token", context.Background(), "/grpc.health.v1.Health/Check", codes.OK},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := interceptor(tt.ctx, nil, &grpc.UnaryServerInfo{FullMethod: tt.method}, handler)
			if status.Code(err) != tt.want {
				t.Fatalf("got %v, want %v", status.Code(err), tt.want)
			}
		})
	}
}

func TestStreamAuth(t *testing.T) {
	interceptor := StreamAuth("s3cret")
	info := &grpc.StreamServerInfo{FullMethod: "/example.v1.Example/Watch"}
	handler := func(any, grpc.ServerStream) error { return nil }

	if err := interceptor(nil, fakeStream{ctx: withToken("s3cret")}, info, handler); err != nil {
		t.Fatalf("valid token rejected: %v", err)
	}
	err := interceptor(nil, fakeStream{ctx: context.Background()}, info, handler)
	if status.Code(err) != codes.Unauthenticated {
		t.Fatalf("got %v, want Unauthenticated", err)
	}
}
