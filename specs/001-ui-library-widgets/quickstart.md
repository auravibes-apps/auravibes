# Quickstart: UI Library Widget Expansion

**Feature**: 001-ui-library-widgets
**Date**: 2026-03-11

This guide provides quick examples for using the new UI components.

## Installation

Components are part of the `auravibes_ui` package. Import via:

```dart
import 'package:auravibes_ui/ui.dart';
```

---

## AuraButton.text Variant

### Basic Usage

```dart
// Simple text button
AuraButton(
  variant: AuraButtonVariant.text,
  onPressed: () => handleAction(),
  child: const Text('Click me'),
)

// Text button with color variant
AuraButton(
  variant: AuraButtonVariant.text,
  colorVariant: AuraColorVariant.error,
  onPressed: () => handleDelete(),
  child: const Text('Delete'),
)

// Text button with icon
AuraButton(
  variant: AuraButtonVariant.text,
  onPressed: () => handleAction(),
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.add),
      SizedBox(width: 8),
      Text('Add Item'),
    ],
  ),
)
```

### Migration from TextButton

```dart
// Before
TextButton(
  onPressed: () => handleAction(),
  child: const Text('Click me'),
)

// After
AuraButton(
  variant: AuraButtonVariant.text,
  onPressed: () => handleAction(),
  child: const Text('Click me'),
)
```

---

## Confirmation Dialogs

### Basic Confirmation

```dart
final confirmed = await showAuraConfirmDialog(
  context: context,
  title: const Text('Delete Item'),
  message: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
);

if (confirmed ?? false) {
  // User confirmed
  await deleteItem();
}
```

### Destructive Action

```dart
final confirmed = await showAuraConfirmDialog(
  context: context,
  title: const Text('Delete MCP Server'),
  message: const Text('This will remove all tools from this server.'),
  isDestructive: true,
  confirmLabel: const Text('Delete'),
  cancelLabel: const Text('Keep'),
);

if (confirmed ?? false) {
  await deleteMcpServer();
}
```

### Custom Labels

```dart
final confirmed = await showAuraConfirmDialog(
  context: context,
  title: const Text('Save Changes'),
  message: const Text('You have unsaved changes. Save before closing?'),
  confirmLabel: const Text('Save'),
  cancelLabel: const Text('Discard'),
  colorVariant: AuraColorVariant.primary,
);
```

### Using Widget Directly

```dart
showDialog<void>(
  context: context,
  builder: (context) => AuraConfirmDialog(
    title: const Text('Custom Dialog'),
    message: const Text('With custom content.'),
    onConfirm: () {
      Navigator.pop(context);
      handleConfirm();
    },
    onCancel: () {
      Navigator.pop(context);
    },
  ),
);
```

---

## Alert Dialogs

### Basic Alert

```dart
await showAuraAlertDialog(
  context: context,
  title: const Text('Update Available'),
  message: const Text('A new version of the app is available. Please restart to update.'),
);
```

### Error Alert

```dart
await showAuraAlertDialog(
  context: context,
  title: const Text('Connection Error'),
  message: Text('Failed to connect: $errorMessage'),
  colorVariant: AuraColorVariant.error,
  dismissLabel: const Text('OK'),
);
```

---

## SnackBar Notifications

### Basic SnackBar

```dart
showAuraSnackBar(
  context: context,
  content: const Text('Operation completed successfully'),
);
```

### Success SnackBar

```dart
showAuraSnackBar(
  context: context,
  content: const Text('Settings saved'),
  variant: AuraSnackBarVariant.success,
);
```

### Error SnackBar

```dart
showAuraSnackBar(
  context: context,
  content: Text('Failed to save: $error'),
  variant: AuraSnackBarVariant.error,
  duration: const Duration(seconds: 6),
);
```

### SnackBar with Action

```dart
showAuraSnackBar(
  context: context,
  content: const Text('Item deleted'),
  variant: AuraSnackBarVariant.info,
  actionLabel: 'Undo',
  onAction: () {
    // Restore the deleted item
    restoreItem();
  },
);
```

---

## Radio Selection

### Basic Radio Group

```dart
final selectedTheme = useState<AppTheme>(AppTheme.system);

AuraRadioGroup<AppTheme>(
  value: selectedTheme.value,
  onChanged: (value) {
    if (value != null) {
      selectedTheme.value = value;
    }
  },
  options: const [
    AuraRadioOption(
      value: AppTheme.system,
      label: Text('System Default'),
    ),
    AuraRadioOption(
      value: AppTheme.light,
      label: Text('Light'),
    ),
    AuraRadioOption(
      value: AppTheme.dark,
      label: Text('Dark'),
    ),
  ],
  label: const Text('Theme'),
)
```

### Radio Group with Subtitles

