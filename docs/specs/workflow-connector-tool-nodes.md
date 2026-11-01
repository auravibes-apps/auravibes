# Workflow Directory Items and Node Graphs

- Status: Accepted
- Date: 2026-10-31
- Amended: 2026-11-01 (value binding and static value UX)
- Decision: [ADR 0002](../adr/0002-workflow-connector-tool-nodes.md)

## Goal

Let people create and maintain reusable Workflows inside the Workspace
Directory. Build each Workflow from Connector tools and clear logic steps.
Choose input values without guessing at hidden ports or requiring a sample run.

## Scope

This change covers the Workflow item model, local and cloud storage, Directory
actions, chat item tabs, AI Directory reads, node editing, value binding, static
value editors, schemas, sampling, and the UX audit.

Whole-Workflow execution is out of scope. The editor may run one read-only
Connector tool to infer its output shape. It never runs a write tool for
sampling.

## Workflow item and storage

- A Workflow is a first-class Directory item with stable ID, Workspace, parent
  folder, name, description, revision, and lifecycle.
- `WorkflowDefinition` stores node configuration and graph links. It does not
  own a separate Directory identity.
- Add the new local Drift schema and cloud Workflow resource from the merged
  `origin/main` baseline. Keep Directory metadata and lifecycle consistent
  across local and cloud storage.
- Directory supports create, list, rename, move, duplicate, trash, and restore.
  A duplicate gets a new item ID and preserves Connector/tool and nested
  Workflow references.
- Trashing a referenced Workflow keeps its stable reference. Show its nested
  node as unavailable until the Workflow is restored or repaired.
- Do not migrate unpublished prototype rows or legacy Skill-node data.

## Directory, AI, and chat entry points

- Create a Workflow from the current Directory folder. Creation saves the item
  and opens its editor.
- Do not add a top-level Workflows sidebar destination or a separate discovery
  command.
- Existing chat item tabs can open, restore, save, close, and return to a
  Workflow. Preserve the current save lifecycle and never discard unsaved edits
  silently. Cover compact and expanded layouts.
- Extend `readDirectory` path/name search and `readItem` to include active
  Workflows. Use the same Workspace access checks. Exclude deleted and
  unauthorized items.

## Graph and node model

- The graph is a directed acyclic graph. A link connects node cards, not data
  fields. Selecting a value from an earlier node creates or confirms a
  dependency link.
- Fan-out successors run independently for each incoming event. Any incoming
  route can trigger a node. A node receiving several routes gets a separate
  event from each route.
- Each node has a stable node ID, a user-editable canvas label, and a canonical
  internal kind/name. Keep the canonical Connector and tool names visible in
  the node menu. Show the stable Connector tool ID in details.
- Connector parameter names and types come from the Connector tool schema and
  cannot be changed in a Workflow. Configure values as node attributes in the
  node menu; do not show data input/output ports.
- A data binding stores stable source node ID and JSON Pointer path internally.
  The user-facing flow does not show JSON paths, JSON Schema documents, or raw
  JSON value text. A selected value appears as a chip labeled `Node label ·
  readable field label`; static values appear without a chip.
- Keep the previous-value chooser closed until a user opens it from the value
  field. Search readable field names, group results by eligible earlier node,
  and include nested fields without showing their JSON paths. Show only values
  available on every incoming route. Block incompatible values with a plain
  explanation; an `any` value needs an explicit Transform cast before it binds
  to a typed Connector input.
- Use type-appropriate static controls: text and numeric fields, a Boolean
  toggle, guided fields for objects, and addable/removable rows for arrays.
  Edit nested values recursively. Show descriptions, defaults, required
  markers, and an explicit null option for nullable fields; keep unset optional
  fields distinct from null. Keep schema editing separate from entering a
  value. Do not ask users to type raw JSON for static values.
- When switching a static value to a binding, preserve its static draft with
  the Workflow and restore it when users switch back, including after save,
  close, and reopen. If no draft exists, use the schema default. Persist draft
  presence separately from the nullable value so an explicit `null` round-trips
  correctly. Source deletion or schema drift must not silently discard the
  draft; flag incompatible values for repair.
- Present the same searchable chooser as a scrollable bottom sheet in the
  compact editor and a bounded dialog in the wide editor. Support keyboard and
  touch, dismiss through outside tap/Back/Escape, and return focus to the field.
