# Context: `apps/auravibes_server`

## Responsibility and data flow

The Serverpod server owns shared cloud state, authorization, and durable conversation execution.
Authenticated endpoints pass account identity and typed requests to use cases and repositories.
PostgreSQL stores durable state. Workers execute queued conversation jobs through engine adapters.

Inputs include authenticated client requests, tool results, and worker wake signals.
Outputs include typed responses, workspace streams, conversation events, and model or tool requests.

## Domain terms

- **Cloud workspace**: shared state with an owner, members, roles, and revision.
- **Membership**: an account's workspace role and access state.
- **Invite**: a workspace access offer with acceptance, decline, renewal, and revocation operations.
- **Mutation receipt**: a stored request identity and hash for idempotent workspace mutations.
- **Conversation turn**: server-owned execution within a conversation, with queued work and stop controls.
- **Conversation event**: a durable semantic change with a sequence cursor for recovery.
- **Transient delta**: live output that does not advance the durable event sequence.

## Invariants

- Cloud workspace and conversation endpoints resolve authenticated account identity before use-case calls.
- Connector sample endpoints accept read tools only, recheck access around execution, and return value-free shapes.
- Workspace use cases enforce active membership and role capabilities before protected operations.
- Repeated mutation identities cannot carry different request content.
- Semantic conversation changes and their events share a transaction.
- Durable jobs remain recoverable without wake signals. Execution uses coordinator election and per-job leases.
- Stream recovery uses snapshots and durable cursors, not transient deltas.
- Server schemas and endpoints define the generated client contract. Generated output is not edited by hand.

## Relationships and evidence

- [App](../auravibes_app/CONTEXT.md) consumes cloud state through account-scoped client adapters.
- [Server client](../../packages/auravibes_server_client/CONTEXT.md) contains generated calls and protocol models.
- [Engine](../../packages/auravibes_engine/CONTEXT.md) supplies shared runtime contracts and execution logic.
- [Live-turn delivery](../../doc/architecture/live-turn-delivery.md) defines durable jobs, event recovery, and Redis fanout.
- [Package boundaries](../../doc/architecture/package-boundaries.md) defines shared engine ownership.
- [Workspace endpoint](lib/src/features/workspaces/cloud_workspace_endpoint.dart) resolves account identity and routes workspace requests.
- [Workspace use cases](lib/src/features/workspaces/usecases/cloud_workspace_usecases.dart) enforce access and mutation rules.
- [Conversation endpoint](lib/src/features/conversations/conversation_endpoint.dart) exposes turns, snapshots, and subscriptions.
- [Generator configuration](config/generator.yaml) selects the client package and server test output.
