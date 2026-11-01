# Workflow node redesign — grill notes

**Status:** Core and canvas interaction designs confirmed; final docs and
implementation complete. Temporary decision log, not the accepted spec.
**Started:** 2026-10-29
**Branch baseline:** `codex/workflow-builder-managed-20261013` at `3285a926`

Keep this file through the interview and any context compaction. Record each
answer under its question. Do not treat recommendations as user decisions.
Create final ADR, glossary and implementation spec only after the design tree
is closed and the user confirms the shared understanding.

## User-stated direction

- Node menus must close.
- Connector-bound input names and types must not be user-editable.
- Nodes have a customizable display name and a separate internal name that
  remains visible in the node menu.
- Workflow inputs should be selectable as a node; its menu should configure a
  clear input schema.
- Deleting a node requires confirmation.
- Connect nodes to nodes, not ports. A node represents the next step in the
  action flow. Ports may disappear and may become node inputs or attributes.

## Decisions carried from earlier approved workflow plan

- Workflow is a Directory item; its identity/lifecycle stays separate from its
  graph definition.
- Connector tools remain visible before a workspace connection exists. Nodes
  retain stable tool IDs; execution resolves the active workspace connection.
- Read-tool sampling uses temporary inputs. Write-tool sampling requires
  pasted JSON. Discard raw sample values. An approved schema override replaces
  the selected schema with inferred shape; this supersedes earlier merge advice.
- No compatibility for unpublished Skill-node or prototype workflow data.
- Whole-workflow execution was previously out of scope. Reconfirm this because
  the new design describes nodes as the next action step.

## Implementation baseline facts

- `WorkflowNode` stores `kind`, `targetId`, editable `label`, `inputs` and
  `outputs` in `apps/auravibes_app/lib/features/workflows/models/workflow_definition.dart`.
- `WorkflowConnection` references source and target port IDs in that same file.
- `WorkflowNodeKind` currently has system tool, agent, Connector tool and
  nested Workflow kinds. It has no Workflow Inputs node.
- `WorkflowPortGroup` edits port names, types, required state and membership.
- The canvas renders input/output port groups and the signature boundary cards.
- `WorkflowInspectorPanel` is persistent beside the canvas on expanded layout
  and appears below the canvas after node selection on compact layout. It has
  no explicit panel-close action. Node deletion currently runs immediately.
- Workflow-level inputs and outputs currently use the signature editor and
  visible boundary cards.
- The glossary defines a Workflow definition as a graph of inputs, outputs,
  nodes and connections. The node-to-node model is not defined yet.

## Decision changes and resolved boundaries

- Condition and Transform nodes are in scope, superseding the earlier
  “no conditional branches yet” recommendation. Condition and event-trigger
  behavior is now defined; whole-Workflow runtime remains deferred.
- Connector nodes may have many input and output fields. Whole-node links can
  connect to many nodes; field bindings choose the specific values.
- Connector parameter fields stay schema-locked. Workflow-local output schema
  can use arbitrary field names and types; type conversion requires Transform.
- Condition alone has visible True/False handles. Ordinary node data fields
  stay inside node menus.
- Inputs is one required, auto-created node. Outputs has one default, permits
  additional nodes, and requires at least one.
- User permits multiple Outputs nodes. Each Output is terminal and stops its
  route when runtime exists; this supersedes the single-Outputs-node and
  per-branch mapping models.
- Connector output schema may be shared at Connector scope or configured per
  Workflow. Workflow-local schema wins; shared schema is fallback. Examples
  and safe read samples infer only when both are absent.
- Repeated samples merge into one inferred shape: absent fields become
  optional and conflicting types become `any`. If user approves an override,
  replace the selected local or shared schema with that inferred shape. Never
  update shared schema without an explicit choice.
- A sample drift prompt offers keep current, create local override, or edit
  shared schema separately. Approved override replaces selected schema.
- Typed paths use JSON Pointer only; this supersedes the earlier dotted-path
  preference. The picker may still show readable field names.
- Output nodes may receive multiple routes but can bind only values common to
  all incoming routes. Distinct branch results use separate Output nodes.
- Ordinary node connections and post-pick behavior are defined in Round 5/6.
- Round 11 confirmed each Output's result schema and one shared schema per
  Connector tool.