- Deleting a source node removes its links. Retain dependent bindings as
  visible broken references and require repair. Do not silently clear them.

### Required endpoint nodes

- Create one Inputs node and one Outputs node when a Workflow is created.
- Inputs is the only source node. It has no incoming links, cannot be deleted,
  and supports named fields with type, required state, description, optional
  default, and nested object/array schema.
- At least one Output node is required. Create one by default; allow more.
  Users may delete extra Outputs but cannot delete the last one.
- Each Output is an independent named result contract and terminal node. It
  may receive multiple routes, but its fields may bind only values common to
  every incoming route. Missing result fields serialize as JSON `null`.
- Each Output has its own result schema. When its future runtime executes, that
  Output ends its route.
- Schema editors support string, integer, number, boolean, object, array, and
  nullable values.

### Connector tool nodes and schemas

- The node picker lists real Connector tools before a Connection exists.
  Group by Connector; search Connector and tool names; show operation
  descriptions and visible Connection/access requirements. Do not include
  Skill, Agent, or system-tool nodes.
- A Connector tool node stores a stable tool ID, never a Connection ID or
  credential. Resolve a usable Connection from the active Workspace at
  execution. If several Connections match during sampling, ask which one to
  use and do not save the choice.
- One shared output schema belongs to each Connector tool and applies to
  Workflows using that tool. A Workflow-local schema overrides only that
  Workflow. Prefer local schema when present; otherwise use the shared schema.
- Users can edit shared per-tool output schemas and Workflow-local output
  schemas. Workflow-local output fields may use arbitrary names and types.
  A type change alters the Workflow contract; use an explicit Transform when
  the source value type differs. Keep canonical Connector schema unchanged by
  local edits.
- When no shared or Workflow-local schema exists, allow users to define JSON
  Schema, paste an example output, or sample a read-only tool with temporary
  inputs. Write-capable tools are never dispatched for sampling; require a
  pasted JSON example instead.
- A JSON object infers one schema field per top-level property. Nested values
  remain objects or arrays. A scalar or top-level array infers one `Result`
  field. Non-JSON text infers `Result:string`.
- Repeated samples merge into an inferred schema. A field absent from any
  sample becomes optional. Conflicting types become `any`.
- If an example/sample differs from an existing schema, ask whether to keep the
  current schema, create a Workflow-local override, or edit the shared schema
  separately. Never update the shared schema as a side effect of sampling.
  Approval replaces the selected schema with the inferred shape.
- Discard raw sample inputs, raw outputs, and pasted example values after
  inference. Cloud sampling returns shape-only results to the app.

### Condition nodes

- A Condition node has visible True and False branch handles. Other node types
  have no visible data ports.
- Configure one or more rules from a source field, type-compatible operator,
  and static or bound comparison value. Group rules with explicit All/Any.
- Offer type-aware equality, exists/is-empty, numeric comparisons, and string
  matching. Hide operators that do not fit the selected field type.
- Missing or null required input marks a run invalid/error. Do not route it to
  False silently or add a third branch.

### Transform nodes

- A Transform node can define multiple named output fields.
- Provide typed operations for field selection, object/array construction,
  string templates, arithmetic, and explicit casts.
- Give each operand a name. String templates insert named operands with
  `{{operand name}}` placeholders. Object construction uses operand names as
  keys.
- Keep configuration in forms. Do not add arbitrary code or a hidden
  expression language.

## Canvas, menus, and recovery

- Use Flutter `FocusNode`s for canvas nodes and links. Selecting/focusing a
  node marks it selected and opens its inspector. Keep that selection while
  keyboard focus moves into inspector controls. The node focus ring follows
  actual keyboard focus and disappears when an inspector field receives
  focus; the selected outline and inspector stay open. Selecting/focusing a
  link highlights it and shows no node inspector.
- Tab/Shift-Tab follows Workflow order: Inputs, upstream-to-downstream nodes,
  each node's outgoing links, Condition True before False, and Outputs last.
  Use canvas position to order peers. Enter/Space activates the focused item;
  Escape clears selection. Empty-canvas taps clear node or link selection;
  panning preserves selection.
- A selected link has one floating trash button at its midpoint. Confirm link
  deletion by naming the source, Condition branch when present, and target.
- Put an external add item on ordinary nodes. Clicking it opens node selection.
  Choosing a type creates a linked node beside the source, selects it, and
  opens its menu. Dragging an add item previews a branch-aware link. Dropping
  it on a valid target creates the link and focuses the target. An invalid
  target shows why it rejects the link and cancels on release. An empty drop
  cancels without creating a link.
