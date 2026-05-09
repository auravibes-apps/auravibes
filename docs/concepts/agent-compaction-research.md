# Agent Conversation Compaction Research

Research timestamp: `2026-05-02T08:17:30-0500`

## Summary

AuraVibes can support both auto and manual conversation compaction. The practical design is:

1. Keep the full visible conversation in Drift.
2. Add a compacted summary message/metadata that affects only the prompt sent to the model.
3. Auto-compact before each assistant continuation when context usage crosses either the percentage threshold or the remaining-token floor (OR logic — triggers when either condition is met).
4. Manual compact from the chat input/context controls should call the same compaction use case.
5. Never split unresolved assistant tool calls from their tool results.

This matches the direction used by current agents: Cline, Goose, Kiro, OpenHands, Continue CLI, Aider, Roo Code, Claude Code, and Codex CLI all favor summarization/compaction over blind truncation when long sessions approach context limits.

## External Findings

| Agent            | Auto compaction                         | Manual compaction                                            | Trigger model                                                                     | Notes                                                                                                                                                          |
| ---------------- | --------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Cline            | Yes                                     | Not documented as primary user command in reviewed page      | Near context limit; context management docs say around 80%                        | Summarizes conversation, replaces active history with summary, shows summarization tool call/cost, falls back to rule-based truncation for unsupported models. |
| Goose            | Yes                                     | Desktop `Compact now`; CLI `/summarize`                      | Default 80%; configurable with `GOOSE_AUTO_COMPACT_THRESHOLD`; `0.0` disables     | Two-tier strategy: proactive compaction, then fallback context strategy. Desktop uses summarization only; CLI can summarize/truncate/clear/prompt.             |
| Kiro             | Yes                                     | Not found in reviewed doc                                    | 80% context usage                                                                 | Chat panel context meter shows usage; Kiro automatically summarizes when usage reaches 80%.                                                                    |
| OpenHands        | Yes                                     | API condensation request                                     | Event-count condenser defaults, e.g. max 120 events to target 60 in reviewed docs | Rolling condenser keeps initial events and recent tail, summarizes middle into condensation event.                                                             |
| Continue CLI     | Yes in CLI source per subagent research | `/compact`                                                   | Computed remaining-token gap, not only percent                                    | Stores `conversationSummary`; prompt history becomes system/context plus compacted summary and recent messages.                                                |
| Aider            | Yes                                     | Mostly `/clear`, `/drop`, token/history controls             | Soft `--max-chat-history-tokens`; default model-derived                           | Uses weak model for chat-history summarization; exposes token and history knobs.                                                                               |
| Roo Code         | Yes if enabled                          | Likely UI/manual condense, source confirms condense pipeline | Configurable percent, valid range 5-100, plus token buffer                        | Non-destructive tagging model; fallback sliding-window truncation.                                                                                             |
| Claude Code      | Long-session compaction documented      | `/compact`                                                   | Exact auto threshold not confirmed from official source                           | Documents what survives compaction; path-scoped rules can be lost until re-read.                                                                               |
| OpenAI Codex CLI | Yes                                     | Manual compact operation                                     | Model/config catalog token limit                                                  | Has pre-turn and mid-turn compaction paths; can compact after tool results before follow-up sampling.                                                          |

## Source Notes

- Cline docs: Auto Compact page says Cline monitors token usage, summarizes near context limits, replaces history with summary, shows a summarization tool call, and uses LLM summarization for Claude 4, Gemini 2.5, GPT-5, and Grok 4 series. Source crawled 2026-04 by search index: <https://docs.cline.bot/features/auto-compact>
- Cline context management docs mention Auto Compact around 80% context usage. Source crawled 2026-02/2026-04 by search index: <https://docs.cline.bot/getting-started/understanding-context-management>
- Goose docs: Smart Context Management says auto compaction defaults to 80%, is configurable with `GOOSE_AUTO_COMPACT_THRESHOLD`, and manual compact exists in Desktop/CLI. Source crawled 2026-05-01 by search index: <https://goose-docs.ai/docs/guides/sessions/smart-context-management/>
- Kiro docs: Summarization page says Kiro automatically summarizes at 80% usage. Page updated 2025-12-02: <https://kiro.dev/docs/chat/summarization/>
- Aider docs: `--max-chat-history-tokens` is a soft limit after which summarization begins, and `--weak-model` is used for chat history summarization. Source crawled 2026-04 by search index: <https://aider.chat/docs/config/options.html>
- OpenClaw/OpenHands-like compaction docs: Compaction keeps recent messages, preserves tool-call/result boundaries, supports `/compact`, and can compact/retry on context overflow. Source crawled 2026-04 by search index: <https://github.com/openclaw/openclaw/blob/main/docs/concepts/compaction.md>
- Continue docs/source were reviewed by subagent from official docs and GitHub raw source paths. IDE docs confirm previous conversation history is included and new sessions clear context: <https://docs.continue.dev/ide-extensions/chat/how-it-works>
- Letta API exposes a conversation compaction endpoint with `mode`, `model`, and `clip_chars`, useful as a product/API reference even though it is not the same category as a coding IDE agent: <https://docs.letta.com/api/resources/conversations/subresources/messages/methods/compact/>

