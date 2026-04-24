---
name: flutter-riverpod-expert
description: Expert Riverpod 3 guidance for Flutter apps, especially projects using hooks_riverpod, flutter_hooks, riverpod_annotation, and riverpod_generator. Use when working with Riverpod providers, HookConsumerWidget/ConsumerWidget, WidgetRef/Ref, generated @riverpod providers, Notifier/AsyncNotifier/StreamNotifier, mutations, scoped providers, provider overrides, testing, caching, automatic retry, performance with select, or migrations from StateNotifier/ChangeNotifier/legacy providers.
---

# Flutter Riverpod Expert

Apply Riverpod 3 patterns that fit the current codebase. In AuraVibes, prefer the existing `hooks_riverpod` setup for Flutter widgets instead of adding or recommending `flutter_riverpod` directly.

## First Checks

1. Inspect the package's `pubspec.yaml` before suggesting imports or dependencies.
2. In this repo, use:
   - `package:hooks_riverpod/hooks_riverpod.dart` for Flutter widgets, `WidgetRef`, `ProviderScope`, `ProviderContainer`, hooks, `Mutation`, and consumer widgets.
   - `package:riverpod_annotation/riverpod_annotation.dart` for generated providers.
   - `package:riverpod_annotation/experimental/scope.dart` only when `@Dependencies` is required for scoped providers.
   - `package:hooks_riverpod/legacy.dart` only when maintaining existing `StateProvider`, `StateNotifierProvider`, or `ChangeNotifierProvider` code.
3. Do not manually edit `pubspec.yaml` for dependency changes in this repo. Use the project command convention with `fvm flutter pub add ...`.
4. Run generation from the package directory after changing generated providers:
   `fvm dart run build_runner build --delete-conflicting-outputs`

## Load References

- Read `references/auravibes-riverpod.md` before editing AuraVibes Riverpod code.
- Read `references/riverpod3-core.md` for provider selection, Riverpod 3 behavior changes, lifecycle, async state, and testing.
- Read `references/hooks-riverpod.md` when touching UI widgets, local widget state, hooks, `HookConsumerWidget`, or imports.

## Default Decisions

- Keep state ownership in generated Notifier classes when state has user intents or mutations.
- Use generated function providers for pure computed values, repositories, services, one-shot fetches, and streams without public mutation methods.
- Use hooks for local widget-only state such as controllers, focus nodes, animation controllers, debounce timers, and form-local state.
- Use Riverpod for app/domain state shared across widgets, persisted across routes, injected into use cases, or consumed by tests.
- Prefer `ref.watch` for reactive values, `ref.select` for narrow rebuilds, `ref.read` in event handlers and notifier methods, and `ref.listen` for side effects.
- Prefer `AsyncValue` pattern matching or `.when` for UI. Avoid ad hoc `isLoading`/`error` flags unless a domain state object needs them for a specific UX.
- After `await` inside notifier methods, check `ref.mounted` before touching `ref` or `state` if the notifier may have been disposed.
- Treat Riverpod 3 `Mutation` as experimental. Use it only where the project already has the pattern or the user asks for it.

## Avoid

- Do not recommend replacing `hooks_riverpod` with `flutter_riverpod` in this repo.
- Do not add `flutter_riverpod` just to access `ConsumerWidget`, `WidgetRef`, `ProviderScope`, or `ProviderContainer`; `hooks_riverpod` already provides the Flutter Riverpod API plus hooks support.
- Do not introduce legacy provider types for new state unless maintaining legacy code.
- Do not use `ref.read` inside `build` to avoid rebuilds. Use `ref.watch`, `ref.select`, or split widgets.
- Do not watch providers inside large list builders when a row widget can watch its own item.
- Do not keep mutable app state in widgets if multiple features or screens need it.
- Do not make every provider `keepAlive: true`; default generated providers are auto-dispose and that is usually correct.
- Do not use scoped providers without declaring `dependencies` on scoped providers and generated dependents.

## Common AuraVibes Pattern

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_send_queue_notifier.g.dart';

@riverpod
class ConversationSendQueueNotifier extends _$ConversationSendQueueNotifier {
  @override
  List<String> build() => const [];

  void enqueue(String messageId) {
    state = [...state, messageId];
  }
}
```

```dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ChatInputWidget extends HookConsumerWidget {
  const ChatInputWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSending = ref.watch(sendMessageProvider.select((state) => state.isSending));

    return IconButton(
      onPressed: isSending
          ? null
          : () => ref.read(sendMessageProvider.notifier).send(),
      icon: const Icon(Icons.send),
    );
  }
}
```

## Validation

- Run targeted tests from the package directory with `fvm flutter test <files> --no-pub`.
- Run generation before analysis when provider signatures, annotations, file names, or provider names change.
- Run `fvm dart run melos analyze` or the repo's focused validation command when the change affects shared providers.
