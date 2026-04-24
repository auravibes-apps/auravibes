# Riverpod 3 Core

Use this reference for provider design, Riverpod 3 behavior, migrations, and tests.

Official docs used when this reference was written:

- https://riverpod.dev/docs/introduction/getting_started
- https://riverpod.dev/docs/whats_new
- https://riverpod.dev/docs/3.0_migration
- https://riverpod.dev/docs/concepts/about_code_generation
- https://riverpod.dev/docs/concepts2/scoping
- https://riverpod.dev/docs/migration/from_state_notifier
- https://riverpod.dev/docs/migration/from_change_notifier

## Provider Selection

Use generated providers when the project already uses `riverpod_generator`.

| Need | Generated shape |
| --- | --- |
| Pure sync value, dependency injection, computed state | `@riverpod T name(Ref ref)` |
| One-shot async fetch with no public mutation methods | `@riverpod Future<T> name(Ref ref)` |
| Stream with no public mutation methods | `@riverpod Stream<T> name(Ref ref)` |
| Mutable sync state with public intents | `@riverpod class Name extends _$Name { T build(); ... }` |
| Mutable async state with public intents | `@riverpod class Name extends _$Name { Future<T> build() async; ... }` |
| Mutable stream state with public intents | generated class with `Stream<T> build()` |

Code generation is optional in Riverpod 3 generally, but if the package already uses generated providers, keep that style for consistency.

## Generated Provider Basics

```dart
import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'todos_notifier.g.dart';

@riverpod
class TodosNotifier extends _$TodosNotifier {
  @override
  FutureOr<List<Todo>> build(String listId) async {
    final repo = ref.watch(todoRepositoryProvider);
    return repo.fetchTodos(listId);
  }

  Future<void> addTodo(String title) async {
    final previous = await future;
    final repo = ref.read(todoRepositoryProvider);

    state = AsyncData([...previous, Todo.pending(title)]);
    await repo.createTodo(listId, title);

    if (!ref.mounted) return;
    ref.invalidateSelf();
  }
}
```

Generated family parameters become available by name inside the class (`listId` above). For non-codegen families this is usually `arg`.

## Riverpod 3 Behavior to Remember

- Failing providers retry automatically by default with exponential backoff until success or disposal. Disable/customize retry at `ProviderScope`, `ProviderContainer`, or provider annotation/constructor when errors are permanent.
- Generated providers are auto-dispose by default. Use `@Riverpod(keepAlive: true)` only when provider lifetime must outlive listeners.
- `StateProvider`, `StateNotifierProvider`, and `ChangeNotifierProvider` are legacy in Riverpod 3. Keep them only for migration/maintenance and import from `legacy.dart`.
- `AsyncValue` is sealed. Prefer exhaustive `switch` or `.when`.
- In Riverpod 3, the safe nullable data getter is `.value`; old `valueOrNull` usage should be migrated.
- Riverpod throws if `Ref`/`Notifier` is used after disposal. Check `ref.mounted` after awaits in methods that might outlive the provider.
- Exceptions while reading providers may be wrapped in `ProviderException`; inspect the original error when needed.
- Widget listeners can be paused when widgets are not visible; do not assume an offscreen widget listener remains active for app-level work.

## Async UI

```dart
return switch (ref.watch(todosProvider(listId))) {
  AsyncData(:final value) => TodoListView(todos: value),
  AsyncError(:final error) => ErrorView(error: error),
  AsyncLoading(:final progress) => LoadingView(progress: progress),
};
```

Use `.when` if that better matches existing code.

## Mutations

Riverpod 3 includes experimental `Mutation`. It is useful for UI-observable side effects such as create/update/delete operations. Because it is experimental, prefer existing project patterns.

```dart
final addMessageMutation = Mutation<MessageEntity>();

void submit(WidgetRef ref, String text) {
  addMessageMutation.run(ref, (tsx) async {
    final notifier = tsx.get(chatMessagesProvider.notifier);
    return notifier.addMessage(text);
  });
}
```

Use `tsx.get` inside mutation transactions rather than `ref.read`.

## Scoped Providers

Scoping requires explicit opt-in.

```dart
@Riverpod(dependencies: [])
String? selectedConversation(Ref ref) => null;

@Riverpod(dependencies: [selectedConversation])
Future<List<Message>> messages(Ref ref) async {
  final id = ref.watch(selectedConversationProvider);
  ...
}
```

Override scoped values with `ProviderScope(overrides: [...])`.

## Performance

- Use `select` when a widget needs one field from broad state.
- Split widgets so each consumer rebuilds at the smallest practical boundary.
- Avoid derived computations in widgets when a derived provider makes invalidation and tests clearer.
- Use immutable state updates. Do not mutate lists/maps in place and reassign the same reference.

## Testing

Use `ProviderContainer.test` for provider tests:

```dart
test('loads todos', () async {
  final container = ProviderContainer.test(
    overrides: [
      todoRepositoryProvider.overrideWithValue(fakeRepository),
    ],
  );

  expect(await container.read(todosProvider('inbox').future), hasLength(2));
});
```

Use `ProviderScope(overrides: [...])` in widget tests. Use Riverpod testing utilities already present in the project instead of creating global containers.
