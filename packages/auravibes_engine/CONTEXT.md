# Context: `packages/auravibes_engine`

## Responsibility and data flow

The engine owns app-neutral agent execution, tool dispatch, skill execution, and model protocol mapping.
Hosts supply data providers, model providers, tools, and cancellation controls through engine contracts.
The engine processes conversation input and returns model output, tool results, and execution state through those contracts.

Inputs include transcripts, agent configuration, model responses, tool specifications, and skill definitions.
Outputs include conversation updates, tool calls, approval requests, model requests, and structured content.

## Domain terms

- **Agent data provider**: host adapter for conversation data, stop state, and compaction.
- **Tool specification**: tool identity, input schema, and execution behavior.
- **Tool approval**: a decision that controls whether a pending tool call can execute.
- **Execution scope**: cooperative stop state with registered cancellation callbacks.
- **Skill definition**: executable skill configuration with HTTP and template support.
- **Transcript**: conversation content prepared for model execution and compaction.
- **A2UI content**: structured UI data that the engine decodes and validates, not Flutter widgets.

## Invariants

- This package uses Dart without Flutter, Riverpod, Drift, or app localization.
- Hosts own persistence, UI, permissions, and platform integration.
- Conversation data access uses provider contracts instead of app database implementations.
- Cancellation uses stop controls and registered cleanup callbacks.
- Public consumers use the package entrypoint. Internal helpers can remain outside public exports.
- Connector sample shaping preserves value types and field names while dropping sample values.

## Relationships and evidence

- [App](../../apps/auravibes_app/CONTEXT.md) supplies app adapters and consumes engine results.
- [Server](../../apps/auravibes_server/CONTEXT.md) supplies server runtime and persistence adapters.
- [Package boundaries](../../doc/architecture/package-boundaries.md) defines engine ownership and dependency rules.
- [Target architecture](../../doc/architecture/target-architecture.md) defines host adapter placement.
- [Public entrypoint](lib/auravibes_engine.dart) exports runtime, tool, skill, provider, and A2UI contracts.
- [Data provider](lib/src/providers/agent_data_provider.dart) combines conversation, stop, and compaction contracts.
- [Runtime contracts](lib/src/agent_runtime.dart) define conversation data access and execution cancellation.
