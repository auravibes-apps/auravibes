# Hooks Riverpod

Use this reference when editing Flutter UI that combines Riverpod and hooks.

Official package/docs references used when this reference was written:

- https://riverpod.dev/docs/introduction/getting_started
- https://pub.dev/packages/hooks_riverpod

## Package Choice

`hooks_riverpod` is the right import when the app uses both Riverpod and Flutter hooks. It provides the Flutter Riverpod consumer APIs and hook-aware consumer widgets. Do not add `flutter_riverpod` separately just to get `ConsumerWidget`, `WidgetRef`, `ProviderScope`, or `ProviderContainer`.

## Widget Selection

- Prefer `ConsumerWidget` when the widget only needs Riverpod.
- Choose `HookConsumerWidget` if the widget needs hooks and Riverpod in the same `build`.
- Employ `Consumer` for a small subtree when only part of a larger widget should rebuild.
- Reserve hooks for widget-local lifecycle objects and ephemeral UI state.

```dart
class SearchBox extends HookConsumerWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final isBusy = ref.watch(searchProvider.select((state) => state.isBusy));

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onSubmitted: isBusy
          ? null
          : (query) => ref.read(searchProvider.notifier).search(query),
    );
  }
}
```

## Local vs Shared State

Use hooks for:

- `TextEditingController`, `FocusNode`, `AnimationController`, `ScrollController`
- selected tab in a single widget
- debounce handles scoped to one widget
- UI-only expanded/collapsed flags that no other widget needs

Use Riverpod for:

- state shared between widgets/screens
- async data, caching, repository access, use-case orchestration
- domain/application state
- values that tests need to override or inspect

## Listening and Side Effects

Use `ref.listen` for UI side effects such as snackbars, dialogs, routing, focus changes, or analytics. Do not trigger those directly from `ref.watch`.

```dart
ref.listen<AsyncValue<void>>(saveProvider, (previous, next) {
  if (next case AsyncError(:final error)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
});
```

## Rebuild Control

Prefer narrow watches:

```dart
final isSending = ref.watch(chatInputProvider.select((state) => state.isSending));
```

Split row widgets so each row watches its own provider/family parameter. Avoid watching many provider instances inline in a large builder when the row can be a `ConsumerWidget`.
