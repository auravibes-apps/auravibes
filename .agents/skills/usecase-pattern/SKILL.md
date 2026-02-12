---
name: usecase-pattern
description: Use when creating or refactoring domain use cases in app modules and you need consistent constructor injection, guard clauses, immutable updates, and orchestration without state management.
---

# Use Case Pattern

## Overview

Use cases are plain domain classes that orchestrate business flow.

Core rule: providers/widgets manage state, use cases coordinate logic, repositories perform data access.

## When to Use

Use this pattern when:
- moving business logic out of providers/controllers
- coordinating multiple repositories or services
- returning domain values after orchestration
- updating metadata/entities through immutable copy patterns
- refactoring large methods into testable orchestration units

Do not use this for simple UI-only state changes.

## Core Structure

```dart
class ActionUseCase {
  const ActionUseCase({
    required FeatureRepository repository,
    required SecondaryDependency secondary,
  })  : _repository = repository,
        _secondary = secondary;

  final FeatureRepository _repository;
  final SecondaryDependency _secondary;

  Future<ActionOutput> call({required ActionInput input}) async {
    if (input.items.isEmpty) {
      throw const ManagedDomainException('Input items are required');
    }

    final prepared = _prepare(input);
    final entity = await _repository.execute(prepared);
    return ActionOutput.fromEntity(entity);
  }
}
```

Use local DTOs only when needed by the flow (for example batch update structures or
metadata updates). Otherwise return the domain value directly.

Rules:
- use a simple class (no provider inheritance/annotations for the use case itself)
- inject dependencies through constructor
- expose one clear entry point, usually `call(...)`
- prefer guard clauses and early returns
- return domain results; do not mutate UI state directly

## Orchestration Pattern

1. Validate inputs with guard clauses.
2. Resolve dependencies/IDs needed for execution.
3. Execute delegated operations (repository or other use case).
4. Return the domain value for the next layer.
5. Persist updates through delegated dependencies.

Keep use cases focused on orchestration, not storage details.

## Immutable Update Pattern

When a use case updates nested metadata/collections:
- map by stable identifiers (for example `toolCallId`)
- copy only affected items
- preserve untouched items as-is
- persist once after building the final result

This keeps behavior deterministic and testable.

## Error Handling Pattern

Use cases should not wrap errors into generic result objects.

Rules:
- return values directly on success
- throw only managed domain exceptions when the error is part of the business flow
- do not catch and re-wrap unknown exceptions into another generic error
- let infrastructure/unexpected exceptions bubble to the caller unless there is a clear domain mapping requirement

## Quick Checklist

- use case class has constructor-injected dependencies
- `call(...)` method is the single entry point
- guard clauses exist for missing/invalid input
- no provider/UI state mutation in use case
- side effects are delegated to repositories/other use cases
- returns a domain value directly whenever possible

## Common Mistakes

1. Putting business logic in providers/controllers instead of a use case.
2. Using `ref.read(...)` inside the use case instead of constructor injection.
3. Catching broad exceptions and embedding them into generic failure objects.
4. Performing many small persistence writes instead of one aggregated update.
5. Mixing orchestration with formatting/presentation concerns.

## Using Use Cases in the App Layer

Use case usage pattern in app modules:
- instantiate use cases in an application controller/service, not in widgets
- read repositories from provider/container, then compose use cases explicitly
- call small use cases in sequence to form one user flow
- keep provider/controller state focused on UI/runtime tracking only

Reference implementation:
- composition root and flow orchestration: `apps/auravibes_app/lib/providers/tool_execution_controller.dart`
- provider delegation entrypoints: `apps/auravibes_app/lib/providers/tool_calling_manager_provider.dart`

### Composition Root Pattern

Inside a controller method:
1. Read dependencies from providers/repository providers.
2. Build foundational use cases first (for example metadata update/checks).
3. Inject them into higher-level orchestrator use cases.
4. Execute the flow through use case `call(...)` methods.

This keeps wiring explicit, testable, and easy to refactor.

### Runtime Usage Flows

- `runTask(...)`: create permission/check/update use cases -> filter allowed work -> execute batch -> continue next step only when pending work is resolved.
- `grantToolCall(...)`: build grant + execution use cases -> grant permission -> execute -> continue flow.
- `skipToolCall(...)` / stop flows: update metadata through dedicated update use case, then continue orchestration as needed.

### App-Layer Do / Don't

Do:
- compose use cases per method/flow in the app layer
- pass IDs and domain inputs into use case `call(...)`
- let use cases coordinate business operations

Don't:
- instantiate repository clients directly inside widgets
- mix UI rendering logic into use cases
- bypass use cases by duplicating orchestration across providers/controllers

## How to Use It

Prompt examples:
- "Create a new domain use case using the usecase-pattern skill."
- "Refactor this provider logic into a constructor-injected use case with guard clauses."
- "Apply immutable update and managed domain exception rules in this use case."

During implementation, follow this order:
1. Define input/output contracts and any managed domain exceptions.
2. Write the use case class and constructor dependencies.
3. Add guard clauses and orchestration flow.
4. Delegate persistence/external calls.
5. Add unit tests for success paths and managed error paths.
