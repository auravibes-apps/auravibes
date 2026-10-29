# Workflow Connector Tool Nodes

- Status: Accepted
- Date: 2026-10-28
- Updated: 2026-10-29

## Context

Workflows need stable identity, folder location, lifecycle, and a reusable
graph. A graph is not itself a Directory item. The feature has not shipped, so
there is no published Skill-node or prototype-data contract to preserve.

## Decisions

- A Workflow is a first-class Directory item. Its identity, workspace, parent
  folder, name, description, revision and lifecycle belong to the item.
- A Workflow definition contains only graph inputs, outputs, nodes and
  connections. Saving or moving the item does not change its identity.
- Store local items in a new Drift schema and cloud items as workflow resources
  with the same item metadata. Do not migrate unpublished prototype workflow
  rows or Skill-node data.
- Directory owns create, list, rename, move, duplicate, trash and restore.
  Duplicates receive a new item ID and retain their graph references.
- Trashing a referenced Workflow keeps its stable reference. The referencing
  node reports that the target is unavailable until it is restored or repaired.
- Open the editor from Directory and in existing chat item tabs. Do not add a
  top-level Workflows destination or separate discovery tool.
- AI uses existing `readDirectory` and `readItem` paths. Both apply the same
  workspace access checks as other Directory items.
- Connector tool nodes store stable tool IDs. Resolve Connections from the
  active Workspace when executing a tool. A Workflow never stores credentials
  or Connection IDs.
- Sampling a read tool uses temporary inputs. Sampling a write tool requires
  pasted JSON and never dispatches the write. Save only inferred port shapes;
  discard raw samples.
- Whole-Workflow execution remains out of scope. Sampling one read tool is the
  only execution in this editor.

## Consequences

- Local and cloud stores need a Workflow item schema and standard Directory
  lifecycle operations.
- Existing AI Directory commands can discover and read Workflows without a
  second command family.
- A nested Workflow can remain referenced while unavailable. The editor must
  surface that state and allow recovery after restore.
- No compatibility decoder or data migration is required for unpublished
  prototype workflows.
