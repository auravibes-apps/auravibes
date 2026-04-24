# Research: Reusable Agents

## Decision: Store agents as workspace-scoped records

**Rationale**: Workspace scope matches existing app routing (`/workspaces/:workspaceId/...`) and keeps reusable instructions tied to the work context where they are meaningful. It avoids cross-workspace leakage and matches the clarified spec.

**Alternatives considered**:
- User-wide agents: rejected because the current app surfaces most resources through workspace context.
- Conversation-local agents: rejected because the feature goal is reuse across conversations.

## Decision: Store display name and generated slug

**Rationale**: The user-facing name preserves natural labels while the slug gives a stable, scannable unique identifier per workspace. Unique workspace slugs reduce ambiguity in selectors and future linking without forcing global uniqueness.

**Alternatives considered**:
- Name only: rejected because duplicate names would create selector ambiguity.
- Global slug uniqueness: rejected because common names such as "reviewer" should be reusable in different workspaces.

## Decision: Add agent reference to conversations

**Rationale**: Conversation-level selection must persist across app restarts and affect future responses. A nullable `agentId` on conversations models "No Agent" naturally and keeps current chat flows simple.

**Alternatives considered**:
- Separate conversation-agent table: rejected because each conversation has at most one selected agent in current scope.
- Store instructions snapshot on conversation: rejected by clarification; conversations must use latest saved instructions.

## Decision: Use latest saved instructions at prompt time

**Rationale**: The selected conversation references the reusable agent. Looking up current instructions before response generation honors edits immediately and avoids version-history complexity.

**Alternatives considered**:
- Selection-time snapshot: rejected because it makes edits less predictable for users.
- User-selectable version behavior: rejected as unnecessary configurability for the first scope.

## Decision: Delete agents and fall conversations back to "No Agent"

**Rationale**: Deletion completes the CRUD lifecycle. Falling back to "No Agent" is predictable, avoids hidden archived behavior, and prevents stale instructions from continuing after deletion.

**Alternatives considered**:
- No delete: rejected because clarified scope includes deletion.
- Archive: rejected because it adds extra state and selector rules not needed now.

## Decision: Inject agent instructions as conversation-level guidance before chat history

**Rationale**: Agent instructions should guide future assistant behavior without becoming a normal user message. Prompt construction can prepend a system/developer-style instruction message, subject to available provider capabilities, while preserving higher-priority platform safety rules.

**Alternatives considered**:
- Store agent instructions as visible chat messages: rejected because it pollutes conversation history.
- Append instructions after user messages: rejected because it weakens the intended guidance and can confuse chronological history.

**Usage example**:

Before selection, prompt construction uses the visible conversation history only:

```text
user: "Review this migration."
assistant: "Share the migration file."
```

After selecting `code-reviewer`, prompt construction prepends the latest saved instructions:

```text
developer: "Act as a code reviewer. Focus on correctness, tests, and migration safety."
user: "Review this migration."
assistant: "Share the migration file."
```

If the selected `agentId` later points to a deleted agent, the conversation behaves as `"No Agent"` before the next send and does not inject stale instructions.

Example agents:
- `code-reviewer`: reviews diffs for correctness, test gaps, and unsafe assumptions.
- `support-bot`: answers customer-support drafts using workspace tone and escalation rules.

## Decision: Keep tool presets, model choice, scheduling, background tasks, and flow builder out of scope

**Rationale**: The first implementation should ship reusable instruction profiles only. Future workflow capabilities can attach to the same workspace-scoped agent concept after the core lifecycle is stable.

**Alternatives considered**:
- Add placeholder fields now: rejected by YAGNI and constitution simplicity rules.
- Build a generic workflow graph now: rejected because it exceeds current accepted requirements.
