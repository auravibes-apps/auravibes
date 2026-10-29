# Workflow Connector Tool Nodes

- Status: Accepted
- Date: 2026-10-28

## Purpose

Workflow nodes should use the executable Connector tools already available in
the workspace. People should be able to choose a named tool and inspect its
inputs and outputs without guessing.

## Decisions

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

## Scope

The editor saves workflow definitions but does not execute whole workflows yet.
Sampling executes one read tool only, or infers a write tool's output from
pasted JSON.

## Acceptance criteria

1. Users can choose real Connector tools before connecting an account and can
   see when a Connection is required.
2. Saved nodes reference stable Connector tool IDs and no Connection IDs.
3. Read samples run with temporary inputs and never persist raw values.
4. Write samples require pasted JSON and never dispatch a write operation.
5. Output ports follow the inference and repeated-sample rules above.
6. Saved workflow node kinds contain no Skill node.
