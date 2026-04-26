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

Example states:

```text
Empty
+------------------------------+
| No reusable agents           |
| [Create Agent]               |
+------------------------------+

Loaded
+------------+---------------+----------------------+
| Name       | Slug          | Instructions         |
+------------+---------------+----------------------+
| Reviewer   | reviewer      | Review code changes. |
| Support    | support       | Answer with tone.    |
+------------+---------------+----------------------+

Saving/deleting
+------------+---------------+----------------------+
| Reviewer   | reviewer      | Saving.              |
+------------+---------------+----------------------+

Error
+------------------------------+
| Name already exists in this  |
| workspace. Choose another.   |
+------------------------------+
```

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

Example option list:

```text
No Agent
Reviewer        reviewer
Support         support
```

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

Selector state flow:

```text
loading agents -> show current value -> user selects option -> save selection
save success -> update displayed value
save failure -> keep previous value and show error
deleted selected agent -> display "No Agent" and show fallback notice
```

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

Agent responsibilities and use cases:
- `Reviewer` should influence future assistant responses by adding review-focused instructions before conversation history.
- `Support` should influence future assistant responses by adding support-tone instructions before conversation history.
- Selectors only choose an agent; prompt composition owns instruction injection.
- Delete flow owns fallback to "No Agent"; prompt composition must not use deleted-agent instructions.

## Out of Scope

- Tool presets.
- Per-agent model selection.
- Scheduled/background tasks.
- Flow builder.
- Instruction version history.
