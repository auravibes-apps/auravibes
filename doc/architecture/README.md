# Architecture Docs

Start here when reading the repo from GitHub.

## Read Order

1. [Target Architecture](./target-architecture.md) - app layer rules and file placement.
2. [Package Boundaries](./package-boundaries.md) - what belongs in the app, engine, UI package, and Widgetbook.
3. [Use Cases Pattern](./usecases-pattern.md) - business workflow rules.
4. [Notifier Pattern](./notifier-pattern.md) - Riverpod mutable state rules.
5. [Glossary](../../docs/concepts/glossary.md) - Connector, Connection, Connector tool, and Skill terms.

## Agent Skills

Short agent-facing versions live outside these docs:

- `.agents/skills/app-architecture/SKILL.md`
- `.agents/skills/package-architecture/SKILL.md`

Keep this folder for durable architecture rules. Do not keep audits, temporary plans, or one-off research notes here.

## Current Agent Tool Boundary

Dynamic skills are exposed through fixed `list_skills`, `load_skill`,
`unload_skill`, `list_skill_credentials`, and `call_skill_tool` provider tools.
Loaded skill context contains the authoritative-at-generation manifest for model
guidance. Execution never trusts that manifest: app and server resolve current
state, permission, revision, and schema before dispatch.

See [Package Boundaries](./package-boundaries.md#auravibes_engine) for skill and
agent ownership. The accepted target separates reusable Connector tools from
Skill guidance; see [ADR 0001](../../docs/adr/0001-connector-tools-and-skills.md).

## MCP Apps in Chat Results

[MCP Apps Host](./mcp-apps-host.md) maps tool metadata, result data, approval,
resource loading, and the isolated embedded view.
