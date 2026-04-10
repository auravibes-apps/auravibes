---
name: flutter-notifier-pattern
description: Use when migrating Riverpod class-based providers from legacy controller naming to notifier naming and enforcing notifier vs usecase boundaries.
---

# Flutter Notifier Pattern

## Overview

In this repo, Riverpod class-based providers that own mutable app/runtime state should be named `*Notifier`, live under a `notifiers/` folder, and expose state-focused intent methods.

This pattern replaces legacy `*Controller` naming for Riverpod classes with `build()` methods.

## Use a Notifier When

- the Riverpod class owns mutable UI/runtime state
- `build()` loads initial state for a feature or flow
- public methods primarily update `state`
- the widget tree needs one place to read state and dispatch intents

## Do Not Use a Notifier For

- pure derived/read-only values
- repository factories or dependency wiring
- reusable domain/business orchestration
- one-off UI actions that do not maintain shared state

## Notifier Responsibilities

- load initial state in `build()`
- expose explicit state transition methods
- keep runtime bookkeeping close to the state it updates
- call use cases for business actions
- use guard clauses and `try/finally` around async state transitions

## Usecase Boundary

Move logic out of a notifier when it includes:

- business validation or domain rules
- orchestration across multiple repositories/services
- reusable domain actions shared by screens/features
- sequencing that is meaningful outside the notifier's state lifecycle

If a method only updates notifier state around an already-defined domain action, it can stay in the notifier.

## Provider Boundary

Keep plain providers for:

- repositories and services
- lightweight computed values
- read-only UI dependencies

Do not rename every provider to a notifier. Only Riverpod classes that own state should become notifiers.

## File Layout

- Notifiers: `apps/<app_name>/lib/features/<feature_name>/notifiers/<name>_notifier.dart`
- Shared/root notifiers: `apps/<app_name>/lib/notifiers/<name>_notifier.dart`
- Use cases: `apps/<app_name>/lib/features/<feature_name>/usecases/<name>_usecase.dart`
- Read-only providers stay in `providers/`

## Migration Checklist

1. Rename the class from `*Controller` to `*Notifier`.
2. Move the file into a `notifiers/` folder.
3. Rename generated provider usages from `*ControllerProvider` to `*NotifierProvider`.
4. Keep `build()` focused on loading initial state.
5. Extract business-heavy methods into use cases.
6. Update imports and generated files.
7. Run code generation, format, and analysis.

## Quick Heuristic

- If the method's job is "change this notifier's state", keep it here.
- If the method's job is "execute a business action", move it to a use case and call it from the notifier or UI.

## Runtime Adapter Pattern

Use cases must not import or depend on notifier classes. When a use case needs to trigger notifier behavior (start/stop streaming, enqueue, check state), use a **runtime adapter** — a plain class with `Function` fields that wraps notifier method references.

### Structure

1. Define a plain class with callback fields for each needed operation.
2. Wire it with a plain `Provider` that captures `ref.watch(...Provider.notifier)` methods.
3. Inject the runtime into the use case via constructor.

### Location

Runtime adapter files live in `providers/`:

- `apps/<app_name>/lib/features/<feature_name>/providers/<name>_runtime_provider.dart`

### Example

```dart
// providers/streaming_runtime_provider.dart
class ConversationStreamingRuntime {
  const ConversationStreamingRuntime({
    required this.start,
    required this.isStreaming,
    required this.remove,
  });

  final void Function(String conversationId) start;
  final bool Function(String conversationId) isStreaming;
  final void Function(String conversationId) remove;
}

final conversationStreamingRuntimeProvider =
    Provider<ConversationStreamingRuntime>((ref) {
  final notifier = ref.watch(conversationStreamingProvider.notifier);
  return ConversationStreamingRuntime(
    start: notifier.start,
    isStreaming: notifier.isStreaming,
    remove: notifier.remove,
  );
});
```

### Safety

Method references are captured once per provider rebuild. Safe because code-generated notifiers are singleton-like. If a notifier adds mutable local fields beyond `ref`/`state`, captured references may go stale.

### When to Use

- A use case needs to call a notifier method or read runtime state from a notifier.
- The dependency boundary between use case and notifier must stay clean.

### When Not to Use

- The use case only needs repository/service access — inject those directly.
- The operation is purely stateless — use a plain function or service.

## Common Mistakes

- renaming a controller to a notifier without moving business logic out
- moving plain repository providers into `notifiers/`
- letting widgets reimplement business branching instead of calling a use case
- storing domain service wiring inside widgets
- importing a notifier class directly from a use case instead of using a runtime adapter
- creating re-export shim files to avoid importing notifier files — import the notifier file directly
