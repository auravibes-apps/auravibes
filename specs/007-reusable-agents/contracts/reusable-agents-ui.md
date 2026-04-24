# UI Contract: Reusable Agents

## Agents Management Screen

Route context:
- Workspace route: `/workspaces/:workspaceId/...`
- Screen displays agents for current workspace only.

Required states:
- Empty: show no agents and offer create action.
- Loaded: show scannable list/table with name, slug, and instructions preview.
- Saving/deleting: prevent duplicate submissions and show progress.
- Error: show user-readable validation or persistence failure.

Required actions:
- Create agent with `name` and `instructions`.
- Edit agent `name` and `instructions`.
- Delete agent.

Validation behavior:
- Empty name blocks save.
- Empty instructions block save.
- Duplicate generated slug in same workspace blocks save and asks for a distinct name.

## New Chat Agent Selector

Location:
- New chat screen near model selection and chat input.

Options:
- Always includes "No Agent".
- Includes current workspace agents only.

Behavior:
- Default selection is "No Agent".
- Selected agent id is passed into new conversation creation.
- Starting a chat remains blocked only by required model/message validation, not by lack of agents.

## Existing Conversation Agent Selector

Location:
- Conversation screen near conversation-level controls.

Options:
- Always includes "No Agent".
- Includes current workspace agents only.

Behavior:
- Shows the conversation's current agent selection.
- Changing selection updates the conversation for future assistant responses only.
- If current selection references a deleted agent, show "No Agent" and inform the user before next send.

## Prompt Behavior Contract

Inputs:
- `conversationId`
- Conversation messages
- Current conversation agent selection
- Latest saved instructions for selected agent, if any

Expected behavior:
- "No Agent": prompt contains only normal conversation history and existing tool messages.
- Selected agent: prompt includes latest saved agent instructions as non-visible conversation guidance before normal conversation history.
- Deleted/missing selected agent: clear or ignore selection, inform user, and proceed as "No Agent".

## Out of Scope

- Tool presets.
- Per-agent model selection.
- Scheduled/background tasks.
- Flow builder.
- Instruction version history.