## AuraVibes Current State

Relevant files:

- Prompt assembly: `apps/auravibes_app/lib/services/chatbot_service/build_prompt_chat_messages.dart`
- Assistant continuation: `apps/auravibes_app/lib/features/chats/usecases/continue_agent_usecase.dart`
- Agent loop: `apps/auravibes_app/lib/features/chats/usecases/run_agent_iteration_usecase.dart`
- Chat input bubble: `apps/auravibes_app/lib/features/chats/widgets/chat_input_widget.dart`
- Conversation screen: `apps/auravibes_app/lib/features/chats/screens/chat_conversation_screen.dart`
- Context usage UI: `apps/auravibes_app/lib/features/chats/widgets/conversation_context_usage_pill.dart`
- Usage calculation: `apps/auravibes_app/lib/features/chats/providers/context_usage_provider.dart`
- Message providers: `apps/auravibes_app/lib/features/chats/providers/messages_providers.dart`
- Message entity/metadata: `apps/auravibes_app/lib/domain/entities/messages.dart`
- Message table: `apps/auravibes_app/lib/data/database/drift/tables/messages_table.dart`
- Chat model service: `apps/auravibes_app/lib/services/chatbot_service/chatbot_service.dart`

Important current behavior:

- `ContinueAgentUsecase.call()` loads persisted messages, builds `ChatMessage` history, then calls `ChatbotService.sendMessage()`.
- `BuildPromptChatMessages` maps user messages to `ChatMessage.user()` and every non-user message to model/tool messages.
- `MessageMetadataEntity` already stores `toolCalls`, `promptTokens`, `completionTokens`, and `totalTokens`.
- `conversationUsedTokensProvider` currently uses latest assistant message usage or streaming usage. It does not estimate the full next prompt size from all messages.
- `MessageType.system` exists, but prompt assembly does not currently map system messages to `ChatMessage.system()`.
- UI strings must be localized. No hardcoded English in Flutter UI.

## Recommended Product Behavior

Auto compaction:

- Check before every assistant continuation, after tools have finished if applicable, and before `BuildPromptChatMessages`.
- Run only when no unresolved tool approvals/tool calls are pending.
- Trigger when either condition is true (OR logic):
  - used context percent is at or above a threshold, recommended default `80%`;
  - remaining context is below a safety gap, recommended default `max(maxOutputTokens, 20% of contextLimit)` capped around `15000` tokens.
- If provider returns a context-overflow error, compact and retry once if the conversation state is still safe.
- Keep a recent tail uncompressed, recommended at least the latest user turn, latest assistant turn, and complete tool-call/result groups.
- Preserve the full original transcript for UI/history.

Manual compaction:

- Add a compact button to the chat input footer or context usage control.
- Disable it while the conversation is busy, while there are pending tool approvals, or before the conversation has enough messages.
- Manual compact should call the same domain use case as auto compact.
- Optional later: allow user instructions for summary focus, e.g. "focus on API decisions". MVP can omit this.

Prompt behavior after compaction:

- Send a compact summary as system/context before the unsummarized recent tail.
- Do not delete visible user/assistant messages for MVP.
- Do not include both old compacted messages and their summary in model context, or token usage will not improve.

## What Can Be Developed In AuraVibes

> **Note (May 2026):** Schema v2 with a dedicated `workspace_compaction_settings` table was implemented in PR #306. Most items below the first two sections have been delivered; sections are retained as historical design notes.

Implemented without schema migration (historical snapshot — since implemented):

- A `CompactConversationUsecase` under `features/chats/usecases/`.
- A `ShouldCompactConversationUsecase` or policy class using selected model context limit and prompt-token estimates.
- A compaction summary stored as a normal message row with existing `messageType` and metadata JSON.
- Metadata fields added to `MessageMetadataEntity`, then regenerated with build_runner:
  - `isCompactionSummary`
  - `compactedFromMessageId`
  - `compactedThroughMessageId`
  - `compactedMessageIds`
  - `compactionCreatedAt`
  - `compactionKind` (`auto` or `manual`)
- Prompt assembly that skips messages covered by the latest compaction summary and includes summary plus recent tail.
- Chat input compact button using `AuraButton` and localized tooltip.
- A compaction status/loading provider or mutation state.
- Basic tests around prompt assembly, trigger policy, and tool-call boundary preservation.

Can build with small app-layer changes:

- Map `MessageType.system` to `ChatMessage.system()` in `BuildPromptChatMessages`.
- Add `ChatbotService.summarizeConversation()` or use the existing provider factory to call a selected model for a non-streaming/streaming summary.
- Extend context usage provider to report estimated prompt usage instead of only latest provider usage.
- Add retry-on-context-overflow in `ContinueAgentUsecase`.

Implemented with schema migration (PR #306):

- ~~Dedicated `conversation_compactions` table~~ → Delivered as `workspace_compaction_settings` table (schema v2) with per-workspace override columns (autoCompactEnabled, usagePercentageThreshold, remainingTokenThreshold).
- ~~Conversation-level compacted-through pointer~~ → Delivered via `compactedThroughMessageId` in message metadata.
- Multiple summary revisions with rollback (future enhancement).
- User-visible compaction history/checkpoints (future enhancement).

## What Cannot Or Should Not Be Developed Yet

Do not build exact cross-provider token accounting until tokenizer/provider support is defined. Current token data comes from provider response usage and is not enough to know exact next prompt size before sending.

Do not destructively delete old messages for MVP. It risks data loss, breaks visible chat history, and is unnecessary if prompt assembly can exclude compacted ranges.

Do not compact while tools are pending or approvals are visible. Tool calls and results are serialized through assistant metadata; splitting them can produce invalid model history or duplicate tool execution.

Do not put compaction business logic in widgets or providers. Per project rules, business logic belongs in use cases; widgets render and providers expose state.

Do not add domain-specific compaction UI to `packages/auravibes_ui`. The app can use generic `AuraButton`/icons; reusable UI package must stay domain-agnostic.

Do not rely only on percent threshold. A 1M token model at 80% still has 200k tokens free; a 32k model at 80% has 6.4k tokens free. Auto compaction needs both percent and remaining-token safety gap.

## Proposed Architecture

Use cases:

- `EstimateConversationPromptTokensUsecase`
  - Input: conversation id, selected model.
  - Output: estimated prompt tokens, context limit, remaining tokens, percent.
  - First version can use provider usage fallback plus rough local estimate. Later version can use exact tokenizers.

- `ShouldCompactConversationUsecase`
  - Input: estimate, settings.
  - Output: decision plus reason.
  - Encodes percent and remaining-token gap.

- `CompactConversationUsecase`
  - Loads messages.
  - Finds latest compaction summary.
  - Chooses compactable range.
  - Keeps safe recent tail.
  - Calls summarizer model.
  - Persists summary metadata.

- `BuildCompactedPromptMessagesUsecase` or extension to `BuildPromptChatMessages`
  - Finds latest summary.
  - Excludes covered messages.
  - Emits summary as system/context.
  - Emits recent tail with valid tool-call/result ordering.

Integration points:

- Auto: `ContinueAgentUsecase.call()`, immediately before `BuildPromptChatMessages()(messages)`.
- Manual: `ChatInputWidget` footer button calls screen callback, screen delegates to compaction use case/mutation.
- Usage UI: `ConversationContextUsagePill` can show compact button/status later, but input footer is enough for MVP.

## Compaction Boundary Rules

Compact only a prefix/middle range that ends before active work:

- Never compact unsent/sending/error messages unless explicitly handled.
- Never compact latest assistant message if it has pending tool calls.
- Never split an assistant tool call from its result message representation.
- Keep latest user message and all messages after it in full for manual compaction unless user explicitly wants hard checkpoint behavior.
- Keep any message after the latest compaction summary unless doing recursive summary replacement.

## Summary Prompt Requirements

The summarizer prompt should preserve:

- User goals and constraints.
- Decisions made.
- Current plan/status.
- Files, identifiers, model/provider names, tool names, and exact IDs when relevant.
- Errors encountered and resolutions.
- Pending tasks.
- Tool outputs only as concise facts, not raw verbose logs.

The prompt should avoid:

- Inventing unseen code state.
- Preserving sensitive tool output verbatim.
- Summarizing unresolved tool calls as completed.

## MVP Plan

1. Add metadata fields for compaction summaries.
2. Add prompt builder tests for summary plus recent tail.
3. Add `CompactConversationUsecase` with manual trigger only.
4. Add compact button to `ChatInputWidget`.
5. Add auto policy using existing context limit and conservative usage estimate.
6. Wire auto compaction into `ContinueAgentUsecase`.
7. Add context-overflow retry once.
8. Run `fvm dart run build_runner build --delete-conflicting-outputs`, analyzer, and focused tests.

## Open Decisions

- Should manual compaction be a hard checkpoint (summary only) or keep a recent tail? Recommendation: keep recent tail for MVP.
- Should summary be visible in chat as a system card? Recommendation: hidden from normal chat list for MVP, but discoverable later in details/debug UI.
- Should threshold be global, per workspace, or per model? Recommendation: global default first, per-model later.
- Which model summarizes? Recommendation: use active conversation model first. Add summarizer model selection only after MVP.
