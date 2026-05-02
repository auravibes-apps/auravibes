# Research: Agent Conversation Compaction Settings

## Decision: Store compaction result as a metadata-marked message

**Decision**: The compaction result is persisted as a normal message in the existing conversation message stream. Its metadata marks it as a compaction summary, records `manual` or `auto`, and records the compacted message range. It must not include thinking state or tool-call metadata.

**Rationale**: Existing message persistence already supports metadata JSON and message ordering. This keeps visible history intact, avoids a new Drift table for MVP, and gives prompt assembly one concrete anchor: the latest compaction summary.

**Alternatives considered**:

- Dedicated compaction table: cleaner long-term audit model, but adds migration/test cost before MVP needs it.
- Mutating/deleting old messages: reduces storage but risks data loss and violates visible transcript preservation.
- In-memory-only summaries: simpler first run but fails across restart.

## Decision: Prompt history starts at latest compaction summary

**Decision**: When preparing messages for the LLM agent service, select the latest sent compaction summary in the conversation. If one exists, send that compaction message and all later messages. If none exists, send all messages.

**Rationale**: This directly matches the requested behavior and prevents duplicated compacted content. It also avoids complex "covered message id" filtering in the first implementation because chronological slicing is sufficient when each new compaction supersedes prior context.

**Alternatives considered**:

- Exclude messages by `compactedMessageIds`: more precise but slower and more complex; still useful metadata for validation/audit.
- Keep a hand-picked recent tail before compaction: useful in some agents, but the user requested "from the last compaction"; the compaction message is the boundary.
- Summary-only prompt after compaction: loses new messages after compaction and is not viable.

## Decision: Reuse `MessageType.system` for compaction summaries

**Decision**: Compaction summaries should be persisted as non-user system messages with compaction metadata. Prompt building maps those messages to system/context messages for the LLM. They are not assistant messages and do not carry tool calls.

**Rationale**: `MessageType.system` already exists. A compaction summary is context for the model, not user text and not assistant output. This also makes it easy to hide or render differently in the visible transcript.

**Alternatives considered**:

- Store summary as assistant text: easier with current prompt builder but semantically wrong and risks the app treating it like assistant tool output.
- Add a new message type: possible, but unnecessary for MVP because system messages already express model context.

## Decision: Use metadata JSON, versioned

**Decision**: Extend `MessageMetadataEntity` with compaction fields, including a metadata version. Generated Freezed/JSON files must be rebuilt.

**Rationale**: The constitution requires persisted metadata to be versioned when shape can change. Metadata JSON lets the feature ship without Drift migration while preserving enough data for prompt selection and future migrations.

**Alternatives considered**:

- No version field: simpler but makes future metadata migrations ambiguous.
- Separate JSON blob string for compaction: duplicates JSON parsing and weakens type safety.

## Decision: Hide compaction summaries from normal chat transcript

**Decision**: Compaction summary messages are persisted and used for prompt selection, but hidden from the normal visible chat transcript.

**Rationale**: The summary is model context, not a conversational turn. Hiding it keeps the user transcript readable while still preserving the summary as durable prompt state.

**Alternatives considered**:

- Visible system checkpoint card: useful for transparency, but adds noise to normal chat flow.
- Expandable details control: useful future enhancement, but not needed for MVP.

## Decision: Settings live in shared preferences via generated notifier

**Decision**: Global compaction settings use the existing preferences pattern from theme settings: a generated keepAlive notifier reads/writes shared preferences. Defaults are auto compaction enabled, 80% usage threshold, and 4,000 remaining-token threshold.

**Rationale**: Settings are global app preferences, not conversation records. The app already uses shared preferences for theme selection.

**Alternatives considered**:

- Drift app settings table: useful if settings need sync/query history later, but heavier than MVP needs.
- Hardcoded constants: rejected by user requirement.
- Workspace/model-specific settings: useful future scope, but global defaults satisfy the current feature.

## Decision: Auto compaction requires both percentage and token-gap thresholds

**Decision**: Auto compaction runs only when enabled and both configured conditions are met: used context percentage is at or above threshold, and remaining context tokens are at or below threshold.

**Rationale**: Percentage alone behaves poorly across model context sizes. Remaining-token gap alone can compact too aggressively on small models. The combined policy matches the research findings and user requirement.

**Alternatives considered**:

- Percentage only: too coarse.
- Token gap only: harder for users to reason about.
- Provider-specific thresholds: possible later, not needed for MVP.

## Decision: Auto check runs before assistant continuation and after tool-safe boundaries

**Decision**: Auto compaction is evaluated in the assistant continuation path before prompt building, but only when the conversation is not waiting on unresolved tool approvals or pending tool calls. In multi-step agent loops, the check happens before each response request once tool results have already been written.

**Rationale**: This matches agent behavior from other tools and avoids invalid model history from split tool calls/results. It also matches the app architecture where `ContinueAgentUsecase` is the point where persisted messages become model history.

**Alternatives considered**:

- Run compaction from UI after each message: misses background/agent loop continuations and puts business logic in widgets.
- Run compaction after every database write: too broad and harder to reason about tool safety.

## Decision: Manual compaction shares the same use case as auto compaction

**Decision**: Manual compaction from the chat input calls `CompactConversationUsecase` with kind `manual`. Auto compaction calls the same use case with kind `auto`. Manual compaction is checkpoint-only: after success, the app waits for the next user action and does not automatically ask the assistant to continue.

**Rationale**: One compaction path keeps metadata, eligibility, summary generation, and failure behavior consistent.

**Alternatives considered**:

- Separate manual and auto implementations: likely duplication and drift.
- Manual only creates marker without summary: does not reduce prompt context.
- Manual compact then auto-continue: surprising because compact is an explicit maintenance/checkpoint action.

## Decision: Required auto-compaction failure blocks continuation

**Decision**: If auto compaction is required because thresholds are met but summary generation or persistence fails, assistant continuation is blocked. The app leaves compactable context unchanged and persists a visible localized chat error message.

**Rationale**: The clarified product behavior prefers explicit failure over continuing with a prompt that has already crossed configured compaction thresholds. Persisting the error in chat makes the blocked continuation understandable and retryable.

**Alternatives considered**:

- Skip compaction and continue: better continuity, but violates the configured safety gate once compaction is required.
- Transient error only: less transcript noise, but the user may lose the reason continuation stopped after navigation/restart.