## Interview record — answered rounds

### Round 1 — answered at interview

1. **What does a node link mean?**
   Open: order only, data dependency, or both. Recommended: link means the
   target is a next step and can read the source node's structured result;
   users configure data bindings inside the target node menu.
   **Answer:** A node may bind values from earlier nodes, including deep JSON
   results. Users may also type a known value without sampling, or enter a
   static value. Binding UX must make source values easy to find and select.

2. **Should the graph be a sequence or allow branches?**
   Recommended: allow a directed acyclic graph with fan-out and fan-in; every
   linked successor is a next step. Keep conditional branching out until a
   condition node exists.
   **Answer:** DAG with fan-out and fan-in; no conditional branches yet.

3. **How should Workflow Inputs appear?**
   Open: one configurable source node per Workflow, or one node per input
   field. Recommended: one source node with a schema editor for all named
   fields; configure name, type, required state and optional default there.
   **Answer:** One Inputs node with a schema editor.

4. **What is the visible internal name?**
   Recommended: keep the user's custom label on the canvas; show the canonical
   Connector and tool names in the menu; put the stable tool ID in details.
   **Answer:** Show canonical Connector and tool names; stable ID in details.

5. **What happens when Connector schema changes?**
   Recommended: use the current Connector schema for field names and types,
   preserve compatible values, and flag removed or incompatible values for
   repair instead of silently deleting them.
   **Answer:** Preserve compatible values; flag removed or incompatible fields
   for repair.

6. **How should node menus close, and when should deletion confirm?**
   Recommended: close with an explicit close button, Escape/back and outside
   tap; closing only dismisses the menu. Confirm every delete and name the
   node plus any links removed.
   **Answer:** Close button, Escape/back and outside tap. Confirm delete and
   name the node and links removed.

7. **Does the editor remain non-executable for this redesign?**
   Recommended: yes; define the graph model now, keep whole-Workflow execution
   out of scope, and retain isolated single-Connector read sampling.
   **Answer:** Keep whole-workflow execution out of scope; allow isolated
   Connector read sampling.

## Round 2 — answered at interview

1. **How does a value reference affect node links?**
   Recommended: a binding to an earlier node creates or requires a dependency
   edge; users can also add control-flow edges without binding a value. The
   picker lists only nodes that can safely precede the current node.
   **Answer:** Selecting a source field creates or confirms the dependency
   link between its node and the target node.

2. **How can users browse deep JSON fields?**
   Recommended: show a searchable, expandable field tree grouped by prior node;
   let users select a field path and preview its type. Include fields known
   from schema without requiring a sample run.
   **Answer:** Searchable expandable tree grouped by node; show field types and
   known schemas, including schemas available without sampling.

3. **How should users enter each node input?**
   Recommended: every input field has a clear source mode: bind a value, enter
   a static value, or type a known dynamic value/path. Keep JSON editing as an
   escape hatch for complex values.
   **Answer:** Each node input can browse to a prior value, accept a known
   binding path typed by the user, or use a static value.

4. **Where does a node's output schema come from if user skips sampling?**
   Recommended: use declared Connector output schema when available; otherwise
   allow users to add/edit expected fields manually. Sampling may merge field
   shapes later, but never stores sample values.
   **Answer:** Use declared Connector schema when available. Otherwise let
   users add expected output fields. Samples may refine field shapes, but raw
   sample values are discarded.

5. **How should workflow results be defined?**
   Recommended: one selectable Outputs node with named fields bound to inputs
   or prior node results; this makes the saved Workflow contract explicit.
   **Answer:** One Outputs node declares named result fields bound to workflow
   inputs or earlier node results.

6. **What do node-to-node links look like on canvas?**
   Recommended: connect whole node cards with one link handle per card; show
   data mapping inside the target node menu, not as port handles.
   **Answer:** Show one link for whole nodes; configure data bindings in the
   target node menu.

7. **What fields belong in the Workflow Inputs schema?**
   Recommended: name, type, required state, description and optional default;
   allow object/array types with JSON schema editing for nested shapes.
   **Answer:** Include name, type, required state, description and optional
   default. Support nested objects and arrays.

