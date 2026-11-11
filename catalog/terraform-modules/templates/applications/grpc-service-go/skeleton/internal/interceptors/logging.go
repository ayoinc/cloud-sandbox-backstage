// Package interceptors holds the gRPC server interceptors of this service.
package interceptors

import (
	"context"
	"log/slog"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/status"
)

// UnaryLogging logs the method, status code and duration of every unary call.
func UnaryLogging(logger *slog.Logger) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (any, error) {
		start := time.Now()
		resp, err := handler(ctx, req)
		logCall(ctx, logger, info.FullMethod, start, err)
		return resp, err
	}
}

// StreamLogging logs the method, status code and duration of every stream.
func StreamLogging(logger *slog.Logger) grpc.StreamServerInterceptor {
	return func(srv any, stream grpc.ServerStream, info *grpc.StreamServerInfo, handler grpc.StreamHandler) error {
		start := time.Now()
		err := handler(srv, stream)
		logCall(stream.Context(), logger, info.FullMethod, start, err)
		return err
	}
}

func logCall(ctx context.Context, logger *slog.Logger, method string, start time.Time, err error) {
	level := slog.LevelInfo
	if err != nil {
		level = slog.LevelWarn
	}
	logger.LogAttrs(ctx, level, "rpc finished",
		slog.String("method", method),
		slog.String("code", status.Code(err).String()),
		slog.Duration("duration", time.Since(start)),
	)
}
