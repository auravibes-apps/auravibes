---
name: flutter-controller-pattern
description: Use when moving business logic out of Flutter widgets/providers into Riverpod controllers and needing clear boundaries for controller state, use-case orchestration, presentation intents, and controller-focused tests.
---

# Flutter Controller Pattern

## Overview
Use controllers as application orchestrators: widgets dispatch intent, controllers coordinate use cases, and domain logic stays in use cases.

In this repo, `ToolExecutionController` is the reference pattern:
- state holder + query API + intent API in `apps/auravibes_app/lib/providers/tool_execution_controller.dart`
- stream/message manager delegates tool lifecycle to controller in `apps/auravibes_app/lib/providers/messages_manager_provider.dart`
- widgets render state and call intent methods in chat widgets.

## When to Use
- A provider/notifier is mixing state + business rules + side effects.
- Widgets contain permission/execution branching.
- A feature needs reusable intent methods (`run`, `grant`, `skip`, `stop`) across multiple widgets.

## When NOT to Use
- Pure computed read-only value providers.
- One-line UI-only state with no orchestration.

## Controller Responsibilities
- Keep a UI-oriented state model (small immutable entities used for rendering).
- Expose query methods for view logic (for example: `isToolRunning`, `hasRunningToolsForMessage`).
- Expose intent methods for user actions (`runTask`, `grantToolCall`, `skipToolCall`, `stopAllToolCalls`).
- Build/coordinate use cases inside controller methods with injected dependencies.
- Keep cleanup and failure-safe logic in controller (`try/finally`, guard clauses).

## Dependency Boundary Rule
- Default: controllers call use cases, not repositories.
- Allow direct repository calls only for thin reads with no business decisions, no branching by business state, and no cross-repository orchestration.
- If logic includes validation, permission checks, sequencing, metadata updates, retries, or combining dependencies, move it into a use case.
- If a controller method starts looking like domain behavior (not UI orchestration), extract/expand use cases first.

## UI Responsibilities
- Watch controller state and map it to presentation.
- Trigger controller intents from user actions.
- Avoid embedding business flow (permission checks, execution order, metadata updates) in widgets.

## Migration Pattern (old provider -> controller)
1. Extract orchestration logic from old provider into a `@Riverpod(keepAlive: true)` controller.
2. Keep domain rules in use cases and call them from controller methods.
3. Keep only rendering decisions in widgets.
4. Update existing managers/notifiers to delegate specialized flow to controller.

## Testing Guidance
- Controller unit tests:
  - state transitions for running/resolved/cleared flows.
  - guard clause behavior for missing entities/ids.
  - intent method behavior (`runTask`, `grant`, `skip`, `stop`).
  - failure safety (`finally` cleanup always runs).
- Orchestration tests:
  - verifies use cases are called with expected inputs and order.
  - verifies AI continuation only when all tools are resolved/granted.
- Widget tests:
  - verify widgets dispatch the correct controller intents.
  - verify pending/running/resolved UI branches from controller state + metadata.

## Common Mistakes
- Re-adding business rules inside widgets after controller extraction.
- Calling repositories directly from controllers for business actions.
- Storing raw domain-heavy payloads in controller state.
- Skipping query helpers and duplicating filters in UI files.
- Instantiating side-effect services directly in widgets.

## Quick Checklist
- Controller owns orchestration, widgets own presentation.
- Business actions go through use cases (repo access in controller is read-only exception).
- Controller state is minimal and UI-friendly.
- Intent/query APIs are explicit and reusable.
- Use cases remain the business rule boundary.
- Tests cover controller transitions, orchestration, and widget intent dispatch.