## Future decision areas — resolved in later rounds

Canvas link gestures, branch rendering, field-path syntax, endpoint nodes,
Transform schema, and fan-out semantics were resolved in later rounds below.

## Round 3 — answered at interview

1. **How should users type a binding they know?**
   Recommended: choose a source node, then browse or type a field path; store
   the stable source-node ID and path. Avoid requiring users to type an
   internal ID or an expression language.
   **Answer:** Choose the source node, then browse or type its field path; store
   the stable node ID and field path.

2. **Who owns output field names and types?**
   Recommended: lock Connector-declared names/types. When schema is missing,
   let users define expected fields. Samples merge shape; conflicts become
   `any` as previously approved. Flag invalid bindings for repair.
   **Answer:** Users can edit output fields even when the Connector declares an
   output schema. Later rounds define Workflow-local fields as editable while
   preserving canonical Connector schema; type changes require Transform.

3. **How many Inputs and Outputs nodes can a Workflow have?**
   Recommended: at most one of each; offer both in the node picker and show
   clear empty/missing-contract states until added. Outputs can remain optional
   while editing a draft.
   **Answer:** “input only out node, output only inner.” Nodes can connect to
   many nodes. A Connector can have many inputs and outputs; direct bindings
   can use any value from a triggering prior node. Exact endpoint and node
   cardinality meaning remains open.

4. **When a node has several predecessors, when is it ready?**
   Recommended: after all linked predecessors complete. Fan-out successors
   represent independent next steps; conditions remain out of scope.
   **Answer:** Any one predecessor completing can trigger the node. Whether
   each arriving predecessor triggers a separate run remains open.

5. **What happens to bindings when their source node is deleted?**
   Recommended: remove its links, retain downstream input configuration as a
   visibly broken reference, and require repair; never silently clear values.
   **Answer:** Remove links. Retain broken bindings and require repair.

6. **How strict is input type matching?**
   Recommended: allow compatible types only; explain mismatches and block
   invalid bindings. Do not coerce silently.
   **Answer:** Allow schema-compatible types; block incompatible bindings and
   explain the mismatch.

7. **Can users transform bound values?**
   Recommended: direct field binding and static JSON values only. Add
   transformations later through explicit nodes, not hidden expressions.
   **Answer:** Add an explicit Transform node in this redesign.

## Round 4 — answered at interview

1. **What does “Inputs only out node, Outputs only inner” mean?**
   Recommended interpretation: Inputs is a source with no incoming links and
   may feed many nodes; Outputs is a sink with incoming links and no outgoing
   links. Keep at most one of each.
   **Answer:** Inputs is a source; Outputs is a sink; at most one each.

2. **How do conditional nodes route branches?**
   Recommended: configure named outcomes in the node menu (for example,
   True/False); draw whole-node links and label each outgoing link with its
   outcome. No visible port handles.
   **Answer:** Use True/False ports. Whether these appear as visible handles or
   logical outcomes on whole-node links remains open.

3. **When several predecessors can trigger one node, how often does it run?**
   Recommended: each arriving branch event triggers a separate node run. This
   preserves trigger semantics and avoids waiting for unrelated branches.
   **Answer:** Once for each incoming branch event.

4. **What can a Transform node do?**
   Recommended: offer a small set of typed built-in transforms (field pick,
   rename, template/string compose, numeric operations and simple comparisons).
   No arbitrary code or hidden expressions.
   **Answer:** Typed built-ins for field pick, rename, compose, numeric
   operations and comparisons.

5. **What does editing a Connector-declared output schema change?**
   Recommended: edit only the Workflow's local expected/output shape or
   projection. Keep the canonical Connector response schema intact; flag
   mappings that the Connector cannot supply.
   **Answer:** Edit the Workflow-local expected shape or projection; preserve
   the canonical Connector schema.

6. **Does whole-Workflow execution stay out of this redesign?**
   Recommended: yes. Define Connector, Condition, Transform, Inputs and Outputs
   node models and graph behavior now; defer the runtime. Keep isolated
   Connector read sampling.
   **Answer:** Yes. Model node types now; keep isolated Connector read sampling
   and defer whole-Workflow execution.

