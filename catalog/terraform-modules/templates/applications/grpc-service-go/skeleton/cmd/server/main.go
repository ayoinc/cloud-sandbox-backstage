// Command server runs the ${{ values.serviceName }} gRPC service.
package main

import (
	"context"
	"log/slog"
	"net"
	"os"
	"os/signal"
	"syscall"

	"${{ values.modulePath }}/internal/app"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	if err := run(logger); err != nil {
		logger.Error("server failed", "error", err)
		os.Exit(1)
	}
}

func run(logger *slog.Logger) error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	opts := app.OptionsFromEnv()
	a, err := app.New(opts, logger)
	if err != nil {
		return err
	}
	lis, err := net.Listen("tcp", opts.Addr)
	if err != nil {
		return err
	}
	return a.Serve(ctx, lis)
}
