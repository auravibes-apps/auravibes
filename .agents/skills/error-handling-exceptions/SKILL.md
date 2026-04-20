---
name: error-handling-exceptions
description: Use when defining exceptions or catch blocks in app/domain/data layers and you need to keep only meaningful domain exceptions while avoiding wrapper-noise rethrows.
---

# Error Handling and Exceptions

## Goal

Keep failures explicit and useful.

Throw domain exceptions only when callers can make a real business decision.
Do not catch unknown errors just to wrap them in another generic exception.

## Rules

1. Throw managed domain exceptions only for expected business flow.
   - Good: not found, validation rejected, permission denied, duplicate key.
   - Bad: wrapping any unexpected `Exception` into `SomethingException`.

2. Let unexpected infrastructure errors bubble.
   - DB, HTTP, parsing, platform, and programming failures should pass through
     unless a clear domain mapping is required.

3. Avoid catch-and-rethrow wrappers.
   - Remove patterns like `catch (e) => throw GenericException('failed', e)`
     when they add no decision value.

4. Use local control flow instead of local throw/catch pairs.
   - If a private helper throws only to be caught in same use case,
     return nullable/result status directly.

5. Keep validation exceptions precise.
   - Keep structured domain exceptions where callers branch behavior.
   - Include actionable message when validation fails.

6. Preserve observability without wrapping.
   - If needed, log and rethrow original error.
   - Do not replace original type unless mapped to a meaningful domain case.

## Layer Guidance

- Domain layer
  - Define exception types only for business semantics.
  - Exception classes should be stable, small, and meaningful.

- Data layer (repositories/services)
  - Do not translate every storage/network error into repository-specific
    generic exceptions.
  - Keep only domain-mapped errors (for example: not-found after existence
    check, validation failure before write).

- Application/use case layer
  - Use guard clauses for expected invalid input.
  - For tool execution or state mapping, prefer explicit status values over
    internal throw/catch control flow.

## Patterns

### Keep

```dart
if (!entity.isValid) {
  throw ValidationException('Name cannot be empty');
}

final item = await repository.getById(id);
if (item == null) {
  throw NotFoundException(id);
}
```

### Remove

```dart
try {
  return await dao.getAll();
} catch (e) {
  throw RepositoryException('Failed to load items', e as Exception);
}
```

### Better

```dart
return dao.getAll();
```

## Cleanup Checklist

- Find `catch (...)` blocks that only wrap and rethrow.
- Remove wrapper exceptions that are never used for branching.
- Keep or add only business-domain exceptions.
- Replace local exception control flow with explicit statuses/results.
- Run analyzer and tests after refactor.

## Prompt Examples

- "Apply error-handling-exceptions skill to this repository implementation."
- "Remove exception wrapper noise and keep only business exceptions."
- "Refactor this use case to avoid local throw/catch control-flow exceptions."