## Round 5 — answered at interview

1. **How should True/False ports appear and connect?**
   Recommended: show two small labeled handles only on Condition nodes. Users
   drag each handle to a whole target node; ordinary data fields have no
   visible ports.
   **Answer:** Show visible True/False handles only on Condition nodes.

2. **How should users create ordinary node links?**
   Recommended: drag from a single node-level handle to a target card; allow
   multiple outgoing links. Binding a value can also create the dependency
   link automatically.
   **Answer:** Put an item outside each node. Clicking it asks which node to
   add; dragging it onto an existing node creates the connection. Exact
   post-pick placement and menu behavior are resolved in Round 6.

3. **Should fan-out successors all run for each incoming event?**
   Recommended: yes, each outgoing link triggers its successor independently.
   Condition nodes route only the matching outcome.
   **Answer:** Yes. Each outgoing link triggers its successor independently.

4. **What syntax should typed field paths use?**
   Recommended: show a readable dotted path after a source node is selected;
   use the picker for array indices or field names that need escaping. Store a
   canonical path internally.
   **Answer:** Use readable dotted paths after selecting the source node.

5. **Can users omit the Inputs or Outputs node?**
   Recommended: yes. Inputs is optional for workflows with no caller-supplied
   values; Outputs is optional for draft or side-effect workflows. Limit each
   Workflow to one of each.
   **Answer:** Both Inputs and Outputs nodes are required. This supersedes the
   optional-node recommendation. At most one each remains the current model.

6. **How should users configure a Transform node?**
   Recommended: one node can define multiple named output fields in rows; each
   row selects a typed built-in operation and binds its operands. No scripts.
   **Answer:** Multiple named output rows, each with a typed operation and
   bound operands.

7. **How should users configure a Condition node?**
   Recommended: select a source field, operator and comparison value in the
   menu; value may be static or bound. Show True/False outcomes on the node.
   **Answer:** Select a source field, operator and static or bound comparison
   value.

## Round 6 — answered at interview

1. **How should required Inputs and Outputs nodes enter a new Workflow?**
   Recommended: insert both automatically when creating the Workflow; users
   can configure them but cannot delete them.
   **Answer:** Insert both automatically; users configure but cannot delete.

2. **After clicking the external add item and choosing a node, what happens?**
   Recommended: create the new node beside the source, connect it, select it,
   and open its menu. Keep dragging the item onto an existing node as a direct
   connection gesture.
   **Answer:** Create beside the source, connect it, select it and open its
   menu. Dragging the item onto an existing node creates a connection.

3. **What edits should a Connector output projection allow?**
   Recommended: select, reorder, alias, add or remove local output fields.
   Keep each mapped field's type tied to its source; use Transform nodes to
   change types. Preserve canonical Connector names and schema.
   **Answer:** Allow arbitrary names and types in the Workflow-local output
   projection. Preserve the canonical Connector schema.

4. **Which node results can a binding use after conditional branches merge?**
   Recommended: list only values guaranteed to exist on every incoming path.
   Use Transform or Condition nodes to handle branch-specific values; do not
   silently bind a missing value.
   **Answer:** Show only values available on every incoming path; hide
   unavailable values.

5. **Can each incoming branch configure different values for the same node?**
   Recommended: use one mapping per target node, valid for every incoming
   event. Add branch-specific mappings only if users need that complexity.
   **Answer:** One mapping must work on every incoming path.

6. **How should users type paths for arrays and unusual field names?**
   Recommended: use dotted paths for ordinary fields and picker insertion for
   array indices or escaped names; store an unambiguous canonical path.
   **Answer:** Use JSON Pointer only.

**Resolved in Rounds 7–8:** branch results use multiple Output nodes; each
Output may accept several routes and binds only values common to those routes.

## Round 7 — answered at interview

1. **What does changing a Workflow output field's type do?**
   Recommended: it changes only the Workflow contract. Do not pretend the
   Connector value was converted; require a Transform node for conversion and
   flag incompatible source types.
   **Answer:** Change the Workflow contract; require Transform for conversion
   and flag type mismatches.

