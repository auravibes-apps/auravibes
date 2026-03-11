# Two-Step Model Selector UX Design

**Date:** 2026-03-10
**Status:** Approved
**Author:** Design session

## Problem Statement

The current model selection UI presents all models from all providers in a single flat dropdown. This creates poor UX because:

1. Users think **provider-first** ("I want OpenAI") before selecting a specific model
2. Flat lists don't scale — 30+ models become hard to navigate
3. No clear relationship between provider and model

## Solution: Two-Step Cascading Selector

Replace the single dropdown with two cascading dropdowns:

```
┌──────────────────────────────────────────────────────────┐
│  ← New Chat                                    [☰]       │
├──────────────────────────────────────────────────────────┤
│  [Provider ▼]              [Model ▼]                     │
│   OpenAI                    gpt-4o                        │
└──────────────────────────────────────────────────────────┘
```

### User Flow

1. Select provider from first dropdown
2. Model dropdown enables with filtered models
3. Select model from second dropdown
4. Chat input enables

## Design Details

### UI Components

| Component | Behavior |
|-----------|----------|
| Provider Dropdown | Lists all providers with configured credentials |
| Model Dropdown | Shows models filtered by selected provider |

### States

| State | Provider Dropdown | Model Dropdown |
|-------|------------------|----------------|
| Initial | "Select provider" (enabled) | "Select model" (disabled) |
| Provider selected | Shows provider name | "Select model" (enabled) |
| Both selected | Shows provider name | Shows model ID |
| Loading | Skeleton/spinner | Disabled |
| Error | Error message | Disabled |

### Edge Cases

| Case | Behavior |
|------|----------|
| No providers configured | Show "No providers" message, both dropdowns disabled |
| Provider has no models | Show "No models available" in model dropdown |
| Single provider | Pre-select it, user only picks model |
| Network error | Show retry button in affected dropdown |

## State Management

### New Provider

```dart
// Groups models by provider for efficient filtering
listModelsGroupedByProviderProvider
├── Returns: Map<String, List<CredentialsModelWithProviderEntity>>
├── Key: Provider name (e.g., "OpenAI", "Anthropic")
└── Value: List of models for that provider
```

### Modified Controller

```dart
newChatControllerProvider
├── State: { modelId, providerId, isLoading }
├── Actions:
│   ├── setProvider(providerId) → resets modelId to null
│   ├── setModel(modelId) → validates same provider
│   └── getAvailableModels() → filtered by selected provider
```

### Data Flow

```
1. Widget mounts
   └── Watch listModelsGroupedByProviderProvider
   └── Watch newChatControllerProvider

2. User selects provider
   └── newChatController.setProvider(providerId)
   └── modelId resets to null
   └── Model dropdown enables with filtered list

3. User selects model
   └── newChatController.setModel(modelId)
   └── Chat input enables

4. User starts chat
   └── Uses selected modelId for conversation
```

## Implementation

### Files to Modify/Create

| File | Action | Purpose |
|------|--------|---------|
| `select_chat_model.dart` | Refactor | Replace single dropdown with two-step selector |
| `new_chat_controller.dart` | Modify | Add `providerId` state, add `setProvider()` method |
| `list_chat_models_providers.dart` | Add | New `listModelsGroupedByProviderProvider` |

## Trade-offs

| Aspect | Decision |
|--------|----------|
| Two taps for switchers | Accepted — clarity and scalability outweigh extra tap |
| No persistence | Simpler implementation, users re-select each session |
| Horizontal layout | Works in app bar, keeps chat UI clean |

## Success Criteria

- [ ] Users can select provider first, then model
- [ ] Model list is filtered by selected provider
- [ ] Changing provider resets model selection
- [ ] UI scales gracefully with 5-50+ models
- [ ] Works in app bar without modal/sheet
