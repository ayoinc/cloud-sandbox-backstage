# API

The API is defined in `proto/${{ values.pkg }}/v1/service.proto`. The service is
`${{ values.pkg }}.v1.${{ values.serviceType }}`.

{% if values.enableUnary or values.enableServerStreaming or values.enableClientStreaming or values.enableBidirectional %}
| Method | Kind | What it does |
| --- | --- | --- |
{% if values.enableUnary %}
| `CreateItem` | Unary | Stores a new item and returns it with its assigned ID. |
| `GetItem` | Unary | Returns one item by ID. |
{% endif %}
{% if values.enableServerStreaming %}
| `ListItems` | Server streaming | Streams every stored item. |
{% endif %}
{% if values.enableClientStreaming %}
| `ImportItems` | Client streaming | Stores each item it receives and returns the count. |
{% endif %}
{% if values.enableBidirectional %}
| `SyncItems` | Bidirectional streaming | Stores each item it receives and answers with the stored item. |
{% endif %}
{% else %}
The service has no methods yet. Add the first `rpc` to the proto file, run
`make generate` and implement it in `internal/server`.
{% endif %}

Items are kept in memory (`internal/server/store.go`). Replace the store with a
database-backed one when items must outlive the process.

## Calling the service

The server supports reflection, so [grpcurl](https://github.com/fullstorydev/grpcurl)
needs no proto files:

```sh
grpcurl -plaintext localhost:50051 list
grpcurl -plaintext localhost:50051 describe ${{ values.pkg }}.v1.${{ values.serviceType }}
{% if values.enableUnary %}
grpcurl -plaintext -d '{"name": "widget"}' localhost:50051 ${{ values.pkg }}.v1.${{ values.serviceType }}/CreateItem
{% endif %}
{% if values.enableHealthChecks %}
grpcurl -plaintext localhost:50051 grpc.health.v1.Health/Check
{% endif %}
```

Set `GRPC_REFLECTION=false` to turn reflection off.

## Changing the API

1. Edit the proto file.
2. Run `make lint`: buf checks the style, and pull requests are checked for
   breaking changes against the target branch.
3. Run `make generate` and implement the new methods in `internal/server`.
   A method that is defined but not implemented answers `Unimplemented`.
