# UI and Behavior Contracts: Agent Conversation Compaction Settings

## Chat Input Manual Compact Contract

### Control

- Location: chat input area footer alongside existing tool/stop/send controls.
- Icon-only button with localized tooltip and accessibility label.
- Uses existing generic UI components.

### Enabled State

Enabled when:

- Current conversation is not busy.
- No pending tool approvals are visible.
- No unresolved tool calls are pending.
- Conversation has eligible prior context to compact.

Disabled/unavailable when:

- Conversation is streaming or running tools.
- Tool approval is pending.
- Conversation has no eligible context.
- Compaction mutation is already running.

### Feedback

- Start: visible loading or disabled state.
- Success: localized confirmation.
- Failure: localized recoverable error.
- No eligible context: localized explanation.
- Success does not trigger assistant continuation; the app waits for the next user action.

## Settings Section Contract

### Location

- Dedicated compaction section in the existing settings screen.

### Fields

- Auto compaction enabled toggle.
- Usage percentage threshold numeric control.
- Remaining-token threshold numeric control.
- Reset to defaults action.

### Validation

- Percentage must be in accepted range.
- Remaining-token threshold must be positive.
- Invalid values cannot be saved.
- Validation messages are localized and visible near the relevant field or in a recoverable error area.

### Save Behavior

- Saved settings affect subsequent auto-compaction checks.
- Open conversations use updated settings on the next check.
- Reset restores defaults and persists them.

## Prompt Selection Contract

### Inputs

- Ordered persisted messages for one conversation.

### Output

- Ordered prompt messages for the LLM agent service.

### Rules

- If no compaction summary exists, output all prompt-eligible messages.
- If a compaction summary exists, output the latest compaction summary and all later prompt-eligible messages.
- Latest compaction summary is the newest sent message with `metadata.isCompactionSummary = true`.
- Compaction summary is emitted as context/system content.
- Compaction summary must not emit tool calls or tool results.
- Older messages before the latest compaction summary must not be emitted.
- Compaction summary messages are not shown in the normal chat transcript.

## Auto Compaction Contract

### Trigger Check

Auto compaction is checked before assistant continuation builds prompt history.

### Required Conditions

- Auto compaction setting is enabled.
- Selected model context limit is known.
- Usage percentage threshold is met.
- Remaining-token threshold is met.
- Conversation is safe to compact.

### Failure Behavior

- If required auto compaction fails, assistant continuation is blocked.
- The compactable context remains uncompacted.
- A visible localized chat error message is persisted so the user can see why continuation stopped.
- The visible error message is not a compaction summary and does not move the prompt boundary.

### Safe Conversation

Safe means:

- No unresolved tool call.
- No pending approval.
- No active tool execution.
- No unfinished assistant message in the compactable range.
- No sending user message in the compactable range.

## Compaction Summary Content Contract

Summary must preserve:

- User goals and constraints.
- Decisions already made.
- Current state and next useful steps.
- Important files, ids, models, providers, and tool names.
- Errors and resolved outcomes.

Summary must not include:

- Thinking traces.
- Raw tool call metadata.
- Pending tool calls represented as completed.
- Secrets or credentials.
