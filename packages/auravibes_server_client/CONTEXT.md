# Context: `packages/auravibes_server_client`

## Responsibility and data flow

This package supplies the generated Dart contract for the AuraVibes Serverpod server.
It owns endpoint callers, serialized protocol models, and protocol exceptions, not application policy.
The server generator writes this package from server schemas and endpoints.

Inputs include the server host, typed request objects, and host-managed authentication state.
Outputs include remote endpoint calls, typed responses, protocol exceptions, and event streams.

## Domain terms

- **Client**: the generated Serverpod connection with named endpoint callers and protocol serialization.
- **Endpoint caller**: typed methods that route requests to a named server endpoint.
- **Protocol model**: generated data shared across the server boundary.
- **Request**: typed input for a server operation, including mutation identities or revisions where defined.
- **Snapshot**: server state used to recover a conversation together with its event cursor.
- **Auth module**: generated access to Serverpod account authentication and token refresh calls.

## Invariants

- Server endpoints and schemas define this contract. Do not edit generated protocol files by hand.
- This package transports requests. The server enforces workspace authorization and mutation rules.
- Hosts configure account sessions and close client connections. This package does not own app session storage.
- Protocol models remain separate from app domain entities. App adapters map between those representations.
- Connector sample calls return value-free shapes; workspace authorization and read-only enforcement remain server-owned.

## Relationships and evidence

- [Server](../../apps/auravibes_server/CONTEXT.md) defines and generates the protocol.
- [App](../../apps/auravibes_app/CONTEXT.md) configures clients and maps cloud results into app state.
- [Live-turn delivery](../../doc/architecture/live-turn-delivery.md) defines snapshot, cursor, and stream recovery semantics.
- [Public entrypoint](lib/auravibes_server_client.dart) exports the protocol and Serverpod client types.
- [Generated client](lib/src/protocol/client.dart) defines endpoint callers and client construction.
- [Server generator configuration](../../apps/auravibes_server/config/generator.yaml) selects this package as client output.
- [App client providers](../../apps/auravibes_app/lib/features/cloud_accounts/providers/serverpod_client_provider.dart) bind authentication and connection lifetime.