- Condition True/False handles visibly connect outcomes to target nodes.
- Let users pan in any direction without a visible canvas edge. Keep the grid
  continuous across the viewport. Node X/Y positions may be any finite value,
  including negative values; reject NaN and infinity. Remove app/server
  0-to-10,000 coordinate bounds and keep the existing 100-node and 100-link
  Workflow limits.
- Node menus close with an explicit close button, Escape/back, or outside tap.
- Every node deletion requires confirmation naming the node and links removed.
  If deletion breaks data bindings, preserve them and show repair state.
- Show clear connection-required, missing-tool, schema-drift, invalid-binding,
  sample-error, empty, loading, and save states. Explain recovery actions.
- Localized UI uses the existing app language and components. Optimize for
  everyday users; Connector IDs and JSON Pointer are advanced details, not the
  primary selection surface.

## UX audit deliverable

Audit every user-visible surface in the branch diff, plus the changed Directory
and chat item paths. Follow the task from creation through save, close, reopen,
and repair. Include evidence source, severity, confidence, recommendation, and
verification scenario for each finding. Use rendered captures where available;
label code-only findings as source-based. Apply the recommendations that fit
this integration.

## Acceptance criteria

1. A Workflow is created in the current Directory folder with required Inputs
   and Outputs nodes and opens in the editor.
2. Local and cloud stores list, save, rename, move, duplicate, trash, and
   restore Workflows with the same item metadata and authorization.
3. Duplicates get new item IDs while retaining Connector/tool and
   nested-Workflow references. Trashed references remain visible as unavailable
   and recover when the target returns.
4. AI path/name searches include active Workflows; `readItem` returns the graph
   only when the item belongs to an authorized Workspace.
5. Directory and chat item tabs open, save, close, restore, and return to
   Workflows in compact and expanded layouts without silent edit loss.
6. Picker lists real Connector tools while disconnected, groups and searches
   them, shows operation details and Connection requirements, and excludes
   Skill, Agent, and system-tool nodes.
7. Connector parameter names/types are immutable; node menus show canonical
   tool identity, support bindings/static values, and close through every
   approved method.
8. Selecting a source field creates/confirms a node dependency link. Bindings
   store stable source node IDs and JSON Pointer paths internally. Users see a
   source-and-field chip, not a path. Incompatible and unknown types require
   repair or explicit Transform casts.
9. Canvas add items create/connect nodes by click or drag. Condition nodes show
   only True/False handles. Plus dragging previews links, validates targets,
   explains rejected drops, and selects the target after connection.
   Fan-in/fan-out graph rules are validated.
10. Inputs schemas support requested fields and nested JSON types. Multiple
    named Outputs have independent schemas, require common values across their
    incoming routes, and serialize missing fields as null.
11. Condition rules support All/Any groups and type-aware operators. Missing
    required values mark the run invalid. Transform nodes support the listed
    typed operations without arbitrary code.
12. Shared Connector tool schema and Workflow-local overrides use the defined
    priority. Schema drift prompts before changes; approved replacement
    updates only the selected scope.
13. Read sampling uses temporary inputs and returns inferred shape only. Write
    tools never run for sampling. Raw samples/examples never persist. Repeated
    samples merge fields, mark missing fields optional, and use `any` for
    conflicts.
14. Node deletion confirms affected links, removes links, and retains broken
    bindings for repair.
15. Nodes and links follow the agreed keyboard focus order. Node inspector
   selection survives inspector input focus; blank taps and Escape clear it.
   Link selection shows a midpoint delete action with endpoint confirmation.
16. The infinite canvas keeps a continuous grid while panning without bounds.
   App and server accept signed finite node coordinates and reject non-finite
   coordinates while retaining collection limits.
17. The UX audit records evidence, severity, confidence, recommendations, and
    verification scenarios. Rendered checks are used where available.
18. No whole-Workflow execution or legacy Skill-node compatibility is added.
19. Static values use type-appropriate controls; object and array values use
    guided editors without raw JSON. Editors honor defaults, required and
    nullable fields, and distinguish unset from null. A bound value retains its
    inactive static draft across save/reopen. The on-demand grouped chooser
    works in compact and wide layouts and shows no JSON paths or schema
    documents.
