package interceptors

import (
	"context"
	"crypto/subtle"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

// openMethodPrefix marks the methods that need no token: health checks, so
// probes and load balancers work without credentials.
const openMethodPrefix = "/grpc.health.v1.Health/"

// UnaryAuth rejects unary calls that do not carry "authorization: Bearer
// <token>" metadata.
func UnaryAuth(token string) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
		if err := authorize(ctx, info.FullMethod, token); err != nil {
			return nil, err
		}
		return handler(ctx, req)
	}
}

// StreamAuth rejects streams that do not carry "authorization: Bearer
// <token>" metadata.
func StreamAuth(token string) grpc.StreamServerInterceptor {
	return func(srv any, stream grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		if err := authorize(stream.Context(), info.FullMethod, token); err != nil {
			return err
		}
		return handler(srv, stream)
	}
}

func authorize(ctx context.Context, method, token string) error {
	if strings.HasPrefix(method, openMethodPrefix) {
		return nil
	}
	md, _ := metadata.FromIncomingContext(ctx)
	values := md.Get("authorization")
	if len(values) == 0 {
		return status.Error(codes.Unauthenticated, "missing authorization metadata")
	}
	presented, ok := strings.CutPrefix(values[0], "Bearer ")
	if !ok || subtle.ConstantTimeCompare([]byte(presented), []byte(token)) != 1 {
		return status.Error(codes.Unauthenticated, "invalid token")
	}
	return nil
}
