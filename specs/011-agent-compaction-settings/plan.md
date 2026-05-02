# Implementation Plan: Agent Conversation Compaction Settings

**Branch**: `011-agent-compaction-settings` | **Date**: 2026-05-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/011-agent-compaction-settings/spec.md`

## Summary

Add manual and automatic conversation compaction for long-running AI agent chats, plus a settings section that makes auto-compaction thresholds user-configurable. The MVP stores compaction state in existing message metadata: the compaction result is a normal persisted message marked as a compaction summary, with metadata identifying whether it was created manually or automatically and which prior messages it represents. Prompt assembly sends only messages from the latest compaction summary forward; conversations without a compaction summary continue sending the full message list. Compaction summaries do not include thinking state or tool-call metadata.

## Technical Context

**Language/Version**: Dart 3.11+ with Flutter 3.41.4+ via FVM  
**Primary Dependencies**: Flutter SDK, hooks_riverpod/Riverpod 3 code generation, Drift, Freezed, dartantic_ai, shared_preferences, auravibes_ui  
**Storage**: Existing Drift `messages` metadata JSON for compaction summaries; shared preferences for global compaction settings; no new Drift table for MVP  
**Testing**: Flutter unit/widget tests, provider/usecase tests, build_runner for generated Freezed/Riverpod code  
**Target Platform**: macOS, iOS, Android, Web, Linux, Windows  
**Project Type**: Flutter monorepo app  
**Performance Goals**: Manual compaction starts feedback within 250ms; auto compaction check adds no visible delay when thresholds are not met; prompt assembly does not duplicate compacted content  
**Constraints**: Preserve visible chat history; do not compact pending tools/approvals; no hardcoded user thresholds; all UI strings localized; use existing FVM/Melos commands  
**Scale/Scope**: One app feature affecting chat prompt assembly, message metadata, compaction settings UI, and focused tests

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle | Check | Status |
| --- | --- | --- |
| Business Logic Layering | Compaction policy, eligibility, summary creation, and prompt slicing live in chat use cases; providers expose state only; widgets forward intent. | Pass |
| Reactive Data | Existing chat message streams remain unchanged for visible UI. Settings can use a keepAlive generated notifier backed by shared preferences. | Pass |
| Localization | Manual compact button, settings labels, validation errors, loading/success/failure feedback require `LocaleKeys`/`TextLocale`/`tr()`. | Pass |
| Typed Errors | Compaction failures and settings validation errors require typed exceptions carrying localization keys before reaching UI. | Pass |
| AsyncValue Pattern | Any new widget consuming async state must use switch expressions/pattern matching, not `.when()`. | Pass |
| Mutation State | Manual compact and settings save actions use Riverpod `Mutation` or equivalent explicit mutation pattern. | Pass |
| UI Package Purity | App-specific compaction UI stays in `apps/auravibes_app`; `auravibes_ui` only supplies generic existing controls. | Pass |
| Widget Size | Settings section and chat input additions are decomposed into focused widgets watching at most one provider where practical. | Pass |
| Database Cascade | No schema changes planned. Existing message rows remain under conversation cascade. | Pass |

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
└── checklists/
    └── requirements.md
```

### Source Code (repository root)

```text
apps/auravibes_app/
├── lib/
│   ├── domain/
│   │   ├── entities/messages.dart                 # Add compaction metadata fields
│   │   └── enums/message_types.dart               # Reuse MessageType.system
│   ├── core/exceptions/
│   │   └── conversation_exceptions.dart           # Add typed compaction/settings failures
│   ├── features/
│   │   ├── chats/
│   │   │   ├── providers/
│   │   │   │   ├── compaction_providers.dart      # Eligibility/status/mutations
│   │   │   │   └── messages_providers.dart        # Usage/eligibility consumers
│   │   │   ├── usecases/
│   │   │   │   ├── compact_conversation_usecase.dart
│   │   │   │   ├── select_prompt_messages_usecase.dart
│   │   │   │   ├── should_auto_compact_usecase.dart
│   │   │   │   └── continue_agent_usecase.dart    # Auto check before prompt build
│   │   │   ├── widgets/
│   │   │   │   ├── chat_input_widget.dart         # Manual compact control
│   │   │   │   └── conversation_context_usage_pill.dart
│   │   │   └── screens/chat_conversation_screen.dart
│   │   └── settings/
│   │       ├── notifiers/compaction_settings_notifier.dart
│   │       ├── screens/settings_screen.dart
│   │       └── widgets/compaction_settings_section.dart
│   ├── i18n/
│   │   └── locale_keys.dart                       # Generated localization keys
│   └── services/
│       └── chatbot_service/
│           ├── build_prompt_chat_messages.dart    # Map compaction/system messages
│           └── chatbot_service.dart               # Summary generation entrypoint
└── test/
    ├── features/chats/usecases/
    ├── features/chats/widgets/
    ├── features/settings/
    └── services/chatbot_service/
```

**Structure Decision**: Keep all business logic in app feature use cases. Reuse existing message metadata JSON to avoid a schema migration. Keep app-specific compaction controls out of `packages/auravibes_ui`.

## Complexity Tracking

> No constitution violations. The feature adds metadata and use cases, but no new package, schema table, or broad repository refactor.

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --- | --- | --- |
| - | - | - |

## Research & Decisions

See [research.md](research.md).

## Design Artifacts

- [data-model.md](data-model.md)
- [contracts/ui-contracts.md](contracts/ui-contracts.md)
- [quickstart.md](quickstart.md)

## Post-Design Constitution Check

All gates still pass after Phase 1 design:

- No schema migration needed for MVP; metadata shape is versioned.
- Manual and auto compaction orchestration stays in use cases.
- Settings are persisted through existing preferences pattern.
- UI changes use localized strings and generic `auravibes_ui` components.
- Tests cover prompt slicing from latest compaction, metadata kind (`manual`/`auto`), unsafe tool boundaries, and settings validation.
