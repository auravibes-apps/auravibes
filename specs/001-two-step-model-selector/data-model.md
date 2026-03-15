# Data Model: Two-Step Model Selector

**Date**: 2026-03-11
**Feature**: 001-two-step-model-selector

## Overview

This feature requires no new database entities. It extends existing state management and creates a derived data provider for grouping.

## Entity Changes

### Modified: NewChatState

**File**: `apps/auravibes_app/lib/features/chats/providers/new_chat_controller.dart`

```dart
@freezed
abstract class NewChatState with _$NewChatState {
  const factory NewChatState({
    String? modelId,           // EXISTING
    String? providerId,        // NEW: Selected provider name
    @Default(false) bool isLoading,  // EXISTING
  }) = _NewChatState;
}
```

**Changes**:
- Added `providerId: String?` - Stores selected provider name (not ID)

**Rationale**: Provider name is used for grouping and display. Storing name directly avoids additional lookups.

### New Provider: listModelsGroupedByProviderProvider

**File**: `apps/auravibes_app/lib/features/models/providers/list_chat_models_providers.dart`

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

**Output Type**: `Map<String, List<CredentialsModelWithProviderEntity>>`

**Key**: Provider name (e.g., "OpenAI", "Anthropic")
**Value**: List of models for that provider

## Existing Entities (No Changes)

### CredentialsModelWithProviderEntity

**File**: `apps/auravibes_app/lib/domain/entities/credentials_models_entities.dart`

```dart
@freezed
abstract class CredentialsModelWithProviderEntity
    with _$CredentialsModelWithProviderEntity {
  const factory CredentialsModelWithProviderEntity({
    required CredentialsModelEntity credentialsModel,
    required CredentialsEntity credentials,
    required ApiModelProviderEntity modelsProvider,  // Contains provider info
  }) = _CredentialsModelWithProviderEntity;
}
```

**Usage**: Already contains all needed provider information via `modelsProvider.name`.

### ApiModelProviderEntity

**File**: `apps/auravibes_app/lib/domain/entities/api_model_provider.dart`

```dart
@freezed
abstract class ApiModelProviderEntity with _$ApiModelProviderEntity {
  const factory ApiModelProviderEntity({
    required String id,
    required String name,    // Used as grouping key
    required ModelProvidersType? type,
    String? url,
    String? doc,
  }) = _ApiModelProviderEntity;
}
```

**Usage**: `name` field used as provider identifier in dropdowns.

## Data Flow

```
Database (Drift)
    │
    ▼
CredentialsModelsRepository
    │
    ▼
listCredentialsCredentialsProvider
    │
    ├──► Direct usage (existing)
    │
    └──► listModelsGroupedByProviderProvider (NEW)
              │
              ▼
         SelectCredentialsModelWidget
              │
              ├──► Provider dropdown (keys)
              │
              └──► Model dropdown (values[providerId])
```

## State Transitions

### NewChatState

```
Initial State:
{
  modelId: null,
  providerId: null,
  isLoading: false
}

User selects provider:
{
  modelId: null,           // Reset
  providerId: "OpenAI",    // Set
  isLoading: false
}

User selects model:
{
  modelId: "uuid-123",     // Set
  providerId: "OpenAI",    // Unchanged
  isLoading: false
}

User changes provider:
{
  modelId: null,           // Reset
  providerId: "Anthropic", // Changed
  isLoading: false
}

User starts chat:
{
  modelId: "uuid-123",
  providerId: "OpenAI",
  isLoading: true          // Set during API call
}
```

## Validation Rules

| Field | Rule | Enforcement |
|-------|------|-------------|
| `providerId` | Must be a key in `listModelsGroupedByProviderProvider` | UI (dropdown options) |
| `modelId` | Must belong to selected provider's model list | UI (dropdown options) |
| `modelId` | Required to start chat | Controller (throws exception) |

## Database Impact

**No schema changes required.** All data comes from existing tables:
- `credentials` table
- `credentials_models` table
- `api_model_providers` table

## Migration Notes

None - this is a UI/state change only.
