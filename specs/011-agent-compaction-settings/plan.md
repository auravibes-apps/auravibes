# Implementation Plan: Agent Conversation Compaction Settings

**Branch**: `011-agent-compaction-settings` | **Date**: 2026-05-03 | **Spec**: `specs/011-agent-compaction-settings/spec.md`
**Input**: Feature specification from `specs/011-agent-compaction-settings/spec.md`

**Note**: This plan is produced by `/speckit.plan` and stops after Phase 1 design artifacts. Task generation happens in `/speckit.tasks`.

## Summary

Add automatic and manual conversation compaction for long-running AuraVibes agent chats. Compaction eligibility is decided by deterministic global settings (enabled, usage percentage threshold, remaining-token threshold), while summary generation calls the AI agent service using the same provider/model selected for the active conversation and a compaction-specific system prompt. The full transcript remains visible; prompt assembly uses the latest compaction summary plus a safe recent tail so old compacted content is not duplicated in model context.

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter 3.41.4+ via repository-pinned FVM SDK  
**Primary Dependencies**: Flutter SDK, hooks_riverpod/Riverpod 3 with code generation, Drift, Freezed/json_serializable, auravibes_ui, dartantic_ai / existing AI agent service  
**Storage**: Existing Drift SQLite `messages` metadata JSON for compaction summaries and ranges; Drift v2 `workspace_compaction_settings` table for per-workspace compaction settings  
**Testing**: `fvm flutter test` for focused package tests; `fvm dart run melos analyze`, `fvm dart run melos format`, `fvm dart run melos run test`, `fvm dart run melos run validate:quick` for workspace checks  
**Target Platform**: Flutter app targets supported by `apps/auravibes_app`  
**Project Type**: Flutter monorepo mobile/desktop app feature  
**Performance Goals**: Avoid duplicated compacted context in 100% of prompt payload tests; retry context-overflow continuations at most once; keep compaction prompt-building work bounded to conversation message count  
**Constraints**: No destructive transcript deletion; Drift schema v2 migration for workspace_compaction_settings table; no compaction while unresolved tool approvals/tool calls are pending; all user-facing strings localized; compaction business logic in use cases; active compaction uses explicit mutation/busy state  
**Scale/Scope**: One app feature in `apps/auravibes_app`; global settings section; message metadata extension; prompt-building, assistant-continuation, chat-input, conversation-list, and chat-transcript integration points

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

1. **Business Logic Layering**: PASS. Compaction eligibility, range selection, summary generation orchestration, prompt selection, and retry behavior will live in domain/usecase classes. Providers expose state and widgets render/delegate intent.
2. **Reactive Data**: PASS. Conversation messages and settings that feed live UI remain exposed through existing reactive provider/repository patterns; one-shot calls are limited to command-style compaction mutations.
3. **Localization**: PASS. Settings labels, validation messages, compacting rows, compacted widgets, details labels, and recoverable errors must use localization keys/TextLocale.
4. **Typed Errors**: PASS. User-facing compaction failures and invalid settings must be typed domain exceptions carrying localization keys and recovery context.
5. **AsyncValue Pattern**: PASS. New AsyncValue UI consumption must use Dart 3 switch expressions/pattern matching, not `.when()`.
6. **Mutation State**: PASS. Manual compaction, auto compaction, settings save/reset, and retryable actions use Riverpod `Mutation` or an equivalent explicit mutation state rather than manual loading toggles.
7. **UI Package Purity**: PASS. Compaction-specific widgets live in the app; `auravibes_ui` remains domain-agnostic and is only used through generic components.
8. **Widget Size**: PASS. Chat input control, compacted widget, details view, settings section, and conversation-list compacting row should be decomposed so each widget watches at most one provider where practical.
9. **Database Cascade**: PASS. No new foreign-key schema changes are planned. Existing message metadata JSON is extended; if schema changes become necessary later, Drift migrations and cascade rules are required.

## Project Structure

### Documentation (this feature)

```text
specs/011-agent-compaction-settings/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── ui-contracts.md
├── spec.md
└── tasks.md
```

### Source Code (repository root)

```text
apps/auravibes_app/
├── lib/
│   ├── data/
│   │   └── database/drift/tables/messages_table.dart
│   ├── domain/
│   │   └── entities/messages.dart
│   ├── features/
│   │   ├── chats/
│   │   │   ├── providers/
│   │   │   │   ├── context_usage_provider.dart
│   │   │   │   └── messages_providers.dart
│   │   │   ├── screens/chat_conversation_screen.dart
│   │   │   ├── usecases/
│   │   │   │   ├── compact_conversation_usecase.dart
│   │   │   │   ├── continue_agent_usecase.dart
│   │   │   │   ├── estimate_conversation_prompt_tokens_usecase.dart
│   │   │   │   ├── run_agent_iteration_usecase.dart
│   │   │   │   └── should_compact_conversation_usecase.dart
│   │   │   └── widgets/
│   │   │       ├── chat_input_widget.dart
│   │   │       ├── compacted_message_widget.dart
│   │   │       └── conversation_context_usage_pill.dart
│   │   └── settings/
│   │       ├── providers/
│   │       └── widgets/
│   └── services/chatbot_service/
│       ├── build_prompt_chat_messages.dart
│       └── chatbot_service.dart
└── test/
    ├── features/chats/
    │   ├── usecases/
    │   └── widgets/
    ├── features/settings/
    └── services/chatbot_service/
```

**Structure Decision**: Implement inside `apps/auravibes_app` because compaction is app-specific agent behavior. Reuse generic `auravibes_ui` components only; do not add domain-specific compaction components to `packages/auravibes_ui`.

## Complexity Tracking

No constitution violations are planned.

## Phase 0: Research

Research output is captured in `specs/011-agent-compaction-settings/research.md`.

All technical unknowns are resolved:

- Use existing Drift message metadata JSON, not a new table, for MVP compaction summaries and ranges.
- Persist settings globally in shared preferences.
- Decide auto eligibility deterministically from thresholds.
- Generate summaries through the active conversation model/provider via AI agent service.
- Keep a minimum recent tail and complete tool-call/result groups outside compacted ranges.
- Retry context-overflow continuations once after safe compaction.

## Phase 1: Design & Contracts

Design artifacts are generated:

- `specs/011-agent-compaction-settings/data-model.md`
- `specs/011-agent-compaction-settings/contracts/ui-contracts.md`
- `specs/011-agent-compaction-settings/quickstart.md`

## Post-Design Constitution Check

1. **Business Logic Layering**: PASS. `CompactConversationUsecase`, `ShouldCompactConversationUsecase`, and prompt-building logic own decisions; widgets remain presentation-only.
2. **Reactive Data**: PASS. Live conversation/settings UI uses providers; mutation actions remain explicit.
3. **Localization**: PASS. Contracts and quickstart require localized settings, errors, and UI labels.
4. **Typed Errors**: PASS. Data model and contracts require recoverable typed failures for invalid settings and compaction errors.
5. **AsyncValue Pattern**: PASS. Implementation tasks must enforce switch-expression AsyncValue handling.
6. **Mutation State**: PASS. Compaction and settings writes are mutation actions.
7. **UI Package Purity**: PASS. Domain-specific UI stays in app feature folders.
8. **Widget Size**: PASS. Planned UI components are small and focused.
9. **Database Cascade**: PASS. No new FK schema change is part of MVP.
