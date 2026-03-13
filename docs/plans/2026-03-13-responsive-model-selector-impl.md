# Responsive Model Selector Layout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix the responsive layout issue where the model selector text wrapping causes the header to shrink and cut off the title and menu button on narrow screens.

**Architecture:** Use existing `DesignBreakpoints` tokens (sm=640px, md=768px) to switch between three layouts: side-by-side in AppBar (≥768px), stacked in AppBar (640-768px), and in body content (<640px). Add text truncation with ellipsis for long model names.

**Tech Stack:** Flutter, `MediaQuery`, `DesignBreakpoints` from auravibes_ui, existing `AuraDropdownSelector`

---

## Task 1: Add Text Truncation to AuraDropdownSelector

**Files:**
- Modify: `packages/auravibes_ui/lib/src/organisms/auravibes_dropdown_selector.dart`

**Step 1: Add truncation to dropdown option text**

In `_DropdownMenuState.build()` around line 285-304, find the option text widget and add truncation:

```dart
// Find this section (around line 291):
Expanded(
  child: AuraText(
    child: DefaultTextStyle(
      style: TextStyle(
        color: option.isEnabled
            ? auraColors.onSurface
            : auraColors.onSurface.withValues(
                alpha: 0.6,
              ),
      ),
      child: option.child!,
    ),
  ),
),

// Change to:
Expanded(
  child: AuraText(
    child: DefaultTextStyle(
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(
        color: option.isEnabled
            ? auraColors.onSurface
            : auraColors.onSurface.withValues(
                alpha: 0.6,
              ),
      ),
      child: option.child!,
    ),
  ),
),
```

**Step 2: Add truncation to selected value display**

In `_AuraDropdownSelectorState._getDisplayText()` around line 112-131, wrap the text with overflow:

```dart
// Find this section:
Widget _getDisplayText() {
  if (widget.value == null) {
    if (widget.placeholder != null) {
      return AuraText(
        color: AuraColorVariant.onSurfaceVariant,
        child: widget.placeholder!,
      );
    }
    return const Text('');
  }

  final selectedOption = widget.options.firstWhere(
    (option) => option.value == widget.value,
    orElse: () => AuraDropdownOption<T>(
      value: widget.value as T,
      child: const Text(''),
    ),
  );

  return selectedOption.child ?? const Text('');
}

// Change to:
Widget _getDisplayText() {
  if (widget.value == null) {
    if (widget.placeholder != null) {
      return AuraText(
        color: AuraColorVariant.onSurfaceVariant,
        child: widget.placeholder!,
      );
    }
    return const Text('');
  }

  final selectedOption = widget.options.firstWhere(
    (option) => option.value == widget.value,
    orElse: () => AuraDropdownOption<T>(
      value: widget.value as T,
      child: const Text(''),
    ),
  );

  // Wrap in LayoutBuilder to get constraints
  return LayoutBuilder(
    builder: (context, constraints) {
      return selectedOption.child ?? const Text('');
    },
  );
}
```

Actually, simpler approach - the selected option child is already a Text widget. We need to ensure it truncates. The issue is that `option.child` is provided externally. Let me check how options are created...

Looking at `select_chat_model.dart`, options are created like:
```dart
AuraDropdownOption(
  value: name,
  child: Text(name),  // <-- This needs maxLines and overflow
),
```

So the fix needs to be in `select_chat_model.dart` where options are created, not in the selector itself. Skip modifying auravibes_ui for now.

**Step 3: Commit (skip for now - fix in Task 2 instead)**

---

## Task 2: Add Text Truncation to SelectCredentialsModelWidget Options

**Files:**
- Modify: `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`

**Step 1: Add truncation to _ProviderDropdown options**

Find the `_ProviderDropdown` widget (around line 140-167) and update the option builder:

```dart
// Find this section:
options: providerNames
    .map(
      (name) => AuraDropdownOption(
        value: name,
        child: Text(name),
      ),
    )
    .toList(),

// Change to:
options: providerNames
    .map(
      (name) => AuraDropdownOption(
        value: name,
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    )
    .toList(),
```

**Step 2: Add truncation to _ModelDropdown options**

Find the `_ModelDropdown` widget (around line 170-229) and update the option builder:

