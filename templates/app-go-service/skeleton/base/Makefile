.PHONY: run test lint build image

run:
	go run ./cmd/server

test:
	go test -race -cover ./...

lint:
	golangci-lint run

build:
	CGO_ENABLED=0 go build -trimpath -o bin/server ./cmd/server

image:
	docker build -t ${{ values.name }} .
