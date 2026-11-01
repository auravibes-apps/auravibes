# Workflow Directory Items and Node Graphs

- Status: Accepted
- Date: 2026-10-31
- Amended: 2026-11-01 (canvas interaction and coordinate bounds)
- Supersedes: Workflow node and output-schema decisions in the previous version

## Context

Workflows need stable Directory identity, folder location, lifecycle, and a
reusable graph. Their editor must use real Connector tools and make each step's
inputs, results, branches, and recovery states understandable to people who do
not need to know port IDs or Connector internals.

The earlier prototype used editable data ports and a single Workflow-level
output signature. The feature has not shipped. There is no published Skill-node
or prototype-data contract to preserve.

## Decisions

### Workflow item and access

- A Workflow is a first-class Workspace Directory item. Its stable ID,
  Workspace, parent folder, name, description, revision, and lifecycle belong
  to the item. `WorkflowDefinition` stores its graph and remains separate from
  item identity.
- Local Drift storage and cloud Workflow resources use the same Directory
  metadata and lifecycle semantics. Add a new schema from the merged main
  baseline; do not migrate unpublished prototype or Skill-node data.
- Directory owns Workflow creation, listing, rename, move, duplicate, trash,
  and restore. A duplicate gets a new item ID and keeps Connector/tool and
  nested-Workflow references.
- A trashed nested Workflow remains referenced. Show it as unavailable until
  restored or repaired.
- Open Workflows from Directory and existing chat item tabs. Do not add a
  top-level Workflows sidebar destination or separate AI discovery tools.
- AI uses existing `readDirectory` search and `readItem` paths. Apply the same
  Workspace authorization checks and exclude deleted or unauthorized items.

### Node graph

- A Workflow definition is a directed acyclic graph. Links connect nodes, not
  Connector input or result fields. Selecting a value from an earlier node
  creates or confirms the dependency link.
- Fan-out successors run independently for each incoming event. Any incoming
  route can trigger a node; the same node can receive separate events from
  several routes.
- Connector fields are configured inside the node menu. Connector parameter
  names and types follow the Connector tool schema and are not user-editable.
  Data bindings use a stable source node ID and JSON Pointer path. Inputs may
  also use static values. Show a searchable, expandable result tree when schema
  is known; allow JSON Pointer entry when users know a path without sampling.
- Show only source values available on every incoming route to one node. An
  unknown (`any`) value needs an explicit Transform cast before it binds to a
  typed Connector input.
- Each Workflow starts with one required, non-deletable Inputs node and one
  Output node. Users can add Outputs but cannot delete the last one. Each
  Output is an independent named result contract and a terminal node. One
  Output can receive several routes but can bind only values common to them.
  Missing result fields serialize as JSON `null`.
- Supported node kinds are Connector tool, Inputs, Outputs, Condition,
  Transform, and nested Workflow. Workflow Skill, Agent, and system-tool nodes
  are not supported.
- A node has a customizable canvas label. Its menu keeps the canonical node or
  Connector/tool name visible; show the stable tool ID in details.

### Branches and transforms

- Only Condition nodes show branch handles. They expose True and False
  outcomes. A Condition selects a source field, type-compatible operator, and
  static or bound comparison value. It supports grouped All/Any rules.
- Operators are type-aware: equality, exists/empty, numeric comparisons, and
  string matching. Missing or null required input makes a run invalid; it does
  not silently route to False.
- Transform nodes can create multiple named output fields with typed
  operations: field selection, object/array construction, string templates,
  arithmetic, and explicit casts. Do not support arbitrary code or hidden
  expression languages.

### Connector schemas and sampling

- A shared output schema belongs to one Connector tool and is reused by
  Workflows that call that tool. A Workflow-local schema overrides the shared
  schema only in that Workflow. Local schema wins when present.
- Connector tool inputs remain defined by the canonical tool schema. Users may
  edit shared tool output schema or a Workflow-local output schema. Workflow
  output fields can use custom names and types; a type change changes the
  Workflow contract and requires a Transform when its source type differs.
