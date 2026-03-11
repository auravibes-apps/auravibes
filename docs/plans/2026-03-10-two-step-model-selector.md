# Two-Step Model Selector Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace single model dropdown with provider-first, then model selection UX.

**Architecture:** Two cascading dropdowns in app bar — provider selection filters available models. Provider ID added to controller state, grouped models provider for efficient filtering.

**Tech Stack:** Flutter, Riverpod, Freezed, existing AuraDropdownSelector widget

---

## Task 1: Add Provider State to NewChatController

**Files:**
- Modify: `apps/auravibes_app/lib/features/chats/providers/new_chat_controller.dart`

**Step 1: Add providerId to NewChatState**

Add `providerId` field to the state class:

```dart
@freezed
abstract class NewChatState with _$NewChatState {
  const factory NewChatState({
    String? modelId,
    String? providerId,  // ADD THIS
    @Default(false) bool isLoading,
  }) = _NewChatState;
}
```

**Step 2: Add setProvider method**

Add new method to NewChatController class (after `setModelId` method):

```dart
void setProvider(String? providerId) {
  state = state.copyWith(
    providerId: providerId,
    modelId: null, // Reset model when provider changes
  );
}
```

**Step 3: Run code generation**

```bash
cd apps/auravibes_app && fvm dart run build_runner build --delete-conflicting-outputs
```

**Step 4: Commit**

```bash
git add apps/auravibes_app/lib/features/chats/providers/new_chat_controller.dart apps/auravibes_app/lib/features/chats/providers/new_chat_controller.freezed.dart apps/auravibes_app/lib/features/chats/providers/new_chat_controller.g.dart
git commit -m "feat(chats): add providerId state to NewChatController"
```

---

## Task 2: Create Grouped Models Provider

**Files:**
- Modify: `apps/auravibes_app/lib/features/models/providers/list_chat_models_providers.dart`

**Step 1: Add grouped models provider**

Add new provider at the end of the file:

```dart
@riverpod
Map<String, List<CredentialsModelWithProviderEntity>> listModelsGroupedByProvider(
  Ref ref,
) {
  final modelsAsync = ref.watch(listCredentialsCredentialsProvider);

  return modelsAsync.when(
    data: (models) {
      final grouped = <String, List<CredentialsModelWithProviderEntity>>{};
      for (final model in models) {
        final providerName = model.modelsProvider.name;
        grouped.putIfAbsent(providerName, () => []).add(model);
      }
      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
}
```

**Step 2: Run code generation**

```bash
cd apps/auravibes_app && fvm dart run build_runner build --delete-conflicting-outputs
```

**Step 3: Commit**

```bash
git add apps/auravibes_app/lib/features/models/providers/list_chat_models_providers.dart apps/auravibes_app/lib/features/models/providers/list_chat_models_providers.g.dart
git commit -m "feat(models): add provider that groups models by provider"
```

---

## Task 3: Refactor SelectCredentialsModelWidget

**Files:**
- Modify: `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`

**Step 1: Replace entire widget implementation**

Replace the entire file content with:

