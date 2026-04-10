# Notifier Pattern

Riverpod class-based providers that own mutable state must use the notifier pattern.

## Purpose

Notifiers are the runtime state owners for a feature.

They should:
- load their initial value in `build()`
- expose methods that update `state`
- coordinate UI/runtime flow around that state

They should not:
- become generic business-logic containers
- duplicate reusable domain orchestration that belongs in a use case
- replace plain read-only providers

## Location and Naming

- Feature notifiers live in `apps/<app_name>/lib/features/<feature_name>/notifiers/`
- Shared app-level notifiers live in `apps/<app_name>/lib/notifiers/`
- Class names use the `*Notifier` suffix
- File names use the `<name>_notifier.dart` suffix

Legacy `*Controller` naming for Riverpod class-based providers should be migrated to `*Notifier`.

## What Belongs in a Notifier

Good notifier responsibilities:
- loading feature state in `build()`
- toggling or updating local runtime state
- keeping async loading/error flags in sync with the UI
- invalidating or refreshing related providers after a state change
- wrapping a use case call with notifier state transitions

See also:
- [Use Cases Pattern](./usecases-pattern.md)
- [Notifier Pattern Skill](../../.agents/skills/flutter-notifier-pattern/SKILL.md) for agent guidance and heuristics

Examples:
- selected model + loading state for a new-chat flow
- current MCP connection state and reconnect/disconnect runtime tracking
- conversation-level tool enablement state for the current screen

## What Belongs in a Use Case

Move logic to a use case when it includes:
- business rules or validation
- orchestration across multiple repositories or services
- reusable domain actions called from multiple notifiers/screens
- sequencing whose value is independent of a specific notifier state

Examples:
- approving or skipping a tool call
- starting a new chat with the required domain side effects
- computing grouped tool views from multiple domain inputs

## What Belongs in a Plain Provider

Keep plain providers for:
- repositories
- services
- computed read-only values
- lightweight dependency composition for the UI

Do not move these into `notifiers/` unless they become state owners.

## Decision Rule

Use this rule before adding a public method to a notifier:

- If the method exists to maintain or expose notifier state, keep it in the notifier.
- If the method exists to execute business logic, implement it as a use case and call it from the notifier or UI.

## Build Method Rule

`build()` should load the state needed by the notifier.

It may:
- read repositories or providers needed to construct initial state
- subscribe to reactive dependencies through `ref.watch`
- trigger local runtime setup tied to the notifier lifecycle

It should avoid:
- embedding reusable business orchestration
- performing unrelated side effects that do not support the notifier state lifecycle

## Runtime Adapter Pattern

When a use case needs to trigger notifier behavior (enqueue a message, start/stop a stream, check streaming state), it must not depend on the notifier class directly. Instead, use a **runtime adapter** — a plain class that captures notifier method references behind callback interfaces.

### Structure

1. Define a plain class with `Function` fields for each needed operation:

```dart
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
```

2. Wire it with a plain `Provider` that captures the notifier's methods:

```dart
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

3. Inject the runtime into the use case via constructor:

```dart
class ContinueAgentUsecase {
  const ContinueAgentUsecase({
    required this.conversationStreamingRuntime,
    // ... other deps
  });

  final ConversationStreamingRuntime conversationStreamingRuntime;

  Future<void> call({required String conversationId}) async {
    conversationStreamingRuntime.start(conversationId);
    // ...
  }
}
```

### Location

Runtime adapter files live in `providers/` alongside other plain providers:

- `apps/<app_name>/lib/features/<feature_name>/providers/<name>_runtime_provider.dart`

### When to Use

- A use case needs to call a notifier method (start/stop streaming, enqueue, check busy state)
- A use case needs to read runtime state that only lives in a notifier

### When Not to Use

- The use case only needs repository/service access — inject those directly
- The operation is purely stateless — use a plain function or service

### Safety Note

Method references are captured once per provider rebuild. The adapter stays valid as long as the underlying notifier instance is not disposed and recreated between uses. For `@Riverpod(keepAlive: true)` notifiers this is guaranteed. For auto-dispose notifiers (`@riverpod`), the provider may be disposed when all listeners are removed and recreated on next access — the adapter's `ref.watch` subscription keeps the notifier alive while the adapter itself is watched, but if the adapter is allowed to dispose and later re-resolved, it will correctly pick up a fresh notifier instance. If a notifier adds mutable local fields beyond `ref`/`state`, review whether captured method references remain valid across the notifier's lifecycle.

## Migration Rule

When migrating legacy Riverpod classes:

1. Rename `*Controller` to `*Notifier`.
2. Move the file into a `notifiers/` folder.
3. Keep plain providers in `providers/`.
4. Review each public method:
   - state maintenance stays in the notifier
   - business actions move to use cases
5. Update provider references, generated files, and imports.

## Practical Example

Good notifier method:

```dart
Future<void> setTheme(AppTheme theme) async {
  state = AsyncData(theme);
  final prefs = await ref.read(sharedPreferencesProvider.future);
  await prefs.setInt(_themeKey, theme.index);
}
```

This stays in the notifier because it directly maintains notifier state.

Good use case call from a notifier:

```dart
Future<ConversationEntity> startConversation(String message) async {
  state = state.copyWith(isLoading: true);
  try {
    return ref.read(sendNewMessageUsecaseProvider).call(
      firstMessage: message,
      credentialsModelId: state.modelId!,
      workspaceId: await _workspaceId(),
    );
  } finally {
    state = state.copyWith(isLoading: false);
  }
}
```

The notifier manages loading state; the business action stays in the use case.