- When no declared schema exists, users may define JSON Schema or provide an
  example output. A read-only Connector tool may also run with temporary sample
  inputs to infer output shape. A write-capable tool is never dispatched for
  sampling; require pasted JSON instead.
- A JSON object infers top-level fields; nested objects and arrays remain
  nested. A scalar or top-level array infers one `Result` field. Non-JSON text
  infers `Result:string`. Multiple samples merge into one inferred shape:
  fields absent from any sample become optional, and conflicting types become
  `any`.
- Never persist raw sample inputs or outputs. Cloud sampling returns only the
  inferred shape to the app.
- If a sample differs from an existing schema, ask whether to keep the current
  schema, create a Workflow-local override, or edit the shared schema
  separately. Never change a shared schema as a side effect of sampling. After
  approval, replace the selected schema with the inferred shape.
- Resolve the active Workspace Connection when a tool executes. A Workflow
  stores a stable Connector tool ID, never a Connection ID or credential.

### Editor behavior and execution scope

- A node's external add item opens node selection when clicked. Choosing a
  node creates and connects it beside the source, selects it, and opens its
  menu. Dragging the item onto an existing node creates a link.
- Node menus close through an explicit close button, Escape/back, or outside
  tap. Deleting a node requires confirmation that names the node and links
  removed. Deletion removes links but retains downstream bindings as broken
  references that need repair.
- The editor saves definitions but does not execute whole Workflows. Isolated
  Connector read sampling is the only execution in this scope. Output nodes
  are modeled as terminal contracts for a future runtime.

### Canvas selection and navigation

- Use Flutter `FocusNode`s for Workflow nodes and links. Keep editor selection
  separate from keyboard focus in inspector controls so users can edit a node
  without closing its menu. The node focus ring follows actual keyboard focus
  and disappears when an inspector field receives focus; the selected outline
  and inspector stay open.
- Node focus selects the node and opens its inspector. Link focus selects the
  link without opening the inspector. Show a floating delete action at the
  link midpoint and confirm using its source, Condition branch when present,
  and target.
- Keyboard traversal follows Workflow order: Inputs, upstream-to-downstream
  nodes, each node's outgoing links, Condition True before False, and Outputs
  last. Use canvas position to order peers. Enter/Space activates; Escape
  clears selection. Empty-canvas taps clear node or link selection; panning
  preserves it.
- Clicking a node's plus handle keeps opening node selection. Dragging it
  previews a branch-aware link. Valid drop creates the link and focuses its
  target. Invalid targets explain why and cancel on release; empty drops
  cancel.
- The canvas has no visible boundary and keeps its grid continuous while
  panning. Node positions accept any finite signed coordinates. App and server
  reject NaN and infinity but do not impose a coordinate range. Keep the
  existing 100-node and 100-link Workflow limits.

## Consequences

- Local and cloud storage need Directory-owned Workflow metadata, graph
  persistence, and standard item lifecycle operations.
- Connector tool schema storage needs a shared per-tool schema and an optional
  Workflow-local override. Sampling paths must return shape-only results and
  discard raw values.
- The graph model no longer uses data-port IDs. Condition branch outcomes are
  the only visible connection handles.
- Infinite canvas rendering is viewport-relative; scene size must not depend
  on the largest stored node coordinate. App and server accept signed finite
  coordinates and retain finite-number validation plus collection limits.
- Canvas focus is transient editor state. Links need no new persisted ID; the
  existing source, target, and optional Condition branch identify a link.
- Multiple named Output contracts support branching without a port-mapping UI.
  Routes into one Output must share the fields it binds.
- Existing AI Directory commands and chat tabs can reach Workflows without
  parallel discovery or navigation systems.
- No Skill-node decoder or prototype-data migration is required.

## Related

- [Workflow item and node behavior spec](../specs/workflow-connector-tool-nodes.md)
- [Shared glossary](../concepts/glossary.md)
- [Connector tools and Skills ADR](0001-connector-tools-and-skills.md)
