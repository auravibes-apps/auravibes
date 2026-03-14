# Quickstart: Two-Step Model Selector

**Date**: 2026-03-11
**Feature**: 001-two-step-model-selector

## Prerequisites

- Flutter SDK via FVM (3.41.4+)
- Melos installed and bootstrapped
- Existing credentials and models configured in app

## Implementation Order

Follow tasks in this order for optimal dependency flow:

```
Task 1: Add providerId state
    │
    ▼
Task 2: Create grouped models provider
    │
    ▼
Task 3: Refactor SelectCredentialsModelWidget
    │
    ▼
Task 4: Wire up NewChatScreen
    │
    ▼
Task 5: Add locale keys
    │
    ▼
Task 6: Write tests
    │
    ▼
Task 7: Validate
```

## Step-by-Step Guide

### Step 1: Add Provider State

**File**: `apps/auravibes_app/lib/features/chats/providers/new_chat_controller.dart`

1. Add `providerId` field to `NewChatState`:
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

2. Add `setProvider` method to `NewChatController`:
```dart
void setProvider(String? providerId) {
  state = state.copyWith(
    providerId: providerId,
    modelId: null, // Reset model when provider changes
  );
}
```

3. Run code generation:
```bash
cd apps/auravibes_app && fvm dart run build_runner build --delete-conflicting-outputs
```

### Step 2: Create Grouped Models Provider

**File**: `apps/auravibes_app/lib/features/models/providers/list_chat_models_providers.dart`

1. Add new provider at end of file:
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

2. Run code generation:
```bash
cd apps/auravibes_app && fvm dart run build_runner build --delete-conflicting-outputs
```

### Step 3: Refactor Widget

**File**: `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`

Replace entire file with two-dropdown implementation:

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
    final groupedModels = ref.watch(listModelsGroupedByProviderProvider);
    final providers = groupedModels.keys.toList()..sort();

    return groupedModels.isEmpty
        ? _buildLoadingOrError(context, ref)
        : _buildSelectors(context, ref, providers, groupedModels);
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

### Step 4: Wire Up NewChatScreen

**File**: `apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart`

Update `SelectCredentialsModelWidget` usage (around line 55):

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

### Step 5: Add Locale Keys

**File**: `apps/auravibes_app/lib/i18n/locale_keys.dart`

Add constants:
```dart
static const models_screens_select_provider = 'models_screens.select_provider';
static const models_screens_select_model = 'models_screens.select_model';
static const models_screens_select_provider_first = 'models_screens.select_provider_first';
```

**File**: `apps/auravibes_app/lib/i18n/en.yaml`

Add translations:
```yaml
models_screens:
  select_provider: "Select provider"
  select_model: "Select model"
  select_provider_first: "Select provider first"
```

### Step 6: Write Tests

**File**: `apps/auravibes_app/test/features/models/widgets/select_chat_model_test.dart`

```dart
import 'package:auravibes_app/features/models/widgets/select_chat_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  group('SelectCredentialsModelWidget', () {
    testWidgets('shows provider dropdown on load', (tester) async {
      // TODO: Implement widget test
    });

    testWidgets('disables model dropdown when no provider selected', (tester) async {
      // TODO: Implement widget test
    });

    testWidgets('enables model dropdown when provider selected', (tester) async {
      // TODO: Implement widget test
    });

    testWidgets('resets model when provider changes', (tester) async {
      // TODO: Implement widget test
    });
  });
}
```

### Step 7: Validate

Run validation commands:
```bash
# From monorepo root
fvm dart run melos analyze
fvm dart run melos run test
fvm dart run melos run validate:quick
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Build runner conflicts | Run with `--delete-conflicting-outputs` |
| Missing locale keys | Ensure `locale_keys.dart` and `en.yaml` are synced |
| Dropdown not rendering | Check `listModelsGroupedByProviderProvider` returns non-empty map |
| State not updating | Verify `onProviderChanged` and `selectCredentialsModelId` callbacks are wired |

## Testing Checklist

- [ ] Provider dropdown shows all configured providers
- [ ] Model dropdown disabled when no provider selected
- [ ] Model dropdown shows only selected provider's models
- [ ] Changing provider resets model selection
- [ ] Chat input disabled until both selected
- [ ] Loading state shows spinner
- [ ] Error state shows error message
- [ ] Single provider auto-selects