```dart
// Find this section:
options: models
    .map(
      (model) => AuraDropdownOption(
        value: model.credentialsModel.id,
        child: Text(
          model.credentialsModel.modelId,
        ), // FR-007: Show model ID
      ),
    )
    .toList(),

// Change to:
options: models
    .map(
      (model) => AuraDropdownOption(
        value: model.credentialsModel.id,
        child: Text(
          model.credentialsModel.modelId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    )
    .toList(),
```

**Step 3: Run analyze to verify**

Run: `fvm dart run melos analyze`
Expected: No errors

**Step 4: Commit**

```bash
git add apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart
git commit -m "fix: add text truncation to dropdown options"
```

---

## Task 3: Add Responsive Layout to SelectCredentialsModelWidget

**Files:**
- Modify: `apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart`

**Step 1: Add import for DesignBreakpoints**

Add at the top of the file (around line 6):

```dart
import 'package:auravibes_ui/ui.dart';
// Already imported - DesignBreakpoints is part of ui.dart
```

**Step 2: Add responsive layout logic in build method**

Find the `build` method (around line 33) and add screen width detection after the `useEffect`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final groupedModelsAsync = ref.watch(listModelsGroupedByProviderProvider);

  final searchValue = useState<String>('');
  final controller = useTextEditingController();

  // Internal provider state if no external control
  final internalProviderId = useState<String?>(null);
  final effectiveProviderId = selectedProviderId ?? internalProviderId.value;

  // ADD THIS: Responsive layout detection
  final screenWidth = MediaQuery.of(context).size.width;
  final isCompact = screenWidth < DesignBreakpoints.md; // <768px

  // ... rest of the code (useEffect stays the same)
```

**Step 3: Update the Row to be responsive**

Find the `Row` widget (around line 101-129) and replace with responsive layout:

```dart
// Find this section:
return AuraPadding(
  padding: const AuraEdgeInsetsGeometry.only(
    bottom: .sm,
    left: .md,
    right: .md,
  ),
  child: Row(
    children: [
      // Provider dropdown
      Expanded(
        child: _ProviderDropdown(
          providerNames: providerNames,
          selectedProvider: effectiveProviderId,
          onChanged: (provider) {
            internalProviderId.value = provider;
            onProviderChanged?.call(provider);
            // Reset model when provider changes (FR-004)
            selectCredentialsModelId(null);
          },
        ),
      ),
      const SizedBox(width: DesignSpacing.sm),
      // Model dropdown
      Expanded(
        child: _ModelDropdown(
          models: filteredModels,
          selectedModelId: credentialsModelId,
          providerSelected: effectiveProviderId != null,
          onChanged: selectCredentialsModelId,
          searchValue: searchValue,
          controller: controller,
        ),
      ),
    ],
  ),
);

// Change to:
return AuraPadding(
  padding: const AuraEdgeInsetsGeometry.only(
    bottom: .sm,
    left: .md,
    right: .md,
  ),
  child: isCompact
      ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ProviderDropdown(
              providerNames: providerNames,
              selectedProvider: effectiveProviderId,
              onChanged: (provider) {
                internalProviderId.value = provider;
                onProviderChanged?.call(provider);
                selectCredentialsModelId(null);
              },
            ),
            const SizedBox(height: DesignSpacing.sm),
            _ModelDropdown(
              models: filteredModels,
              selectedModelId: credentialsModelId,
              providerSelected: effectiveProviderId != null,
              onChanged: selectCredentialsModelId,
              searchValue: searchValue,
              controller: controller,
            ),
          ],
        )
      : Row(
          children: [
            Expanded(
              child: _ProviderDropdown(
                providerNames: providerNames,
                selectedProvider: effectiveProviderId,
                onChanged: (provider) {
                  internalProviderId.value = provider;
                  onProviderChanged?.call(provider);
                  selectCredentialsModelId(null);
                },
              ),
            ),
            const SizedBox(width: DesignSpacing.sm),
            Expanded(
              child: _ModelDropdown(
                models: filteredModels,
                selectedModelId: credentialsModelId,
                providerSelected: effectiveProviderId != null,
                onChanged: selectCredentialsModelId,
                searchValue: searchValue,
                controller: controller,
              ),
            ),
          ],
        ),
);
```

**Step 4: Run analyze**

Run: `fvm dart run melos analyze`
Expected: No errors

**Step 5: Commit**

```bash
git add apps/auravibes_app/lib/features/models/widgets/select_chat_model.dart
git commit -m "feat: add responsive Row/Column layout for model selector"
```

---

## Task 4: Add Responsive Placement in NewChatScreen

**Files:**
- Modify: `apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart`

**Step 1: Add responsive detection in build method**

Find the `build` method (around line 18) and add screen width detection:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(newChatControllerProvider);

  // ADD THIS: Responsive layout detection
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < DesignBreakpoints.sm; // <640px

  Future<void> onToolsPress() async {
    // ... existing code
```

