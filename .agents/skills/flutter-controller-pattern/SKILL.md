---
name: flutter-controller-pattern
description: Use only when maintaining existing Flutter controllers. For new or migrated Riverpod mutable state, use flutter-notifier-pattern.
---

# Legacy Flutter Controller Pattern

This skill documents existing controllers only. New Riverpod state follows
[flutter-notifier-pattern](../flutter-notifier-pattern/SKILL.md); do not introduce
new controller naming or migrate providers into controllers.

## Overview
Existing controllers coordinate application flows. They call use cases. Use cases own business logic.

In this repo, the reference pattern is:
- a state holder exposes query and intent APIs
- stream/message orchestration delegates tool lifecycle to that state holder
- widgets render state and call intent methods.

## When to Maintain an Existing Controller

- Keep state and orchestration in existing controllers.
- Keep permission/execution branching in existing controllers, not widgets.
- Keep reusable intent methods (`run`, `grant`, `skip`, `stop`) in existing controllers.

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

## Riverpod Migration

Use [flutter-notifier-pattern](../flutter-notifier-pattern/SKILL.md) for legacy Riverpod `*Controller` migrations.

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
