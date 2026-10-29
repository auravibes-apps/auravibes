# Context: `apps/auravibes_app`

## Responsibility and data flow

The Flutter app owns user workflows, local persistence, account sessions, and localized presentation.
Views read Riverpod state. Notifiers call use cases, which use repositories and services.
Local repositories use the app database. Cloud adapters use the generated Serverpod client.

Inputs include user actions, local records, cloud snapshots, and conversation streams.
Outputs include localized views, persisted app state, engine requests, and authenticated cloud requests.

## Domain terms

- **Workspace**: the scope for conversations, agents, tools, and configuration.
- **Local workspace**: an app-owned workspace with a null remote URL and no complete cloud mirror pair.
- **Cloud mirror**: a remote workspace linked through both cloud workspace and account identifiers.
- **Conversation**: a workspace-owned transcript with optional model, agent, fork, and subagent metadata.
- **Agent**: workspace configuration with instructions, visibility, enabled state, and skill references.
- **Workflow**: reusable sequence of connected steps with named inputs and outputs.
- **Connector tool node**: Workflow step that references one stable Connector tool ID; Workspace Connections are resolved separately.
- **Cloud account session**: authentication state scoped to a server origin and account identity.

## Invariants

- Workspace names and conversation titles must not be empty. Conversations need a workspace identifier.
- Local workspace validation rejects remote URLs and complete cloud mirror identifier pairs. It does not reject an isolated identifier.
- Remote workspace creation needs a nonempty URL or two nonempty cloud mirror identifiers.
- Cloud clients use account-scoped authentication storage. Provider disposal closes their connections.
- App adapters own persistence, permissions, and localization. Engine code does not own these concerns.
- Workflow nodes store Connector tool IDs, not Connection IDs. Connector output ports store inferred names and types, never sample values.
- User-facing text uses localization keys. Shared UI components receive content from their host.

## Relationships and evidence

- [Engine](../../packages/auravibes_engine/CONTEXT.md) supplies app-neutral agent execution contracts.
- [Server client](../../packages/auravibes_server_client/CONTEXT.md) supplies typed cloud calls and models.
- [UI](../../packages/auravibes_ui/CONTEXT.md) supplies reusable components and theme tokens.
- [Target architecture](../../doc/architecture/target-architecture.md) defines app layers and dependency direction.
- [Package boundaries](../../doc/architecture/package-boundaries.md) defines ownership across packages.
- [Workspace entities](lib/domain/entities/workspace_entity.dart) define local and remote validation.
- [Conversation entities](lib/domain/entities/conversation_entity.dart) define transcript identity and fork metadata.
- [Agent entities](lib/domain/entities/agent_entity.dart) define agent configuration and skill references.
- [Client providers](lib/features/cloud_accounts/providers/serverpod_client_provider.dart) bind cloud clients to account sessions.
