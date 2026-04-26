# AuraVibes Riverpod Rules

Use this reference before editing Riverpod code in AuraVibes.

## Current Package Shape

`apps/auravibes_app/pubspec.yaml` currently uses:

- `hooks_riverpod: ^3.0.3`
- `riverpod: ^3.0.3`
- `riverpod_annotation: ^4.0.0`
- `riverpod_generator: ^4.0.0+1`
- `flutter_hooks: ^0.21.3+1`

Implication: use `hooks_riverpod`, not `flutter_riverpod`, in Flutter widgets. `hooks_riverpod` depends on and exposes the Flutter Riverpod APIs while also supporting `HookConsumerWidget`.

## Imports

Use widget imports like:

```dart
import 'package:hooks_riverpod/hooks_riverpod.dart';
```

Use generated provider imports like:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'my_provider.g.dart';
```

Use scoped-provider annotation imports only when the file has `@Dependencies`:

```dart
import 'package:riverpod_annotation/experimental/scope.dart';
```

Use experimental mutation imports only when the file declares or uses `Mutation`:

```dart
import 'package:riverpod/experimental/mutation.dart';
```

Use legacy imports only for existing legacy providers:

```dart
import 'package:hooks_riverpod/legacy.dart';
```

## Naming and Folders

- Mutable state owners should usually be `*Notifier` under `notifiers/`.
- Pure repository/service providers belong under `providers/`.
- Generated provider names come from class/function names. For `ThemeNotifier`, generator emits `themeProvider`, not `themeNotifierProvider`.
- Keep feature-local providers inside the feature unless the provider is genuinely app-wide.

## Scoped Providers

AuraVibes uses scoped providers for selected conversation/workspace context. Default scoped providers should be non-nullable and fail fast until overridden via `ProviderScope`.

For a scoped generated provider:

```dart
@Riverpod(dependencies: [])
String conversationSelected(Ref ref) =>
    throw const NoConversationSelectedException();
```

Any generated provider that watches it must list it:

```dart
@Riverpod(dependencies: [conversationSelected])
Future<List<MessageEntity>> chatMessages(Ref ref) async {
  final conversationId = ref.watch(conversationSelectedProvider);
  ...
}
```

Widgets that directly or indirectly depend on scoped providers may need `@Dependencies([...])` from `riverpod_annotation/experimental/scope.dart`.

## Commands

Run Dart/Flutter commands through FVM:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter test test/path/to/file_test.dart --no-pub
fvm dart run melos analyze
```

Do not hand-edit dependencies. Use:

```bash
fvm flutter pub add package_name
fvm flutter pub add dev:package_name
```

## Review Checklist

- Widget files import `hooks_riverpod`, not `flutter_riverpod`.
- Provider definition files import `riverpod_annotation` and have the correct `part`.
- Generated files are updated after provider API changes.
- Scoped providers declare `dependencies` consistently.
- `keepAlive: true` is justified by app lifetime, service lifetime, or expensive setup.
- Long async notifier methods avoid touching disposed refs after `await`.
- UI rebuilds are narrowed with `select` or widget splitting where state is broad.