2. **How can branch-specific values reach the required Outputs node?**
   Recommended: let Outputs define per-branch bindings for the same named
   result fields. Validate each branch; users may set defaults for fields
   missing on a branch.
   **Answer:** Use per-branch mappings for the same result fields; validate
   each branch.

3. **Which operators should Condition expose?**
   Recommended: type-aware equals/not-equals, exists/is-empty, numeric
   comparisons, and string contains/starts-with/ends-with. Hide invalid
   operators for the selected field type.
   **Answer:** Offer type-aware equals, exists/empty, numeric comparisons and
   string matching.

4. **Which operations should Transform expose first?**
   Recommended: type-aware field selection, object/array construction,
   string templates, numeric arithmetic, and explicit casts. Keep operations
   as forms; no arbitrary code.
   **Answer:** Field selection, object/array construction, string templates,
   arithmetic and explicit casts.

5. **What should happen when a Condition input is missing or null?**
   Recommended: mark the run invalid/error; keep only True/False handles.
   Null checks should use explicit exists/is-empty operators.
   **Answer:** Mark the run invalid/error; keep only True/False handles.

6. **Can one Condition contain multiple rules?**
   Recommended: support grouped rules with explicit All/Any (`AND`/`OR`)
   matching; show the grouping in plain language.
   **Answer:** Yes. Group multiple rules with explicit All/Any matching.

## Round 8 — answered at interview

1. **Which node kinds belong in the picker?**
   Recommended: Connector tools, Inputs, Outputs, Condition, Transform and
   nested Workflow nodes. Remove unpublished Skill, Agent and system-tool
   nodes unless user confirms they remain.
   **Answer:** Connector tools, Inputs, Outputs, Condition, Transform and
   nested Workflow. Remove Skill, Agent and system-tool nodes.

2. **How does a custom Connector output field get its value?**
   Recommended: each projection row has a JSON Pointer source path into the
   raw Connector response. Use Transform nodes for computed values.
   **Answer:** A custom field has no source value by itself. Users may define a
   shared Connector schema or a Workflow-local schema, add an example output
   on the node, provide JSON Schema/example, or execute the node to derive a
   Workflow schema. Rounds 9 and 10 define priority and override behavior.

3. **How should users configure per-branch Outputs mappings?**
   Recommended: show a section for each incoming route, labeled by Condition
   and True/False outcome. Require each route's output bindings.
   **Answer:** Allow multiple Outputs nodes. Each Output terminates its route
   when executed; full runtime remains out of scope.

4. **Can an output field be absent on some branch?**
   Recommended: keep the output contract stable; require a value or explicit
   static default on every path. Do not make fields silently null.
   **Answer:** Allow missing fields to be null.

5. **How should a new sample affect user-authored output projections?**
   Recommended: update only the temporary/observed Connector schema; keep
   user-authored projections stable and show drift for repair.
   **Answer:** Keep projections stable; show schema drift for repair.

6. **How should unknown (`any`) values bind to typed Connector inputs?**
   Recommended: require an explicit Transform cast before binding; preserve
   strict, understandable input validation.
   **Answer:** Require an explicit Transform cast.

7. **Which JSON value types should schema editors support?**
   Recommended: string, integer, number, boolean, object, array and nullable
   values. Use nested editors for objects/arrays.
   **Answer:** String, integer, number, boolean, object, array and nullable.

## Round 9 — answered at interview

1. **How should shared and Workflow-local Connector schemas interact?**
   Recommended: declared/shared Connector schema is the default for every
   Workflow. A Workflow-local schema overrides it only for that Workflow;
   global edits show affected Workflow count before saving.
   **Answer:** Shared schema is default; local schema overrides only that
   Workflow.

2. **How should users create and remove multiple Outputs nodes?**
   Recommended: auto-create one Output with each new Workflow; let users add
   more and delete extras, but require at least one Output.
   **Answer:** Create one by default; allow more, require at least one.

3. **Can an Output node receive links from several routes?**
   Recommended: one incoming route per Output node. Add another Output for a
   separate terminal route; this keeps each output schema unambiguous.
   **Answer:** Yes. An Output can receive several routes, but can bind only
   values common to every incoming route.