**Step 2: Update the AppBar to conditionally show selector**

Find the `AuraScreen` widget (around line 54) and update:

```dart
// Find this section:
return AuraScreen(
  appBar: AuraAppBarWithDrawer(
    title: const TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
    bottom: SelectCredentialsModelWidget(
      credentialsModelId: state.modelId,
      selectedProviderId: state.providerId,
      selectCredentialsModelId: (value) {
        ref.read(newChatControllerProvider.notifier).setModelId(value);
      },
      onProviderChanged: (provider) {
        ref.read(newChatControllerProvider.notifier).setProvider(provider);
      },
    ),
  ),
  child: Stack(
    children: [
      Center(
        child: ChatInputWidget(
          disabled: state.isLoading || state.modelId == null,
          onSendMessage: handleSendMessage,
          onToolsPress: onToolsPress,
        ),
      ),
      if (state.isLoading)
        ColoredBox(
          color: Colors.black.withValues(alpha: 0.3),
          child: const Center(child: CircularProgressIndicator()),
        ),
    ],
  ),
);

// Change to:
return AuraScreen(
  appBar: AuraAppBarWithDrawer(
    title: const TextLocale(LocaleKeys.home_screen_actions_start_new_chat),
    bottom: isSmallScreen
        ? null
        : SelectCredentialsModelWidget(
            credentialsModelId: state.modelId,
            selectedProviderId: state.providerId,
            selectCredentialsModelId: (value) {
              ref.read(newChatControllerProvider.notifier).setModelId(value);
            },
            onProviderChanged: (provider) {
              ref.read(newChatControllerProvider.notifier).setProvider(provider);
            },
          ),
  ),
  child: Column(
    children: [
      if (isSmallScreen)
        SelectCredentialsModelWidget(
          credentialsModelId: state.modelId,
          selectedProviderId: state.providerId,
          selectCredentialsModelId: (value) {
            ref.read(newChatControllerProvider.notifier).setModelId(value);
          },
          onProviderChanged: (provider) {
            ref.read(newChatControllerProvider.notifier).setProvider(provider);
          },
        ),
      Expanded(
        child: Stack(
          children: [
            Center(
              child: ChatInputWidget(
                disabled: state.isLoading || state.modelId == null,
                onSendMessage: handleSendMessage,
                onToolsPress: onToolsPress,
              ),
            ),
            if (state.isLoading)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    ],
  ),
);
```

**Step 3: Run analyze**

Run: `fvm dart run melos analyze`
Expected: No errors

**Step 4: Commit**

```bash
git add apps/auravibes_app/lib/features/chats/screens/new_chat_screen.dart
git commit -m "feat: move selector to body on small screens (<640px)"
```

---

## Task 5: Run Tests and Verify

**Files:**
- None (verification only)

**Step 1: Run analyze**

Run: `fvm dart run melos analyze`
Expected: No errors

**Step 2: Run format**

Run: `fvm dart run melos format`
Expected: 0 files changed

**Step 3: Run existing tests**

Run: `cd apps/auravibes_app && fvm flutter test`
Expected: All tests pass (or same status as before)

**Step 4: Manual verification**

Test on different screen sizes:
- Desktop (≥1024px): Side-by-side in AppBar
- Tablet landscape (768-1024px): Side-by-side in AppBar
- Tablet portrait (640-768px): Stacked in AppBar
- Mobile (<640px): Selector in body content

**Step 5: Commit any formatting changes**

```bash
git add -A
git commit -m "chore: format code after responsive layout changes"
```

---

## Summary

| Task | Description | Files Modified |
|------|-------------|----------------|
| 1 | Add text truncation to dropdown options | `select_chat_model.dart` |
| 2 | Add responsive Row/Column layout | `select_chat_model.dart` |
| 3 | Move selector to body on small screens | `new_chat_screen.dart` |
| 4 | Verify with tests and manual testing | None |

**Total commits expected:** 4-5
