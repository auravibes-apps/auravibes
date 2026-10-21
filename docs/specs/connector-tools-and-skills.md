# Connector tools and Skills spec

- Status: Implementation complete. Focused tests and code generation pass; strict analysis still reports information-level lint findings.
- Date: 2026-10-20

## Problem

Users connect services such as Notion or Gmail and expect agents to use them.
Today, tools are owned by Skills, so the connection and the agent's ability to
use that service feel like separate setup steps. This also makes it hard for
users to author Skills for their own workflows without duplicating or loading
the service's tools.

## Goals

- Let users connect an integration once and make its available capabilities
  usable by agents.
- Keep connector credentials and tool execution independent from Skills.
- Let Skills explain how and when to use tools, and let multiple Skills share
  the same tools.
- Let agents discover available Connections and tools, while allowing a Skill
  with a known tool ID to call the common executor directly.
- Keep the user-facing model simple: connecting a Connector must not require a
  separate Skill toggle.

## Out of scope

- Workflow node design belongs to a separate PR. This work does not add a Skill
  workflow node or decide how workflow nodes connect to agent nodes.
- MCP tool discovery is future work. This spec does not change MCP discovery.

## Product model

Use [the shared glossary](../concepts/glossary.md) for Connector, Connection,
Connector tool, and Skill definitions.

| Concept | Owns | Does not own |
| --- | --- | --- |
| Connector | Catalog identity and offered capabilities, including models and tools | Workspace credentials or use-case instructions |
| Connection | Workspace access, credentials, and public configuration for a Connector | Tool definitions or Skill guidance |
| Connector tool | A reusable operation, its input schema, template, and execution contract | Credentials or Skill-specific instructions |
| Skill | User-authored guidance and references to Connector tool IDs | Connector tools, tool execution, or credentials |

A Connector can offer models, tools, or both. OpenAI is one Connector even when
it offers both model access and tools. Connector filters such as “Only
connectors with tools” come from catalog offerings. Do not persist a model/tool
role tag or encode UI filters in the service-connection enum.

Store credentials in the generic `service_connections` table. Update its kind
enum before release to remove skill-specific `skillCredential` and
`appSkillCredential` cases. Keep the enum about credential ownership or
lifecycle, not about which Skills use a Connector.

## Required behavior

### Connecting a Connector

1. User finds a Connector in the Connectors section and connects an account.
2. The app stores its credentials through `service_connections`.
3. The enabled Connection makes the Connector's credential-dependent tools
   available to agents.
4. Skills that reference those tools become available without a separate
   manual Skill toggle.

Connecting must not install a Skill or copy tool definitions into a Skill.
Users may author a Skill before connecting its required Connector; the Skill's
guidance becomes usable when its referenced tools have an enabled Connection.

### Authoring and loading a Skill

- A Skill contains use-case instructions, such as “use Notion for CRM.”
- A Skill references one or more stable Connector tool IDs.
- A Connector tool can be referenced by multiple Skills.
- Loading a Skill adds its instructions only. It does not load tool definitions,
  install tools, or load credentials.
- A user can use Connector tools without authoring or enabling a Skill.

### Discovering and executing a tool

- Connections and Connector tools are available through shared discovery
  capabilities; they are not exposed as a separate callable tool set for every
  Connector.
- Discovery lets an agent list available Connections and Connector tools.
- A Skill that already names a tool ID may call the common executor without
  first calling discovery.
- The executor resolves the current workspace, enabled Connection, permissions,
  tool revision, and input schema at dispatch time.
- If exactly one enabled Connection can serve a tool, resolve it automatically.
  If multiple Connections match, require the user or agent to select one.
- Do not expose a credential-dependent tool as available when no usable
  Connection exists.

The provider-facing discovery and execution tool names and payload schemas are
implementation choices. Preserve the existing template and execution behavior
while moving ownership from Skills to Connector tools.

## Acceptance criteria

1. A Connector can offer models, tools, or both, and appears once in the
   Connectors UI.
2. Capability filters use catalog offerings. They do not require persisted role
   tags or new credential kinds.
3. Connecting a Connector makes its credential-dependent tools available
   without requiring a separate Skill toggle.
4. A user can create and load a Skill that references a Connector tool. The
   loaded Skill context contains guidance and tool IDs, not tool definitions or
   credentials.
5. Two Skills can reference the same Connector tool without duplicating its
   definition or execution implementation.
6. An agent can execute a known Connector tool ID through the common executor
   without calling discovery first.
7. An agent can discover the available Connections and Connector tools when it
   does not already know a tool ID.
8. The executor uses current workspace permissions and tool schema, and refuses
   dispatch when there is no usable Connection.
9. One matching Connection resolves automatically. Multiple matching
   Connections require explicit selection.
10. The connection-kind enum has no `skillCredential` or
    `appSkillCredential` cases before release.

## Suggested implementation tickets

1. **Move tool catalog and execution ownership to Connectors.** Define reusable
   Connector tool IDs, schemas, templates, and execution metadata independently
   from Skill definitions. Preserve existing execution semantics.
2. **Use generic Connections for connector credentials.** Update the
   `service_connections` kind enum and remove skill-owned credential kinds.
   Keep capability filters in the Connector catalog, not in credential data.
3. **Make Skills reference Connector tools.** Store stable tool-ID references;
   make Skill load return instructions only. Support multiple Skills using one
   tool.
4. **Add shared discovery and execution.** Add common discovery for Connections
   and tools plus a common executor. Validate permissions, current schema, and
   Connection availability at execution time; handle zero, one, and multiple
   matching Connections.
5. **Connect the user experience.** Show Connector capability filters and
   connection state. Make linked Skill guidance available from Connection/tool
   availability without a separate Skill toggle.
