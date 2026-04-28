# Implementation Plan: Avoid Approval Flash

**Branch**: `008-avoid-approval-flash` | **Date**: 2026-04-26 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/008-avoid-approval-flash/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Prevent already-approved tool calls from flashing approval controls by sharing one resolved tool-permission decision between execution and conversation UI visibility. The implementation will keep the existing tool approval semantics, move permission resolution into a small reusable use case, and update the approval card source to show only tool calls whose shared decision is `needsConfirmation`.

## Technical Context

**Language/Version**: Dart 3.11+ with Flutter 3.41.4+ via FVM  
**Primary Dependencies**: Flutter, hooks_riverpod/Riverpod 3, riverpod_generator, Freezed, Drift, auravibes_ui  
**Storage**: Existing Drift `messages` metadata JSON and tool permission tables; no schema changes planned  
**Testing**: `fvm flutter test` in `apps/auravibes_app`; existing Mockito test pattern for use cases  
**Target Platform**: AuraVibes Flutter app across supported mobile, desktop, and web targets
**Project Type**: Flutter monorepo app feature in `apps/auravibes_app`  
**Performance Goals**: Approved tool calls should progress without approval UI in under 1 second under normal app conditions; approval card should not render for already-approved pending tool calls during conversation updates  
**Constraints**: Preserve approve, reject, approve-for-conversation, and approve-always behavior; avoid duplicated permission checks; maintain 60 fps UI expectations; use FVM-prefixed Dart/Flutter commands  
**Scale/Scope**: Current conversation screen, latest assistant message tool calls, and existing tool execution approval pipeline

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

**I. Start with User Needs**: PASS. Spec defines prioritized user stories for removing approval flashes while preserving safety prompts.

**II. Design with Data**: PASS. Uses existing message metadata and tool permission records; no new persistence or schema migration.

**III. Package-First Architecture**: PASS. Feature belongs in `apps/auravibes_app` because it coordinates app-specific conversation state and tool execution; no reusable package extraction needed.

**IV. UI Kit Mandate**: PASS. Existing approval UI already uses `auravibes_ui`; no new reusable UI component planned.

**V. Test-Driven Development**: PASS. Implementation tasks must add failing tests for approved and unapproved tool-call visibility before code changes.

**VI. Fail Fast + Explicit Errors**: PASS. Existing disabled/not-configured results stay explicit; no silent permission fallback.

**VII. Simplicity + YAGNI**: PASS. Minimal shared decision object/use case; no feature flags, new config keys, or speculative abstractions.

**VIII. Observability + Performance**: PASS. Removes transient UI work for approved calls and reuses the execution decision path.

**IX. Security + Privacy**: PASS. Maintains existing approval gates; no secrets or user data added to docs/tests.

**X. Code Quality Standards**: PASS. Implementation must preserve generated Riverpod/Freezed patterns and pass analyzer/format checks.

## Project Structure

### Documentation (this feature)

```text
specs/008-avoid-approval-flash/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
apps/auravibes_app/
├── lib/
│   ├── features/chats/providers/messages_providers.dart
│   ├── features/chats/widgets/chat_tool_approval_card.dart
│   ├── features/chats/screens/chat_conversation_screen.dart
│   └── features/tools/usecases/
│       ├── run_allowed_tools_usecase.dart
│       └── [shared permission decision use case]
└── test/
    ├── features/chats/providers/[approval visibility provider test]
    └── features/tools/usecases/run_allowed_tools_usecase_test.dart
```

**Structure Decision**: Implement inside `apps/auravibes_app` because the behavior depends on app conversation state, existing repositories, and the tool execution pipeline. No package extraction is needed because this is not reusable UI kit behavior.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution violations.
