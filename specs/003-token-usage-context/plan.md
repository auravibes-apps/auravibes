# Implementation Plan: Conversation Token Usage Indicator

**Branch**: `003-token-usage-context` | **Date**: 2026-04-15 | **Spec**: `/specs/003-token-usage-context/spec.md`
**Input**: Feature specification from `/specs/003-token-usage-context/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Persist per-message token usage metadata from `ChatResult.usage`, aggregate usage per conversation (including in-flight streaming state), and render top-bar context usage (`used/limit - percent`) with a circular progress indicator.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Dart 3.11+ with Flutter 3.41.4+ (FVM pinned)  
**Primary Dependencies**: Flutter, Riverpod, Drift, LangChain (`ChatResult` / `LanguageModelUsage`), auravibes_ui  
**Storage**: Existing Drift `messages` table metadata JSON (no schema migration planned)  
**Testing**: Flutter unit/widget tests with existing test suites under `apps/auravibes_app/test`  
**Target Platform**: Flutter app targets currently supported by monorepo  
**Project Type**: Mobile/desktop/web Flutter application in Melos monorepo  
**Performance Goals**: Top bar usage updates during stream without visible lag; preserve current chat streaming smoothness (60fps target)  
**Constraints**: Minimal persistence fields only; no broad data-model refactor; percent/progress clamped to `[0,100]`  
**Scale/Scope**: One feature in chat conversation flow; no cross-conversation analytics

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- ✅ Principle I (User Needs): Spec has prioritized user stories and acceptance criteria focused on conversation usage visibility.
- ✅ Principle II (Design with Data): Data model updates defined before UI implementation; persistence flow explicit.
- ✅ Principle III/IV (Package/UI): UI changes stay in app screen and use existing design system widgets/tokens.
- ✅ Principle V (TDD): Add/extend unit tests for usage mapping, aggregation, and streaming overlay behavior.
- ✅ Principle VI (Fail Fast): Missing usage fields default to safe zero behavior.
- ✅ Principle VII (Simplicity): Reuse existing metadata JSON and providers; avoid schema/migration unless proven necessary.
- ✅ Principle VIII (Observability/Performance): Lightweight calculations; no heavy recomputation loops.
- ✅ Principle IX (Security/Privacy): No new sensitive data persisted.
- ✅ Principle X (Quality): Maintain lint/format/test standards.

## Project Structure

### Documentation (this feature)

```text
specs/003-token-usage-context/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)
<!--
  ACTION REQUIRED: Replace the placeholder tree below with the concrete layout
  for this feature. Delete unused options and expand the chosen structure with
  real paths (e.g., apps/admin, packages/something). The delivered plan must
  not include Option labels.
-->

```text
apps/auravibes_app/
├── lib/
│   ├── domain/entities/messages.dart
│   ├── data/repositories/message_repository_impl.dart
│   ├── utils/chat_result_extension.dart
│   ├── features/chats/usecases/continue_agent_usecase.dart
│   ├── features/chats/providers/messages_providers.dart
│   └── features/chats/screens/chat_conversation_screen.dart
└── test/
    ├── features/chats/usecases/continue_agent_usecase_test.dart
    └── features/chats/providers/chat_messages_provider_test.dart
```

**Structure Decision**: Existing Flutter app structure in `apps/auravibes_app` is sufficient. Feature touches domain metadata entity, chat streaming persistence use case, providers for conversation aggregation, and conversation app bar UI.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
