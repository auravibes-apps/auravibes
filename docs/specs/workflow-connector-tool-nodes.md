# Workflow Items and Connector Tool Nodes

- Status: Accepted
- Date: 2026-10-28
- Updated: 2026-10-29

## Item model and location

- A Workflow is a named, editable item in the current Workspace Directory.
- The Workflow item owns stable ID, workspace, parent folder, name,
  description, revision and lifecycle. Its Workflow definition owns only the
  graph inputs, outputs, nodes and connections.
- Local Drift and cloud workflow resources store the same item metadata.
- Do not migrate unpublished prototype rows or legacy Skill-node data.
- Directory supports create, list, rename, move, duplicate, trash and restore.
  A duplicate gets a new ID and retains Connector/tool and nested-Workflow
  references.
- Trashing a referenced Workflow keeps its ID in the graph. Show the nested
  step as unavailable until the target is restored or repaired.
- Open the item from Directory or an existing chat item tab. Do not add a
  Workflows sidebar destination or a separate discovery tool.
- AI uses existing `readDirectory` and `readItem` operations to find and read
  active Workflows in the selected Workspace, with existing access checks.

## Connector tool nodes

### Purpose

Workflow nodes should use the executable Connector tools already available in
the workspace. People should be able to choose a named tool and inspect its
inputs and outputs without guessing.

### Decisions

- The picker lists executable Connector tools with connector name, tool name,
  description, and a visible connection requirement. A missing Connection does
  not hide a tool.
- A Connector tool node stores its stable tool ID. It does not store a
  Connection ID or credential. Execution resolves a usable Connection for the
  active Workspace.
- Input ports come from the tool's input schema. New Connector tool nodes have
  no output ports until the user samples the tool.
- Sampling a read tool runs it with temporary sample inputs. A user can choose
  a Connection for the sample when several match; this choice is not saved.
- Sampling a write tool never runs it. The user pastes valid JSON output to
  infer its outputs.
- Samples update output port names and types only. Raw input and output values
  are not saved in the workflow. Cloud sampling returns a shape-only result so
  provider values do not reach the app.
- A JSON object creates one port per top-level field. Nested objects and arrays
  stay `object` and `array`. A JSON scalar or array creates one `Result` port
  with its inferred type. Non-JSON text creates `Result:string`.
- Repeated samples merge fields. A field missing from any sample becomes
  optional; conflicting types become `any`. Existing port IDs stay stable.
- Legacy Skill workflow nodes are not supported. This feature has not shipped
  or been used, so no Skill-node decoder or server compatibility path remains.

### Scope

The editor saves Workflow definitions but does not execute whole workflows.
Sampling may execute one read Connector tool with temporary inputs. Write-tool
samples require pasted JSON and never run the write operation.

### Acceptance criteria

1. Users can choose real Connector tools before connecting an account and can
   see when a Connection is required.
2. Saved nodes reference stable Connector tool IDs and no Connection IDs.
3. Read samples run with temporary inputs and never persist raw values.
4. Write samples require pasted JSON and never dispatch a write operation.
5. Output ports follow the inference and repeated-sample rules above.
6. Saved workflow node kinds contain no Skill node.
7. A user can create a Workflow in the current folder and the editor opens the
   saved item.
8. Directory supports local and cloud listing, saving, folder moves,
   duplication, trash and restore.
9. A trashed nested Workflow remains referenced and appears unavailable until
   restored or repaired.
10. Existing chat item tabs can open, restore and close a Workflow in compact
    and expanded layouts without losing unsaved edits silently.
11. AI Directory path/name searches include active Workflows. `readItem`
    returns the graph only when the item belongs to the authorized Workspace.
