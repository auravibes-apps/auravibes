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
can offer models, Connector tools, or both. The Connectors UI filters by offered
capabilities, such as “Only connectors with tools”; capability filters are not
credential kinds or persisted role tags.

## Connection

A Workspace's configured access to a Connector, including its credentials and
public configuration. Connections use the generic `service_connections`
credential store. One Connector can have multiple Connections.

## Connector tool

A reusable operation offered by a Connector, such as reading a Notion page.
Tool definitions, templates, and execution belong to the Connector, not to a
Skill. A Workflow node refers to a Connector tool by stable tool ID; it does
not own a Connection or credential.

## Connector tool schema

The input and output shape declared for one Connector tool. Connector input
field names and types are fixed by this schema. Its output schema may be shared
by Workflows that use the tool, or overridden for one Workflow.

## Workflow

A named, reusable item in a Workspace Directory. It has stable identity,
folder location, name, description, revision, and lifecycle. Its graph is the
Workflow definition.

## Workflow definition

The directed acyclic graph stored inside a Workflow item. It contains node
configuration and links. It has no separate Directory identity.

## Workflow node

A step in a Workflow definition. Users may give a node a custom canvas label;
its menu also shows its canonical type or Connector/tool name. Data inputs and
outputs are schema fields configured inside the node, not visible connection
ports. Condition nodes have visible True and False branch handles.

## Canvas selection

The Workflow node or node link currently active in the editor. Selecting a node
opens its configuration menu; selecting a link exposes its delete action. An
empty-canvas tap or Escape clears the selection.

## Inputs node

The single required source node in each Workflow. It declares the Workflow's
caller-supplied fields, including name, type, required state, description,
default, and nested object or array shape.

## Output node

A named terminal result contract in a Workflow. A Workflow has at least one;
each Output node owns an independent result schema and ends its route when the
future Workflow runtime executes.

## Connector tool node

A Workflow node that invokes one Connector tool. The node stores the stable
tool ID. At execution, the active Workspace supplies a usable Connection.

## Condition node

A Workflow node that evaluates typed rules and routes each event through its
True or False branch. Missing or null required values make the run invalid.

## Transform node

A Workflow node that produces named values using typed operations such as
field selection, object or array construction, string templates, arithmetic,
and explicit casts. It does not execute arbitrary user code.

## Node link

A directed connection between Workflow nodes. It controls which step follows
an incoming event; data values are selected through node fields. A Condition
link also identifies the True or False outcome. Links can be selected and
deleted independently of the nodes they connect.

## Data binding

A node input's reference to a value produced by an earlier node. The reference
uses a stable source node ID and JSON Pointer field path. An input can instead
use a static value.

## Workflow-local schema

An output schema override stored with one Workflow. It takes precedence over
the shared schema for the Connector tool in that Workflow only.

## Skill

Use-case guidance, such as “use Notion for CRM.” A Skill can reference one or
more Connector tool IDs. Loading a Skill adds its instructions; it does not
load, install, or own those tools or their credentials. Skills are not Workflow
nodes.
