# Implementation Plan: Two-Step Model Selector

**Branch**: `001-two-step-model-selector` | **Date**: 2026-03-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-two-step-model-selector/spec.md`

## Summary

Replace the single model dropdown with a two-step cascading selector: provider selection first, then model selection filtered by provider. This matches user mental models (provider-first thinking) and scales gracefully from 5 to 50+ models.

**Technical Approach**: Add `providerId` to existing `NewChatState`, create a grouped models provider that maps provider names to model lists, and refactor `SelectCredentialsModelWidget` to render two `AuraDropdownSelector` widgets side-by-side.

## Technical Context

**Language/Version**: Dart 3.x (FVM pinned to 3.41.4+)
**Primary Dependencies**: Flutter, Riverpod (with code generation), Freezed, auravibes_ui
**Storage**: Drift database (existing, no schema changes needed)
**Testing**: flutter_test, widget tests, unit tests
**Target Platform**: iOS, Android, Web, macOS, Windows, Linux (6 platforms)
**Project Type**: Flutter mobile/desktop app in monorepo
**Performance Goals**: 60 fps UI, <3s startup, instant dropdown rendering
**Constraints**: Must fit in app bar, no modal/sheet, work offline
**Scale/Scope**: 5-50 models across 2-10 providers per workspace

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Evidence |
|-----------|--------|----------|
| I. Start with User Needs | ✅ PASS | Spec includes 3 prioritized user stories with acceptance scenarios |
| II. Design with Data | ✅ PASS | Uses existing entities (Provider, Model, Credentials), no new DB schema |
| III. Package-First Architecture | ✅ PASS | Changes scoped to existing `features/models/` and `features/chats/` |
| IV. UI Kit Mandate | ✅ PASS | Uses existing `AuraDropdownSelector` from `auravibes_ui` |
| V. Test-Driven Development | ⚠️ PLANNED | Tests will be written before implementation (TDD) |
| VI. Fail Fast + Explicit Errors | ✅ PASS | Handles loading/error states explicitly |
| VII. Simplicity + YAGNI | ✅ PASS | Minimal change: 3 files modified, 1 provider added |
| VIII. Observability + Performance | ✅ PASS | No new async operations, leverages existing providers |
| IX. Security + Privacy | ✅ PASS | No changes to credential storage or API key handling |
| X. Code Quality Standards | ✅ PASS | Will follow very_good_analysis, <400 lines per file |

**Gate Result**: ✅ PASS - All principles satisfied, TDD planned for implementation

## Project Structure

### Documentation (this feature)

```text
specs/001-two-step-model-selector/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
apps/auravibes_app/
├── lib/
│   ├── features/
│   │   ├── chats/
│   │   │   ├── providers/
│   │   │   │   ├── new_chat_controller.dart      # MODIFY: Add providerId state
│   │   │   │   ├── new_chat_controller.freezed.dart
│   │   │   │   └── new_chat_controller.g.dart
│   │   │   └── screens/
│   │   │       └── new_chat_screen.dart          # MODIFY: Wire up provider selection
│   │   └── models/
│   │       ├── providers/
│   │       │   ├── list_chat_models_providers.dart  # MODIFY: Add grouped provider
│   │       │   └── list_chat_models_providers.g.dart
│   │       └── widgets/
│   │           └── select_chat_model.dart        # REFACTOR: Two dropdown widgets
│   └── i18n/
│       ├── locale_keys.dart                       # MODIFY: Add new locale keys
│       └── en.yaml                                # MODIFY: Add translations
└── test/
    └── features/
        └── models/
            └── widgets/
                └── select_chat_model_test.dart   # CREATE: Widget tests
```

**Structure Decision**: Feature scoped to existing `features/models/` and `features/chats/` directories. No new packages or modules needed. Follows monorepo package-first architecture.

## Complexity Tracking

> No constitution violations. This section is empty.

---

## Phase 0: Research

### Research Tasks

| Topic | Decision | Rationale |
|-------|----------|-----------|
| Grouping strategy | Group by `modelsProvider.name` (String) | Provider names are unique and user-facing; avoids complex ID-based grouping |
| State reset behavior | Reset `modelId` when `providerId` changes | Matches user expectation: changing provider means re-selecting model |
| Single provider handling | Pre-select if only one provider exists | Reduces friction for simple configurations (P3 user story) |
| Dropdown layout | Side-by-side in Row with equal flex | Fits in app bar, symmetrical visual weight |
| Search/filter in dropdown | Use existing AuraDropdownSelector search | No custom implementation needed |

### Technical Decisions

1. **Provider Identifier**: Use `providerName` (String) instead of `providerId` for grouping
   - Rationale: Simpler lookup, provider names are unique and stable
   - Alternative rejected: `providerId` would require additional mapping

2. **State Shape**: Add `providerId: String?` to `NewChatState`
   - Rationale: Minimal change, follows existing pattern
   - Alternative rejected: Separate provider for selection state (over-engineering)

3. **Widget Composition**: Two private `_ProviderDropdown` and `_ModelDropdown` widgets
   - Rationale: Separation of concerns, testable in isolation
   - Alternative rejected: Single monolithic widget (harder to test)

---

## Phase 1: Design

### Data Model

See [data-model.md](./data-model.md) for entity details.

**Key Insight**: No new entities needed. Uses existing:
- `CredentialsModelWithProviderEntity` - Already contains provider info
- `NewChatState` - Extended with `providerId` field

### Contracts

No external API contracts for this feature. Internal contracts:

| Contract | Provider | Consumer |
|----------|----------|----------|
| `listModelsGroupedByProviderProvider` | `list_chat_models_providers.dart` | `SelectCredentialsModelWidget` |
| `setProvider(String?)` | `NewChatController` | `SelectCredentialsModelWidget` |
| `setModelId(String?)` | `NewChatController` (existing) | `SelectCredentialsModelWidget` |

### Quickstart

See [quickstart.md](./quickstart.md) for implementation guide.

---

## Phase 2: Tasks

Tasks will be generated by `/speckit.tasks` command after plan approval.

**Estimated Tasks**:
1. Add `providerId` state to `NewChatController`
2. Create `listModelsGroupedByProviderProvider`
3. Refactor `SelectCredentialsModelWidget`
4. Update `NewChatScreen` wiring
5. Add locale keys and translations
6. Write widget tests
7. Run validation and fix issues

**Estimated Time**: 2-3 hours including tests
