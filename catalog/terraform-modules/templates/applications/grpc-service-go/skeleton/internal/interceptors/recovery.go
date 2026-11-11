package interceptors

import (
	"context"
	"log/slog"
	"runtime/debug"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// UnaryRecovery turns a panic in a unary handler into an Internal error, so
// one failing call cannot take the server down.
func UnaryRecovery(logger *slog.Logger) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (_ any, err error) {
		defer func() {
			if recovered := recover(); recovered != nil {
				err = recoveredError(ctx, logger, info.FullMethod, recovered)
			}
		}()
		return handler(ctx, req)
	}
}

// StreamRecovery turns a panic in a stream handler into an Internal error.
func StreamRecovery(logger *slog.Logger) grpc.StreamServerInterceptor {
	return func(srv any, stream grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) (err error) {
		defer func() {
			if recovered := recover(); recovered != nil {
				err = recoveredError(stream.Context(), logger, info.FullMethod, recovered)
			}
		}()
		return handler(srv, stream)
	}
}

func recoveredError(ctx context.Context, logger *slog.Logger, method string, recovered any) error {
	logger.ErrorContext(ctx, "panic in rpc handler",
		slog.String("method", method),
		slog.Any("panic", recovered),
		slog.String("stack", string(debug.Stack())),
	)
	return status.Error(codes.Internal, "internal error")
}
