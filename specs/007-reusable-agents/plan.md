# Implementation Plan: Reusable Agents

**Branch**: `007-reusable-agents` | **Date**: 2026-04-24 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/007-reusable-agents/spec.md`

## Summary

Add workspace-scoped reusable agents to the Flutter app. Users can create, edit, delete, browse, and select agents for new and existing conversations. Each agent stores a display name, a workspace-unique slug, and instructions. Conversations store the selected agent reference and always use the latest saved agent instructions for future responses. Deleted agents disappear from selection surfaces and affected conversations fall back to "No Agent".

Technical approach: add Drift persistence for agents and conversation selections, domain entities/repositories/use cases under the existing app architecture, Riverpod providers/notifiers for UI state, chat prompt composition that prepends selected agent instructions as conversation-level guidance, and UI controls in Agents, New Chat, and Conversation screens.

## Technical Context

**Language/Version**: Dart 3.11+ with Flutter 3.41.4+ via FVM  
**Primary Dependencies**: Flutter SDK, Riverpod with code generation, Freezed, Drift, dartantic_ai, auravibes_ui  
**Storage**: Local Drift SQLite database with schema migration  
**Testing**: `fvm flutter test` for focused package tests; `fvm dart run melos analyze`, `fvm dart run melos format`, and `fvm dart run melos run validate:quick` for validation  
**Target Platform**: AuraVibes Flutter app targets supported desktop/mobile/web platforms  
**Project Type**: Flutter monorepo application feature in `apps/auravibes_app`  
**Performance Goals**: Agent list and selectors remain responsive with at least 10 workspace agents; selecting/changing an agent completes in 2 actions or fewer per spec  
**Constraints**: Use existing feature-based architecture, Drift DAOs for persistence, Riverpod generated providers, `auravibes_ui` design system, no tool presets, no model selection changes, no scheduled/background tasks, no flow builder  
**Scale/Scope**: Workspace-local agent management, conversation-level selection, latest-instructions prompt injection, delete fallback to "No Agent"

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **I. Start with User Needs**: PASS. Spec defines prioritized independently testable stories for create, select, edit, browse, and delete.
- **II. Design with Data**: PASS. This plan defines Drift tables, repository boundaries, data model, UI contract, and migration before implementation.
- **III. Package-First Architecture**: PASS. Feature belongs in `apps/auravibes_app`; reusable styling remains in `auravibes_ui`; no new package needed.
- **IV. UI Kit Mandate**: PASS. Screens and selectors must use `auravibes_ui` components/tokens.
- **V. Test-Driven Development**: PASS. Quickstart requires tests for DAO/repository/use cases/widgets before implementation, integration coverage for critical agent journeys, and a coverage audit before completion.
- **VI. Fail Fast + Explicit Errors**: PASS. Validation failures, duplicate slug conflicts, not-found cases, and cross-workspace selection rejections use meaningful explicit domain exceptions per `error-handling-exceptions`; generic catch-and-rethrow wrappers are not allowed.
- **VII. Simplicity + YAGNI**: PASS. Plan excludes tools, model choice, scheduling, background tasks, and flow builder.
- **VIII. Observability + Performance**: PASS. Plan includes task coverage for structured logging on create/edit/delete/select/fallback operations, timed manual verification for UX success criteria, and lightweight query targets.
- **IX. Security + Privacy**: PASS. Agent instructions are user-authored conversation guidance; no secrets should be logged; platform rules remain higher priority.
- **X. Code Quality Standards**: PASS. Plan follows existing Dart naming, generated providers, Freezed entities, Drift DAOs, and validation commands.

## Project Structure

### Documentation (this feature)

```text
specs/007-reusable-agents/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── reusable-agents-ui.md
└── tasks.md
```

### Source Code (repository root)

```text
apps/auravibes_app/lib/
├── data/
│   ├── database/drift/
│   │   ├── app_database.dart
│   │   ├── daos/agents_dao.dart
│   │   └── tables/agents_table.dart
│   └── repositories/agent_repository_impl.dart
├── domain/
│   ├── entities/agent.dart
│   └── repositories/agent_repository.dart
├── features/
│   ├── agents/
│   │   ├── notifiers/agents_notifier.dart
│   │   ├── providers/agent_repository_provider.dart
│   │   ├── screens/agents_screen.dart
│   │   ├── usecases/create_agent_usecase.dart
│   │   ├── usecases/delete_agent_usecase.dart
│   │   ├── usecases/update_agent_usecase.dart
│   │   └── widgets/
│   └── chats/
│       ├── notifiers/new_chat_notifier.dart
│       ├── screens/chat_conversation_screen.dart
│       ├── screens/new_chat_screen.dart
│       └── usecases/
│           ├── change_conversation_agent_usecase.dart
│           ├── send_new_message_usecase.dart
│           └── continue_agent_usecase.dart
├── router/app_router.dart
├── widgets/app_navigation_wrappers.dart
└── services/chatbot_service/build_prompt_chat_messages.dart

apps/auravibes_app/test/
├── data/
│   ├── database/agents_dao_test.dart
│   └── repositories/agent_repository_impl_test.dart
├── features/
│   ├── agents/
│   └── chats/
└── services/chatbot_service/build_prompt_chat_messages_test.dart
```

**Structure Decision**: Implement in `apps/auravibes_app` because agents are app-specific workspace/conversation behavior. Add domain/repository/data layers for persistence, feature-layer use cases and notifiers for user actions, and update chat services only where prompt composition needs selected agent instructions.

## Complexity Tracking

No constitution violations.

## Phase 0: Research

See [research.md](./research.md).

## Phase 1: Design

See [data-model.md](./data-model.md), [contracts/reusable-agents-ui.md](./contracts/reusable-agents-ui.md), and [quickstart.md](./quickstart.md).

## Post-Design Constitution Check

- **Data before UI**: PASS. `data-model.md` defines tables, relationships, validation, and transitions before task generation.
- **API contracts before providers**: PASS. `contracts/reusable-agents-ui.md` defines UI and prompt behavior contracts.
- **TDD path**: PASS. `quickstart.md` lists focused failing tests before implementation, integration tests for critical journeys, and coverage validation.
- **Simplicity**: PASS. No future workflow features enter implementation scope.
- **Security/privacy**: PASS. Prompt priority, meaningful explicit exceptions, and no-secret structured logging constraints are explicit.
