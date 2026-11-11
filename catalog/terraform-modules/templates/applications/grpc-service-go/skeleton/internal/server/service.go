// Package server implements the ${{ values.serviceType }} gRPC service.
package server

import (
	pb "${{ values.modulePath }}/gen/${{ values.pkg }}/v1"
)

// Service implements pb.${{ values.serviceType }}Server on top of a Store.
type Service struct {
	pb.Unimplemented${{ values.serviceType }}Server

	store *Store
}

// New returns a Service that keeps its items in store.
func New(store *Store) *Service {
	return &Service{store: store}
}
