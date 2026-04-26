# Agent Workflows: Reusable Agents

## Example Agents

| Display name | Slug | Instructions |
| --- | --- | --- |
| Reviewer | `reviewer` | Review code changes for correctness, missing tests, and unsafe assumptions. |
| Support | `support` | Draft concise customer-support replies using workspace tone and escalation rules. |
| Planner | `planner` | Break product requests into implementation phases, dependencies, and validation checks. |

## New Chat Selection

```text
User selects Reviewer
  -> NewChatNotifier stores selected agentId
  -> SendNewMessageUsecase validates agent workspace ownership
  -> ConversationRepository creates conversation with agentId
  -> ContinueAgentUsecase resolves latest Reviewer instructions
  -> build_prompt_chat_messages prepends instructions before chat history
```

Prompt before selection:

```text
user: "Review this diff."
```

Prompt after selecting `reviewer`:

```text
developer: "Review code changes for correctness, missing tests, and unsafe assumptions."
user: "Review this diff."
```

## Existing Conversation Change

```text
User changes conversation from No Agent to Support
  -> ConversationChatNotifier requests change
  -> ChangeConversationAgentUsecase validates workspace ownership
  -> ConversationRepository patches conversation.agentId
  -> Next assistant response resolves latest Support instructions
```

Past messages are not rewritten. Only future response generation uses the new selection.

## Edit Agent

```text
User edits Reviewer instructions
  -> AgentsNotifier submits AgentPatch
  -> UpdateAgentUsecase validates name/instructions and workspace slug uniqueness
  -> AgentRepository saves updated record
  -> Future prompts for conversations using Reviewer resolve the latest instructions
```

Conversations store `agentId`, not an instruction snapshot.

## Delete Agent

```text
User deletes Reviewer
  -> DeleteAgentUsecase deletes the agent
  -> AgentRepository clears affected conversation.agentId values or guarantees fallback behavior
  -> Selectors remove Reviewer
  -> Next prompt behaves as No Agent
```

No stale deleted-agent instructions are injected.

## Interface Responsibilities

| Layer | Inputs | Outputs | Errors |
| --- | --- | --- | --- |
| `ChatAgentSelector` | current `agentId`, workspace agents | selected `agentId?` | local validation display only |
| `NewChatNotifier` | selected `agentId?`, draft message | new conversation request | keeps previous selection on failure |
| `ChangeConversationAgentUsecase` | conversation id, `agentId?` | updated conversation selection | cross-workspace and not-found exceptions |
| `AgentRepository` | create/update/delete requests | persisted agent state | validation, duplicate slug, not-found exceptions |
| `build_prompt_chat_messages` | messages, optional instructions | ordered prompt messages | no persistence or UI side effects |

Unexpected infrastructure failures should bubble unless they can be mapped to validation, duplicate slug, not-found, or cross-workspace cases.
