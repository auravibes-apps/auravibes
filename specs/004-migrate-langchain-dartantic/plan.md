# Implementation Plan: Migrate AI Orchestration Framework

**Branch**: `004-migrate-langchain-dartantic` | **Date**: 2026-04-21 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/004-migrate-langchain-dartantic/spec.md`

## Summary

Replace all LangChain Dart usage (`langchain`, `langchain_openai`, `langchain_anthropic`) with `dartantic_ai` across the AuraVibes Flutter monorepo. This is a big-bang migration that preserves all user-facing behavior including chat, streaming, tool calling, MCP integration, token usage tracking, and multi-provider support, while enabling all dartantic_ai built-in providers via models.dev integration.

## Technical Context

**Language/Version**: Dart 3.11+ (FVM pinned to 3.41.4+)  
**Primary Dependencies**: Flutter SDK, Riverpod (with code generation), dartantic_ai, Drift  
**Storage**: Drift (SQLite) — no schema changes required  
**Testing**: flutter_test, mockito, very_good_analysis linting  
**Target Platform**: iOS, Android, macOS, Windows, Linux, Web  
**Project Type**: Flutter monorepo (cross-platform AI assistant app)  
**Performance Goals**: First-token latency <2s, end-to-end response time within 10% of current baseline, 60 fps during streaming  
**Constraints**: Must pass `very_good_analysis` with zero warnings, 80%+ coverage for new tests, single commit big-bang migration  
**Scale/Scope**: 22 files directly affected across service layer, tool system, streaming pipeline, and test suite

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle                         | Status  | Notes                                                |
| --------------------------------- | ------- | ---------------------------------------------------- |
| I. Start with User Needs          | ✅ PASS | 5 prioritized user stories with acceptance scenarios |
| II. Design with Data              | ✅ PASS | Key entities defined; no schema changes needed       |
| III. Package-First Architecture   | ✅ PASS | Migration stays within existing app structure        |
| IV. UI Kit Mandate                | ✅ PASS | No UI changes required                               |
| V. Test-Driven Development        | ✅ PASS | 100% existing tests + new targeted tests required    |
| VI. Fail Fast + Explicit Errors   | ✅ PASS | Edge cases cover error scenarios                     |
| VII. Simplicity + YAGNI           | ✅ PASS | Big-bang approach minimizes complexity               |
| VIII. Observability + Performance | ✅ PASS | Latency targets defined (within 10%)                 |
| IX. Security + Privacy            | ✅ PASS | API key handling unchanged (secure storage)          |
| X. Code Quality Standards         | ✅ PASS | Must pass very_good_analysis with zero warnings      |

**Result**: All gates pass. Proceed to Phase 0.

## Project Structure

### Documentation (this feature)

```text
specs/004-migrate-langchain-dartantic/
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
│   ├── services/
│   │   ├── chatbot_service/           # Chat model init, streaming, title gen
│   │   │   ├── chatbot_service.dart
│   │   │   ├── build_prompt_chat_messages.dart
│   │   │   └── models/
│   │   │       └── chat_message_models.dart
│   │   └── tools/                     # Tool definitions and specs
│   │       ├── native_tool_entity.dart
│   │       ├── user_tools_entity.dart
│   │       └── native_tools/
│   │           ├── calculator_tool.dart
│   │           └── url_tool.dart
│   ├── features/
│   │   └── chats/
│   │       ├── usecases/
│   │       │   └── continue_agent_usecase.dart
│   │       └── notifiers/
│   │           └── messages_streaming_notifier.dart
│   ├── domain/
│   │   └── usecases/
│   │       └── tools/
│   │           └── mcp/
│   │               └── build_combined_tool_specs_usecase.dart
│   └── utils/
│       └── chat_result_extension.dart
└── test/
    ├── services/chatbot_service/
    ├── features/chats/usecases/
    └── domain/usecases/tools/mcp/
```

**Structure Decision**: This migration is confined to the existing `apps/auravibes_app` service and feature layers. No new packages or directories are created. LangChain dependencies are removed from `pubspec.yaml` and replaced with `dartantic_ai`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations detected. All constitution gates pass.

---

## Generated Artifacts

| Artifact         | Path                                                               | Phase   |
| ---------------- | ------------------------------------------------------------------ | ------- |
| Research         | [research.md](research.md)                                         | Phase 0 |
| Data Model       | [data-model.md](data-model.md)                                     | Phase 1 |
| Quickstart       | [quickstart.md](quickstart.md)                                     | Phase 1 |
| Service Contract | [contracts/chatbot_service.md](contracts/chatbot_service.md)       | Phase 1 |
| Tool Contract    | [contracts/tool_definition.md](contracts/tool_definition.md)       | Phase 1 |
| Message Contract | [contracts/message_conversion.md](contracts/message_conversion.md) | Phase 1 |
