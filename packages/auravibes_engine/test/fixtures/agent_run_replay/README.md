# Offline agent run fixtures

These synthetic JSON fixtures drive `AgentStreamService` and `AgentService`
without providers, credentials, MCP servers, or persisted user data.

Each file has `schemaVersion: 1`, a scenario name, an ordered `events` array,
and an `expected` result. Event IDs are unique within a fixture and appear in
replay failure messages to locate the first divergence.

Supported events:

- `chunk`: provider text delta and optional complete tool requests.
- `response`: ends the current provider response. Tool results follow in
  request order.
- `toolResult`: synthetic result for the matching tool call ID.
- `cancel`: stops the active stream and must be the final event.
- `failure`: fails a provider request between responses. `rateLimit` requires
  a positive `retryAfterMs`; `unknown` is non-retryable.

`expected` records the decision or error, event order, assistant message
statuses and text, partial stream snapshots, tool dispatches and results,
exactly-once side-effect counts, user message lifecycle, and retry events.
The test support parser validates the schema and event ordering before replay.
