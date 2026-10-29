# Glossary

## Workspace

A place that groups conversations, agents, connections, and settings. Local
and cloud describe where a Workspace lives, not different user concepts.

## Conversation

An ongoing exchange where users request work and review results, including
messages and tool activity. A Conversation belongs to a Workspace.

## Agent

A reusable AI helper with instructions and selected Skills. Connections provide
its access to services; the Agent does not own connection credentials.

## Connector

An integration in the catalog, such as Notion, Gmail, or OpenAI. A Connector
can offer models, connector tools, or both. The Connectors UI filters by offered
capabilities, such as “Only connectors with tools”; capability filters are not
credential kinds or persisted role tags.

## Connection

A workspace's configured access to a Connector, including its credentials and
public configuration. Connections use the generic `service_connections`
credential store. One Connector can have multiple Connections.

## Connector tool

A reusable operation offered by a Connector, such as reading a Notion page.
Tool definitions, templates, and execution belong to the Connector, not to a
Skill. Any Skill can reference a Connector tool by ID.

## Skill

Use-case guidance, such as “use Notion for CRM.” A Skill can reference one or
more Connector tools. Loading a Skill adds its instructions; it does not load,
install, or own those tools or their credentials.