4. **How do output schema sources combine?**
   Recommended: Connector declaration/shared schema first; then Workflow-local
   JSON Schema or inferred shape from an example/read sample. Local schema
   overrides inferred shape. Keep example/sample values temporary.
   **Answer:** Prefer Workflow-local schema when present; otherwise use the
   shared Connector schema. Examples and read samples infer only when neither
   schema exists.

5. **How should node output examples be handled?**
   Recommended: pasted JSON is temporary and used only to infer schema; save
   the schema, not example values. For Connector writes, require pasted input
   JSON and do not execute during sampling.
   **Answer:** Ask the user whether to override the current schema when an
   example/sample suggests a different schema. Override scope and replacement
   behavior are resolved in Rounds 10 and 11. Raw sample values remain
   discarded per prior decision.

6. **When an Output field is missing, should runtime emit it as null?**
   Recommended: yes; keep the field in the output object with JSON `null`.
   **Answer:** Yes. Include the field with JSON `null`.

## Round 10 — answered at interview

1. **When sample schema differs, what should the override prompt offer?**
   Recommended: keep current schema, create/update a Workflow-local override,
   or open Connector settings for an explicit shared-schema edit. Never update
   shared schema as a side effect of sampling.
   **Answer:** Keep current, create local override, or edit shared schema
   separately.

2. **After the user approves a local schema override, replace or merge?**
   Recommended: merge new fields, mark absent fields optional, and flag type
   conflicts for repair. Preserve user-authored names/types until confirmed.
   **Answer:** Replace current schema with inferred shape after approval.

## Round 11 — answered at interview

1. **Does each Output node own its own result schema?**
   Recommended: yes. Each Output is a named terminal result contract; its
   fields and routes stay independent from other Output nodes.
   **Answer:** Yes. Each Output is an independent named result contract.

2. **What does a shared Connector schema cover?**
   Recommended: one schema per Connector tool, shared by Workflows that use
   that tool. A Connector integration can contain tools with different
   output shapes.
   **Answer:** One schema per Connector tool, shared by Workflows.

## Confirmed consensus snapshot

- A Workflow remains a Directory item with identity/lifecycle separate from
  its graph definition. Item metadata includes stable ID, workspace, parent
  folder, name, description, revision and lifecycle. Align Drift and cloud
  resources with Directory metadata. Support create/list/rename/move/duplicate/
  trash/restore; copies keep connector/tool and nested-Workflow references.
- Remove top-level Workflows navigation. Create from Directory; open in chat
  item tabs with save/close/return behavior across compact and expanded layouts.
- Extend AI `readDirectory` search and `readItem` reads to Workflows, with the
  same access checks and exclusion of deleted or unauthorized items.
- New Workflows start with one required Inputs node and one required Outputs
  node. Users configure Inputs, cannot delete it, may add Outputs, and cannot
  delete the last Output.
- Node kinds: Connector tools, Inputs, Outputs, Condition, Transform and
  nested Workflow. Remove Skill, Agent and system-tool nodes; no legacy data
  migration.
- Users may rename a node's canvas label. Its menu keeps canonical Connector
  and tool names visible; stable tool ID appears in details.
- Connector parameter names/types follow Connector schema and cannot change.
  Workflow-local output schemas may use arbitrary names and types; type
  mismatch needs an explicit Transform. Canonical Connector schema stays
  unchanged by local edits.
- Connector schema is shared per tool or Workflow-local. Local schema wins;
  shared per-tool schema is fallback. Examples and safe read samples infer
  only when schemas are absent. Repeated samples merge fields; absent fields
  become optional; conflicts become `any`. A drift prompt offers keep, local
  override, or explicit shared edit. Approval replaces the chosen schema.
  Save schema; discard raw samples.
- Read-only Connector tools can run for schema sampling with temporary inputs.
  Write tools require pasted JSON and do not run for sampling. Show tools
  before connection and mark the connection requirement. Resolve workspace
  connection at execution.
- Users bind from earlier node values with a searchable field tree. Select
  source node, then type JSON Pointer if needed. Store stable node ID and path.
  Inputs support bindings and static values. Unknown types need an explicit
  Transform cast.
- Graph is a directed acyclic graph with fan-out and fan-in. Each incoming
  event triggers a node; fan-out successors run independently. Ordinary nodes
  use an external add item: click, choose a node, create/connect beside source,
  select it and open its menu; drag item to an existing node to connect.
  Condition alone has visible True/False handles.