```dart
AuraRadioGroup<SortOrder>(
  value: currentSort,
  onChanged: (value) => updateSort(value),
  options: const [
    AuraRadioOption(
      value: SortOrder.alphabetical,
      label: Text('Alphabetical'),
      subtitle: Text('Sort items from A to Z'),
    ),
    AuraRadioOption(
      value: SortOrder.recent,
      label: Text('Most Recent'),
      subtitle: Text('Sort by last modified date'),
    ),
  ],
)
```

### Horizontal Radio Group

```dart
AuraRadioGroup<ViewMode>(
  value: viewMode,
  onChanged: (value) => setViewMode(value),
  direction: Axis.horizontal,
  options: const [
    AuraRadioOption(value: ViewMode.list, label: Text('List')),
    AuraRadioOption(value: ViewMode.grid, label: Text('Grid')),
  ],
)
```

### Radio List Tile (Individual)

```dart
Column(
  children: [
    AuraRadioListTile<String>(
      value: 'option1',
      groupValue: selectedOption,
      onChanged: (value) => setState(() => selectedOption = value),
      title: const Text('Option 1'),
      subtitle: const Text('Description of option 1'),
    ),
    AuraRadioListTile<String>(
      value: 'option2',
      groupValue: selectedOption,
      onChanged: (value) => setState(() => selectedOption = value),
      title: const Text('Option 2'),
      subtitle: const Text('Description of option 2'),
    ),
  ],
)
```

---

## Tooltips

### Basic Tooltip

```dart
AuraTooltip(
  message: 'Click to add a new item',
  child: AuraIconButton(
    icon: Icons.add,
    onPressed: () => handleAdd(),
  ),
)
```

### Tooltip Above Widget

```dart
AuraTooltip(
  message: 'Settings',
  preferBelow: false,
  child: AuraIconButton(
    icon: Icons.settings,
    onPressed: () => openSettings(),
  ),
)
```

### Custom Color Tooltip

```dart
AuraTooltip(
  message: 'Warning: This action is irreversible',
  colorVariant: AuraColorVariant.warning,
  child: const Icon(Icons.warning),
)
```

---

## Selectable Text

### Basic Selectable Text

```dart
AuraSelectableText(
  'This text can be selected and copied by the user.',
)
```

### With Custom Style

```dart
AuraSelectableText(
  errorMessage,
  style: TextStyle(
    fontSize: 14,
    fontFamily: 'monospace',
  ),
  colorVariant: AuraColorVariant.error,
)
```

### With Max Lines

```dart
AuraSelectableText(
  longText,
  maxLines: 5,
  textAlign: TextAlign.left,
)
```

---

## Complete Example: Settings Dialog

```dart
class ThemeSettingsDialog extends HookConsumerWidget {
  const ThemeSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeControllerProvider);
    final currentTheme = themeAsync.asData?.value ?? AppTheme.system;
    final selectedTheme = useState(currentTheme);

    return AuraConfirmDialog(
      title: const Text('Theme Settings'),
      message: AuraRadioGroup<AppTheme>(
        value: selectedTheme.value,
        onChanged: (value) {
          if (value != null) {
            selectedTheme.value = value;
          }
        },
        options: const [
          AuraRadioOption(
            value: AppTheme.system,
            label: Text('System Default'),
            subtitle: Text('Follow system appearance'),
          ),
          AuraRadioOption(
            value: AppTheme.light,
            label: Text('Light'),
            subtitle: Text('Always use light mode'),
          ),
          AuraRadioOption(
            value: AppTheme.dark,
            label: Text('Dark'),
            subtitle: Text('Always use dark mode'),
          ),
        ],
      ),
      confirmLabel: const Text('Apply'),
      cancelLabel: const Text('Cancel'),
      onConfirm: () {
        ref.read(themeControllerProvider.notifier).setTheme(selectedTheme.value);
        Navigator.pop(context);
        showAuraSnackBar(
          context: context,
          content: const Text('Theme updated'),
          variant: AuraSnackBarVariant.success,
        );
      },
      onCancel: () {
        Navigator.pop(context);
      },
    );
  }
}

// Usage
showDialog<void>(
  context: context,
  builder: (context) => const ThemeSettingsDialog(),
);
```

---

## Common Patterns

### Replace all TextButton with AuraButton.text

```dart
// Search pattern
TextButton\(
  onPressed:\s*\(([^)]*)\)\s*=>\s*([^,]+),
  child:\s*([^)]+),
\)

// Replace with
AuraButton(
  variant: AuraButtonVariant.text,
  onPressed: ($1) => $2,
  child: $3,
)
```

### Replace all showDialog<AlertDialog>

```dart
// Before
showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Title'),
    content: Text('Message'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
);

// After
showAuraAlertDialog(
  context: context,
  title: const Text('Title'),
  message: const Text('Message'),
);
```

---

## Testing

All widgets support standard Flutter widget testing:

```dart
testWidgets('AuraButton.text renders correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AuraButton(
          variant: AuraButtonVariant.text,
          onPressed: () {},
          child: const Text('Click me'),
        ),
      ),
    ),
  );

  expect(find.text('Click me'), findsOneWidget);
});
```
