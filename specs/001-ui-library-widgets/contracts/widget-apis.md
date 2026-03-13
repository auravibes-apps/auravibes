# Widget API Contracts

**Feature**: 001-ui-library-widgets
**Date**: 2026-03-11

This document defines the public API contracts for all new widgets in the UI library expansion.

## AuraButton.text Variant

### Enum Extension

```dart
// In: packages/auravibes_ui/lib/src/molecules/auravibes_button.dart

enum AuraButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  elevated,
  text,  // NEW
}
```

### Behavior Contract

| Variant | Background | Border | Text Color | Shadow |
|---------|------------|--------|------------|--------|
| text | transparent | none | colorVariant ?? primary | none |

### Padding Contract

```dart
// Text variant uses minimal padding for inline use
EdgeInsetsGeometry _getPadding(AuraSpacingTheme spacing) {
  return switch (variant) {
    AuraButtonVariant.text => EdgeInsets.symmetric(
      horizontal: spacing.sm,
      vertical: spacing.xs,
    ),
    // ... other variants
  };
}
```

---

## AuraConfirmDialog

### Widget Contract

```dart
// File: packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart

class AuraConfirmDialog extends StatelessWidget {
  const AuraConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.colorVariant,
  });

  /// The dialog title widget.
  final Widget title;

  /// The dialog message/content widget.
  final Widget message;

  /// Label for the confirm button. Defaults to localized "Confirm".
  final Widget? confirmLabel;

  /// Label for the cancel button. Defaults to localized "Cancel".
  final Widget? cancelLabel;

  /// Called when the confirm button is pressed.
  final VoidCallback? onConfirm;

  /// Called when the cancel button is pressed.
  final VoidCallback? onCancel;

  /// If true, confirm button uses error styling (red).
  final bool isDestructive;

  /// The accent color for the dialog.
  final AuraColorVariant? colorVariant;
}
```

### Helper Function Contract

```dart
/// Shows a confirmation dialog and returns whether the user confirmed.
///
/// Returns `true` if confirmed, `false` if cancelled, `null` if dismissed.
Future<bool?> showAuraConfirmDialog({
  required BuildContext context,
  required Widget title,
  required Widget message,
  Widget? confirmLabel,
  Widget? cancelLabel,
  bool isDestructive = false,
  bool barrierDismissible = true,
  AuraColorVariant? colorVariant,
});
```

### Return Value Contract

| User Action | Return Value |
|-------------|--------------|
| Tap confirm | `true` |
| Tap cancel | `false` |
| Tap outside | `null` (if barrierDismissible) |
| Press escape | `null` |

---

## AuraAlertDialog

### Widget Contract

```dart
class AuraAlertDialog extends StatelessWidget {
  const AuraAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.dismissLabel,
    this.colorVariant,
  });

  /// The dialog title widget.
  final Widget title;

  /// The dialog message/content widget.
  final Widget message;

  /// Label for the dismiss button. Defaults to localized "OK".
  final Widget? dismissLabel;

  /// The accent color for the dialog.
  final AuraColorVariant? colorVariant;
}
```

### Helper Function Contract

```dart
/// Shows an alert dialog with a single dismiss action.
Future<void> showAuraAlertDialog({
  required BuildContext context,
  required Widget title,
  required Widget message,
  Widget? dismissLabel,
  bool barrierDismissible = true,
  AuraColorVariant? colorVariant,
});
```

---

## AuraSnackBar

### Enum Contract

```dart
// File: packages/auravibes_ui/lib/src/molecules/auravibes_snackbar.dart

enum AuraSnackBarVariant {
  /// Default appearance using surface colors
  default_,
  
  /// Success message with green accent
  success,
  
  /// Error message with red accent
  error,
  
  /// Warning message with yellow accent
  warning,
  
  /// Info message with blue accent
  info,
}
```

### Function Contract

```dart
/// Shows a snackbar notification.
///
/// Requires a Scaffold ancestor in the widget tree.
///
/// Returns the ScaffoldFeatureController for the snackbar.
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAuraSnackBar({
  required BuildContext context,
  required Widget content,
  AuraSnackBarVariant variant = AuraSnackBarVariant.default_,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
});
```

### Color Contract

| Variant | Background Color | Text Color | Action Color |
|---------|------------------|------------|--------------|
| default_ | surfaceVariant | onSurface | primary |
| success | success (with opacity) | onSurface | onPrimary |
| error | error (with opacity) | onSurface | onError |
| warning | warning (with opacity) | onSurface | onWarning |
| info | info (with opacity) | onSurface | onInfo |

### Error Contract

```dart
// Throws FlutterError if no Scaffold ancestor exists
// Error message: "No ScaffoldMessenger found in context"
```

---

## AuraRadio<T>

### Widget Contract

```dart
// File: packages/auravibes_ui/lib/src/molecules/auravibes_radio.dart

class AuraRadio<T> extends StatelessWidget {
  const AuraRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.colorVariant,
    this.disabled = false,
  });

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value in the group.
  final T? groupValue;

  /// Called when the user selects this radio button.
  /// 
  /// If null, the radio button will be disabled.
  final ValueChanged<T?>? onChanged;

  /// The color variant for the radio button when selected.
  final AuraColorVariant? colorVariant;

  /// Whether the radio button is disabled.
  final bool disabled;
}
```

