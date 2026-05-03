# Implementation Plan: Agent Conversation Compaction Settings

**Branch**: `011-agent-compaction-settings` | **Date**: 2026-05-02 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/011-agent-compaction-settings/spec.md`

## Summary

Add automatic and manual conversation compaction with configurable thresholds, plus transparent UI states for compaction progress and results. Implementation keeps full visible conversation history, inserts compaction checkpoints into message history as dedicated system messages, shows a tappable `Compacted` widget in chat, shows a temporary `Compacting` row in conversation list, and routes sends through the existing queue when compaction is active.

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter 3.41.4+ (FVM pinned)
**Primary Dependencies**: Flutter SDK, hooks_riverpod/Riverpod 3 (code generation), drift, freezed/json_serializable, auravibes_ui, dartantic_ai
**Storage**: Drift SQLite (`messages` metadata JSON, conversations/messages tables) + shared preferences for global compaction settings
**Testing**: flutter_test, mocktail, Riverpod/provider tests, use case tests, widget tests
**Target Platform**: macOS, iOS, Android, Web, Linux, Windows
**Project Type**: Flutter monorepo application
**Performance Goals**: Auto compaction executes before continuation on all required checks; no duplicate pre-summary payload; queue ordering preserved during compaction
**Constraints**: Never split unresolved tool-call/result chains; no thinking/tool metadata in compaction summaries; manual compaction must not trigger auto-continue; stored compaction text remains untrimmed for user inspection
**Scale/Scope**: Long-running single-user local conversations; multiple compaction cycles per conversation; global settings apply across conversations

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design._

| Principle                               | Check                                                                                                   | Status |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------ |
| I. User Value First                     | Spec contains independently testable P1-P3 stories for auto compaction, manual compaction, and settings | PASS   |
| II. Layered, Package-Aware Architecture | Business logic planned in use cases/providers; UI state in widgets; persistence in repositories/DAOs    | PASS   |
| III. UI System First                    | New compacting/compacted UI states will use existing `auravibes_ui` components and localization         | PASS   |
| IV. Data and State Correctness          | Existing Drift message metadata extended with versioned fields; provider lifecycle explicit             | PASS   |
| V. Risk-Based Quality Gates             | Use case tests + widget tests + prompt selection tests cover behavior changes                           | PASS   |
| VI. Explicit Failures                   | Required auto-compaction failure blocks continuation and persists recoverable visible error             | PASS   |
| VII. Security and Privacy               | No secret logging; compaction content persisted locally; no extra credential surface                    | PASS   |
| VIII. Observable Where It Matters       | Compaction start/success/failure and blocked continuations can be logged without sensitive payload      | PASS   |
| IX. Simplicity                          | Reuse existing queue, message stream, and settings patterns; no new table for MVP                       | PASS   |
| X. Dart and Flutter Standards           | FVM, analyzer, formatter, tests required before completion                                              | PASS   |

**Post-Design Re-check**: PASS. Design artifacts keep use-case layering, typed metadata, UI localization, and queue reuse without constitution exceptions.

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
└── tasks.md
```

### Source Code (repository root)

```text
apps/auravibes_app/
├── lib/
│   ├── features/chats/
│   │   ├── usecases/
│   │   │   ├── compact_conversation_usecase.dart
│   │   │   ├── should_auto_compact_usecase.dart
│   │   │   └── select_prompt_messages_usecase.dart
│   │   ├── widgets/
│   │   │   ├── chat_messages_widget.dart
│   │   │   ├── chat_list_widget.dart
│   │   │   ├── chat_input_widget.dart
│   │   │   └── sidebar_conversations_widget.dart
│   │   └── providers/
│   │       └── compaction_* providers/notifiers
│   ├── data/
│   │   ├── repositories/message_repository_impl.dart
│   │   └── database/drift/
│   │       ├── daos/message_dao.dart
│   │       └── tables/messages_table.dart
│   └── services/chatbot_service/
│       └── build_prompt_chat_messages.dart
└── test/
    ├── features/chats/usecases/
    ├── features/chats/widgets/
    └── features/settings/
```

**Structure Decision**: Keep feature logic in `apps/auravibes_app` chat and settings layers. Reuse existing storage and queue infrastructure. Do not add domain-specific widgets to `packages/auravibes_ui` unless a second concrete reuse appears.

## Complexity Tracking

No constitution violations expected.

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| None      | N/A        | N/A                                  |

## Phase 0: Research & Decisions

Research complete in [research.md](research.md). All prior ambiguities resolved.

Key decisions:

1. Persist compaction summaries as metadata-marked system messages in the existing message stream.
2. Show summaries in chat as a tappable `Compacted` widget; show in-progress conversation-list state as separate temporary `Compacting` row.
3. Reuse existing send queue by treating active compaction as busy.
4. Store original (untrimmed) compaction text; normalize only when building model payload.
5. Select prompt context from latest compaction summary forward.

## Phase 1: Design & Contracts

Design artifacts:

- [data-model.md](data-model.md)
- [contracts/ui-contracts.md](contracts/ui-contracts.md)
- [quickstart.md](quickstart.md)

Design scope:

1. Extend message metadata with compaction identity/range fields and persisted content policy.
2. Define UI behavior contracts for loading, queued sends, and compacted-message detail view.
3. Define prompt boundary rules and failure handling contracts.
4. Define settings validation and defaults.

## Phase 2: Task Planning Approach

Task generation (`/speckit.tasks`) should split work by vertical behavior slices:

1. Compaction domain/use-case logic and metadata writes.
2. Prompt selection boundary integration.
3. Conversation list + chat message UI states (`Compacting`, `Compacted`, detail tap).
4. Queue/busy integration with existing send queue.
5. Settings UI, persistence, and validation.
6. Tests for auto/manual flows, failure paths, and payload normalization behavior.
