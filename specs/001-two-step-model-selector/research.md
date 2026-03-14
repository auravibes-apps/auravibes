# Research: Two-Step Model Selector

**Date**: 2026-03-11
**Feature**: 001-two-step-model-selector

## Research Summary

This feature is well-scoped with minimal unknowns. Research focused on implementation patterns within the existing codebase.

## Decisions

### 1. Grouping Strategy

**Decision**: Group models by `modelsProvider.name` (String)

**Rationale**:
- Provider names are unique and user-facing
- Avoids complex ID-based grouping logic
- Natural sort order for dropdown display
- Matches user mental model (provider name, not ID)

**Alternatives Considered**:
- Group by `modelsProvider.id`: Rejected - requires additional lookup for display
- Create separate `ProviderEntity`: Rejected - over-engineering, existing data sufficient

### 2. State Reset Behavior

**Decision**: Reset `modelId` to `null` when `providerId` changes

**Rationale**:
- Matches user expectation: changing provider means re-selecting model
- Prevents invalid state (model from wrong provider)
- Simple implementation in `setProvider()` method

**Alternatives Considered**:
- Preserve model if same provider: Rejected - adds complexity, low value
- Show warning before reset: Rejected - interrupts user flow

### 3. Single Provider Handling

**Decision**: Pre-select provider if only one exists

**Rationale**:
- Reduces friction for simple configurations
- User still sees provider name (dropdown not hidden)
- Easy to implement: check `providers.length == 1` in widget build

**Alternatives Considered**:
- Hide provider dropdown for single provider: Rejected - loses context, confuses users
- No auto-selection: Rejected - unnecessary extra tap

### 4. Dropdown Layout

**Decision**: Side-by-side in `Row` with equal `Expanded` flex

**Rationale**:
- Fits in app bar bottom area
- Symmetrical visual weight
- Consistent with existing UI patterns
- Works on narrow screens (dropdowns handle overflow)

**Alternatives Considered**:
- Stacked vertically: Rejected - takes too much vertical space
- Provider dropdown above model: Rejected - same issue
- Modal/sheet: Rejected - spec explicitly excludes

### 5. Search/Filter in Dropdown

**Decision**: Use existing `AuraDropdownSelector` search capability

**Rationale**:
- Component already supports search header
- No custom implementation needed
- Consistent with existing model dropdown behavior

**Alternatives Considered**:
- Custom search widget: Rejected - unnecessary duplication
- No search: Rejected - poor UX for many models

## Technical Patterns

### Existing Code Patterns Used

| Pattern | Location | Usage |
|---------|----------|-------|
| `AuraDropdownSelector<T>` | `auravibes_ui` | Both dropdowns |
| `AsyncValue` handling | Existing widget | Loading/error states |
| `ref.watch()` + `useMemoized` | `select_chat_model.dart` | Derived data |
| Freezed state classes | `new_chat_controller.dart` | Immutable state |

### Code Generation Required

| File | Generator | Trigger |
|------|-----------|---------|
| `new_chat_controller.dart` | `freezed` + `riverpod_generator` | State change |
| `list_chat_models_providers.dart` | `riverpod_generator` | New provider |

## Dependencies

### Internal Dependencies

```
SelectCredentialsModelWidget
├── listModelsGroupedByProviderProvider (NEW)
│   └── listCredentialsCredentialsProvider (EXISTING)
├── NewChatController (MODIFIED)
│   └── state.providerId (NEW)
│   └── setProvider() (NEW)
└── AuraDropdownSelector (EXISTING in auravibes_ui)
```

### External Dependencies

None - all functionality uses existing Flutter/Riverpod patterns.

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Provider name collision | Low | Medium | Use unique constraint in DB (already exists) |
| Large model list performance | Low | Low | AuraDropdownSelector handles virtualization |
| State sync issues | Low | Medium | Clear state reset in `setProvider()` |

## Conclusion

No blocking unknowns. Implementation can proceed with confidence using established patterns.