- Conditions select source field, operator and static/bound comparison value.
  Support type-aware equals, exists/empty, numeric comparisons and string
  matching. Group rules with All/Any. Missing/null input marks run invalid.
- Transform nodes can emit multiple named fields with typed operations:
  field selection, object/array construction, string templates, arithmetic
  and explicit casts. No arbitrary code.
- Each Output is a terminal result contract with its own schema. It may receive
  multiple routes but binds only values common to them. Missing fields
  serialize as JSON `null`.
- Menus close by close button, Escape/back or outside tap. Delete confirms and
  names node/removed links. Deleting a source removes links but keeps broken
  bindings for repair.
- Whole-Workflow execution remains out of scope. Isolated Connector read
  sampling remains in scope.
- User confirmed this consensus on 2026-10-31 and authorized final docs.
- Final glossary, ADR and spec now live at `docs/concepts/glossary.md`,
  `docs/adr/0002-workflow-connector-tool-nodes.md` and
  `docs/specs/workflow-connector-tool-nodes.md`.
- Audit user-visible surfaces across the branch and changed Directory/chat
  flows. Record evidence, severity, confidence, recommendations and
  verification scenarios; apply integration recommendations. Use rendered
  captures where available and label source-only findings.

## Canvas interaction addendum — 2026-11-01

### User-stated direction

- Make edges selectable with Flutter `FocusNode`s. Selecting an edge shows no
  side menu; show a trash action and confirm before deleting the edge.
- Use each node's `FocusNode` to show node selection and its menu.
- Clicking canvas space outside nodes and edges unfocuses the node.
- Dragging a node's external plus handle previews an edge that can be dropped
  on another node.
- Make the canvas appear infinite; grid lines should continue beyond nodes.

### Canvas implementation baseline facts

- Nodes select through `selectedNodeId` and `GestureDetector.onTap`; canvas
  background taps clear that selection. No per-node `FocusNode` exists.
- Edges are drawn by `_WorkflowConnectionPainter`; they have no hit target,
  selection state, or delete action.
- `WorkflowConnection` has source node ID, target node ID and optional
  Condition branch. It has no persistent connection ID.
- Plus handles are `Draggable`s with an icon-only feedback. Dropping on a
  `DragTarget` creates a node connection; no edge preview is painted.
- `InteractiveViewer` has a fixed 320-pixel boundary margin. The scene derives
  its finite size from node extents, the grid paints only that size, and node
  positions are capped.
- App and server validation both restrict node coordinates to finite values
  from 0 through 10,000. The app also clamps drag and render positions.
- The expanded inspector is a sibling of the canvas and has its own autofocus
  `Focus`; compact layout places it below the canvas. Selected node identity
  currently lives in editor state, not in Flutter focus state.

### Canvas interaction decisions

**Round 12 — answered 2026-11-01**

1. **Keyboard focus:** Traverse nodes and edges with Tab/Shift-Tab; activate
   with Enter/Space; Escape clears selection.
2. **Edge delete action:** Show floating trash at edge midpoint. Confirmation
   names source, Condition branch when present, and target.
3. **Plus drag:** Click still opens the picker. Drag previews a branch-aware
   edge. A valid node drop connects and focuses the target; invalid or empty
   drop cancels.
4. **Infinite canvas:** Keep the grid visible while panning in any direction;
   show no canvas edge; do not impose internal coordinate safety limits.

### Resolved canvas interaction rounds

**Round 13 — answered 2026-11-01**

1. **Coordinate domain:** Allow any finite X/Y value, including negative
   values. Reject NaN and infinity. Remove the current 0-to-10,000 coordinate
   range from app and server validation; retain the separate 100-node limit.

**Round 14 — answered 2026-11-01**

1. **Clear focus:** Empty-canvas taps clear node or edge focus. Pan gestures
   preserve focus.

**Round 15 — answered 2026-11-01**

1. **Inspector focus:** When keyboard focus moves from a canvas node into its
   inspector controls, should the node remain selected and its menu stay open
   until explicit clear (empty tap, Escape, or another canvas item)?
   Answer: yes; selection persists until empty tap, Escape, or another canvas
   item, while inspector controls take normal keyboard focus.
