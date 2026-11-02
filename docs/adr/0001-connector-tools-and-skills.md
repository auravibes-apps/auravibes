# Connector tools and Skills

- Status: Accepted
- Date: 2026-10-20

This ADR sets the architecture boundary. See the [feature spec](../specs/connector-tools-and-skills.md)
for user behavior, acceptance criteria, and suggested implementation tickets.

## Context

The current runtime stores tool specifications under Skills and adds them to
loaded Skill manifests. Users expect connecting an integration such as Notion
or Gmail to make its capabilities available without finding and enabling a
separate Skill. Users also need to create use-case Skills that teach agents how
to use shared tools without owning or loading those tools.

## Decision

Use **Connector** for an integration catalog entry and **Connection** for a
workspace's configured access to that Connector. A Connector may provide models,
tools, or both. The UI filters Connectors by catalog capabilities, such as
“Only connectors with tools”; do not persist a role tag for this distinction.

Store connector credentials in generic `service_connections` records. Update
the connection-kind enum before release to remove the skill-specific
`skillCredential` and `appSkillCredential` cases. Connector identity belongs
to the service connection; model/tool capability does not belong in its
credential kind.

Own Connector tool definitions, templates, and execution independently from
Skills. Skills reference one or more Connector tool IDs and contain use-case
instructions only. A Skill may be authored without a Connection; at runtime,
make guidance available when its required tools have an enabled Connection.
Connecting a Connector must make related guidance available without a separate
manual Skill toggle.

Use a common executor to resolve the current workspace, enabled Connection,
permissions, tool revision, and schema before dispatch. Discovery of available
Connections and Connector tools is optional when Skill instructions already
identify the tool. Resolve a tool automatically when one matching Connection
exists; require an explicit choice when several match.

## Consequences

- Connector tools can be reused by any Skill and by future product surfaces.
- Loading a Skill adds guidance only; it does not install or inject tool specs.
- Credentials and tool execution no longer depend on Skill-owned credential
  records.
- The current skill-owned tool runtime must migrate to Connector-owned tools.

Workflow node design and MCP tool discovery are outside this decision. See
[ADR 0002](0002-workflow-connector-tool-nodes.md) for the separate Workflow
node decision.