### Selection Contract

| Condition | Visual State | Interaction |
|-----------|--------------|-------------|
| value == groupValue | Selected (filled) | None |
| value != groupValue | Unselected (empty) | Tappable |
| disabled == true | Greyed out | No response |
| onChanged == null | Greyed out | No response |

---

## AuraRadioOption<T>

### Class Contract

```dart
class AuraRadioOption<T> {
  const AuraRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  /// The value this option represents.
  final T value;

  /// The display label for this option.
  final Widget label;

  /// Optional subtitle displayed below the label.
  final Widget? subtitle;
}
```

---

## AuraRadioGroup<T>

### Widget Contract

```dart
// File: packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart

class AuraRadioGroup<T> extends StatelessWidget {
  const AuraRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.label,
    this.direction = Axis.vertical,
    this.colorVariant,
  });

  /// The currently selected value.
  final T? value;

  /// Called when the selection changes.
  final ValueChanged<T?>? onChanged;

  /// The available options.
  final List<AuraRadioOption<T>> options;

  /// Optional label displayed above the options.
  final Widget? label;

  /// Layout direction for the options.
  final Axis direction;

  /// Color variant for all radio buttons in the group.
  final AuraColorVariant? colorVariant;
}
```

### Layout Contract

| direction | Layout |
|-----------|--------|
| Axis.vertical | Column with spacing.sm between items |
| Axis.horizontal | Row with spacing.md between items |

---

## AuraRadioListTile<T>

### Widget Contract

```dart
class AuraRadioListTile<T> extends StatelessWidget {
  const AuraRadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.colorVariant,
    this.disabled = false,
  });

  /// The value represented by this tile.
  final T value;

  /// The currently selected value in the group.
  final T? groupValue;

  /// Called when the user selects this tile.
  final ValueChanged<T?>? onChanged;

  /// The title widget.
  final Widget title;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Color variant when selected.
  final AuraColorVariant? colorVariant;

  /// Whether the tile is disabled.
  final bool disabled;
}
```

### Layout Contract

```
┌────────────────────────────────────────┐
│ ○  [Title]                             │
│    [Subtitle]                          │
└────────────────────────────────────────┘
```

- Radio: 24x24, left-aligned
- Title: AuraTextStyle.bodyMedium
- Subtitle: AuraTextStyle.bodySmall, onSurfaceVariant

---

## AuraTooltip

### Widget Contract

```dart
// File: packages/auravibes_ui/lib/src/atoms/auravibes_tooltip.dart

class AuraTooltip extends StatelessWidget {
  const AuraTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
    this.colorVariant,
  });

  /// The text to display in the tooltip.
  final String message;

  /// The widget to wrap with tooltip functionality.
  final Widget child;

  /// Whether to prefer showing the tooltip below the child.
  final bool preferBelow;

  /// Background color variant for the tooltip.
  final AuraColorVariant? colorVariant;
}
```

### Behavior Contract

| Platform | Trigger | Dismissal |
|----------|---------|-----------|
| Desktop | Mouse hover | Mouse exit |
| Mobile | Long press | Tap anywhere |

### Styling Contract

```dart
// Default colors (overridable via colorVariant)
backgroundColor: onSurface
textColor: surface
borderRadius: sm
padding: xs horizontal, xs/2 vertical
```

---

## AuraSelectableText

### Widget Contract

```dart
// File: packages/auravibes_ui/lib/src/atoms/auravibes_selectable_text.dart

class AuraSelectableText extends StatelessWidget {
  const AuraSelectableText(
    this.data, {
    super.key,
    this.style,
    this.colorVariant,
    this.textAlign,
    this.maxLines,
  });

  /// The text to display.
  final String data;

  /// Optional Aura text style variant. Color will be overridden by colorVariant.
  final AuraTextStyle? style;

  /// Text color variant.
  final AuraColorVariant? colorVariant;

  /// Text alignment.
  final TextAlign? textAlign;

  /// Maximum number of lines.
  final int? maxLines;
}
```

### Selection Contract

- Long press + drag: Selects text
- Copy action (via context menu): Copies to clipboard
- Platform-native selection handles and toolbar

---

## Export Contract

All widgets must be exported from:

```dart
// File: packages/auravibes_ui/lib/ui.dart

export 'src/atoms/auravibes_selectable_text.dart';
export 'src/atoms/auravibes_tooltip.dart';
export 'src/molecules/auravibes_radio.dart';
export 'src/molecules/auravibes_snackbar.dart' show showAuraSnackBar, AuraSnackBarVariant;
export 'src/organisms/auravibes_dialog.dart' show AuraConfirmDialog, AuraAlertDialog, showAuraConfirmDialog, showAuraAlertDialog;
export 'src/organisms/auravibes_radio_group.dart' show AuraRadioGroup, AuraRadioListTile, AuraRadioOption;
```

---

## Breaking Changes Policy

These APIs are **new** and have no existing consumers. The following changes would be breaking:

1. Removing any public property from a widget
2. Making a required parameter optional (or vice versa)
3. Changing the type of any parameter
4. Changing the return type of helper functions
5. Removing enum values

All changes to these contracts require:
1. Documentation in CHANGELOG
2. Migration guide if breaking
3. Version bump following semver