2. **Traversal order:** Tab/Shift-Tab follows Inputs, upstream-to-downstream
   nodes, each node's outgoing edges, Condition True before False, and Outputs
   last. Use canvas position to order peers.
3. **Invalid link drops:** Show a brief reason when a target cannot accept a
   dragged link; cancel the link on release.

## Canvas interaction consensus — confirmed 2026-11-01

- Each Workflow node and connection can receive Flutter keyboard focus.
  Tab/Shift-Tab follows workflow order: Inputs, upstream-to-downstream nodes,
  each node's outgoing edges, Condition True before False, then Outputs. Use
  canvas position to order peers. Enter/Space activates the focused item;
  Escape clears selection.
- Focusing a node selects it and opens its inspector. Moving keyboard focus
  into that inspector does not clear the node selection. Another canvas item,
  an empty-canvas tap, or Escape clears/replaces selection.
- The visible node focus ring follows Flutter keyboard focus. When an
  inspector field or another outside input receives focus, remove that ring
  while retaining the selected outline and inspector.
- Focusing an edge selects and highlights it. It never opens the side
  inspector. Show a floating trash button at the edge midpoint. Confirm
  deletion by naming the source, Condition branch when present, and target.
- Clicking a node's plus handle keeps opening the node picker. Dragging it
  previews a branch-aware edge. Dropping on a valid node connects and focuses
  the target; an invalid target explains why and cancels on release; an empty
  drop cancels. Panning preserves selection; an empty-canvas tap clears it.
- The canvas pans in any direction with a continuous grid and no visible edge.
  Node X/Y coordinates may be any finite value, including negatives. Reject
  NaN and infinity. Remove app and server 0-to-10,000 coordinate bounds; keep
  the separate 100-node Workflow limit.

The user confirmed this addendum and authorized final glossary, ADR, spec, and
implementation on 2026-11-01. The existing core Workflow consensus remains
accepted.

## Canvas implementation result — 2026-11-01

- Node and connection focus, ordered keyboard traversal, activation, and
  Escape clearing are implemented.
- Empty taps clear selection; pan gestures preserve it. Inspector focus keeps
  the selected node active. Its focus ring disappears when a field receives
  focus, while its selected outline and inspector remain.
- Selected connections show a midpoint delete action with source, branch, and
  target confirmation.
- Plus handles open the picker by click and preview links by drag. Valid drops
  connect and focus the target; invalid drops show a reason and cancel.
- Canvas uses a continuous grid with no visible boundary. App and server accept
  any finite signed coordinates and reject non-finite values.
- Focused app and server tests pass. `validate:changed` still reports
  info-level diagnostics and DCL warnings in the workflow feature.
- Merged `origin/main` at `3cd812447` cleanly in merge commit `58db0b297`.
  The merged CI import-sort check passes across all 3,004 Dart files.
- Rendered app capture was not available; verification used source review and
  widget tests.

## UX view and flow brief

- **Goal:** Build and understand a Workflow graph without guessing which node
  or link is active, what a drag will connect, or why a link was rejected.
- **Entry:** Existing Workflow editor in its Directory/chat item tab.
- **Canvas:** Continuous grid fills the viewport while users pan without a
  visible boundary. Nodes and links remain the primary content.
- **Selection:** Focusing a node selects it and opens its inspector. Focus can
  move into inspector fields without closing the menu. Focusing a link selects
  it and reveals one midpoint delete action, never the node inspector.
- **Add/link flow:** Click plus opens the current node picker. Drag plus shows
  a branch-aware link preview. A valid drop links and focuses the target; an
  invalid target explains why and cancels on release; empty drop cancels.
- **Clear/exit:** Empty-canvas tap and Escape clear selection. Panning keeps
  selection. Existing compact and expanded inspector layouts remain.
- **Keyboard:** Tab/Shift-Tab follows Workflow order, with branch order and
  screen-position tie-breaks as agreed. Enter/Space activate; Escape clears.
- **Completion:** User can see the new link, target selection, deletion
  confirmation, and invalid-target recovery without whole-Workflow execution.