```dart
import 'package:auravibes_app/domain/entities/credentials_models_entities.dart';
import 'package:auravibes_app/features/chats/providers/new_chat_controller.dart';
import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/app_error.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SelectCredentialsModelWidget extends HookConsumerWidget
    implements PreferredSizeWidget {
  const SelectCredentialsModelWidget({
    required this.selectCredentialsModelId,
    super.key,
    this.credentialsModelId,
    this.providerId,
    this.onProviderChanged,
  });

  final String? credentialsModelId;
  final String? providerId;
  final void Function(String?) selectCredentialsModelId;
  final void Function(String?)? onProviderChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedModelsAsync = ref.watch(listModelsGroupedByProviderProvider);
    final providers = groupedModelsAsync.keys.toList()..sort();

    return groupedModelsAsync.isEmpty
        ? _buildLoadingOrError(context, ref)
        : _buildSelectors(context, ref, providers, groupedModelsAsync);
  }

  Widget _buildLoadingOrError(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(listCredentialsCredentialsProvider);
    return switch (modelsAsync) {
      AsyncLoading() => const Padding(
          padding: EdgeInsetsGeometry.all(AuraSpacing.md),
          child: AuraSpinner(),
        ),
      AsyncError(:final error, :final stackTrace) => Padding(
          padding: const EdgeInsetsGeometry.all(AuraSpacing.sm),
          child: AppErrorWidget(error: error, stackTrace: stackTrace),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildSelectors(
    BuildContext context,
    WidgetRef ref,
    List<String> providers,
    Map<String, List<CredentialsModelWithProviderEntity>> groupedModels,
  ) {
    final availableModels = providerId != null
        ? groupedModels[providerId] ?? []
        : <CredentialsModelWithProviderEntity>[];

    return AuraPadding(
      padding: const AuraPaddingValue.only(bottom: AuraSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: _ProviderDropdown(
              providers: providers,
              selectedProvider: providerId,
              onChanged: onProviderChanged,
            ),
          ),
          SizedBox(width: context.auraTheme.spacing.sm),
          Expanded(
            child: _ModelDropdown(
              models: availableModels,
              selectedModel: credentialsModelId,
              enabled: providerId != null,
              onChanged: selectCredentialsModelId,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _ProviderDropdown extends HookConsumerWidget {
  const _ProviderDropdown({
    required this.providers,
    required this.selectedProvider,
    required this.onChanged,
  });

  final List<String> providers;
  final String? selectedProvider;
  final void Function(String?)? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraDropdownSelector<String>(
      value: selectedProvider,
      onChanged: onChanged,
      placeholder: const TextLocale(LocaleKeys.models_screens_select_provider),
      options: providers
          .map(
            (provider) => AuraDropdownOption(
              value: provider,
              child: Text(provider),
            ),
          )
          .toList(),
    );
  }
}

class _ModelDropdown extends HookConsumerWidget {
  const _ModelDropdown({
    required this.models,
    required this.selectedModel,
    required this.enabled,
    required this.onChanged,
  });

  final List<CredentialsModelWithProviderEntity> models;
  final String? selectedModel;
  final bool enabled;
  final void Function(String?)? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraDropdownSelector<String>(
      value: selectedModel,
      onChanged: enabled ? onChanged : null,
      placeholder: TextLocale(
        enabled
            ? LocaleKeys.models_screens_select_model
            : LocaleKeys.models_screens_select_provider_first,
      ),
      options: models
          .map(
            (model) => AuraDropdownOption(
              value: model.credentialsModel.id,
              child: Text(model.credentialsModel.modelId),
            ),
          )
          .toList(),
    );
  }
}
```

**Step 2: Add new locale keys**

Add to `apps/auravibes_app/lib/i18n/locale_keys.dart`:

```dart
static const models_screens_select_provider = 'models_screens.select_provider';
static const models_screens_select_model = 'models_screens.select_model';
static const models_screens_select_provider_first = 'models_screens.select_provider_first';
```

**Step 3: Add translations**

Add to `apps/auravibes_app/lib/i18n/en.yaml` (create if needed, or find existing):

```yaml
models_screens:
  select_provider: "Select provider"
  select_model: "Select model"
  select_provider_first: "Select provider first"
```

**Step 4: Run analyze to check for errors**

```bash
cd apps/auravibes_app && fvm flutter analyze lib/features/models/widgets/select_chat_model.dart
```

**Step 5: Commit**

```bash
git add apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart apps/auravibes_app/lib/i18n/locale_keys.dart apps/auravibes_app/lib/i18n/en.yaml
git commit -m "feat(models): refactor to two-step provider/model selector"
```

---

## Task 4: Update NewChatScreen to Wire Up Provider Selection

**Files:**
- Modify: `apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart`

**Step 1: Update SelectCredentialsModelWidget usage**

Replace the `SelectCredentialsModelWidget` in the appBar bottom (around line 55-60):

```dart
bottom: SelectCredentialsModelWidget(
  credentialsModelId: state.modelId,
  providerId: state.providerId,
  selectCredentialsModelId: (value) {
    ref.read(newChatControllerProvider.notifier).setModelId(value);
  },
  onProviderChanged: (value) {
    ref.read(newChatControllerProvider.notifier).setProvider(value);
  },
),
```

**Step 2: Run analyze**

```bash
cd apps/auravibes_app && fvm flutter analyze lib/features/chats/screens/new_chat_screen.dart
```

**Step 3: Commit**

```bash
git add apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart
git commit -m "feat(chats): wire up provider selection in new chat screen"
```

---

## Task 5: Run Full Validation

**Step 1: Run melos analyze**

```bash
fvm dart run melos analyze
```

**Step 2: Run tests (if any exist for these files)**

```bash
fvm dart run melos run test
```

**Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: resolve any analysis issues"
```

---

## Summary

| Task | Files Modified |
|------|---------------|
| 1 | `new_chat_controller.dart` + generated |
| 2 | `list_chat_models_providers.dart` + generated |
| 3 | `select_chat_model.dart`, `locale_keys.dart`, `en.yaml` |
| 4 | `new_chat_screen.dart` |
| 5 | Validation |

**Total: 5 tasks, ~30 minutes estimated**
