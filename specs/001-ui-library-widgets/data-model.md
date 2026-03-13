# Data Model: UI Library Widget Expansion

**Feature**: 001-ui-library-widgets
**Date**: 2026-03-11

## Overview

This feature adds UI components to the `auravibes_ui` package. These are stateless presentation components with no data persistence. The "data model" here refers to the component interfaces and configuration objects.

## Component Models

### AuraButtonVariant (Extension)

```dart
enum AuraButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  elevated,
  text,  // NEW - transparent background, no border, inline use
}
```

**State Transitions**: None (enum)

---

### AuraConfirmDialog

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| title | Widget | ✅ | - | Dialog title |
| message | Widget | ✅ | - | Dialog content |
| confirmLabel | Widget? | ❌ | "Confirm" | Confirm button label |
| cancelLabel | Widget? | ❌ | "Cancel" | Cancel button label |
| onConfirm | VoidCallback? | ❌ | null | Confirm action callback |
| onCancel | VoidCallback? | ❌ | null | Cancel action callback |
| isDestructive | bool | ❌ | false | Styles confirm as destructive |
| colorVariant | AuraColorVariant? | ❌ | null | Accent color |

**State Transitions**: None (stateless widget)

---

### AuraAlertDialog

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| title | Widget | ✅ | - | Dialog title |
| message | Widget | ✅ | - | Dialog content |
| dismissLabel | Widget? | ❌ | "OK" | Dismiss button label |
| colorVariant | AuraColorVariant? | ❌ | null | Accent color |

**State Transitions**: None (stateless widget)

---

### AuraSnackBarVariant

```dart
enum AuraSnackBarVariant {
  default_,  // Uses surface colors
  success,   // Green tint
  error,     // Red tint
  warning,   // Yellow tint
  info,      // Blue tint
}
```

**State Transitions**: None (enum)

---

### AuraRadioOption<T>

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| value | T | ✅ | - | Option value |
| label | Widget | ✅ | - | Option display label |
| subtitle | Widget? | ❌ | null | Optional subtitle |

**State Transitions**: None (immutable configuration class)

---

### AuraRadio<T>

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| value | T | ✅ | - | This radio's value |
| groupValue | T? | ✅ | - | Currently selected value |
| onChanged | ValueChanged<T?>? | ✅ | - | Selection callback |
| colorVariant | AuraColorVariant? | ❌ | null | Radio color |
| disabled | bool | ❌ | false | Disabled state |

**State Transitions**:
- Unselected → Selected (when value == groupValue)
- Enabled → Disabled (visual only, no callback)

---

### AuraRadioGroup<T>

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| value | T? | ✅ | - | Currently selected value |
| onChanged | ValueChanged<T?>? | ✅ | - | Selection callback |
| options | List<AuraRadioOption<T>> | ✅ | - | Available options |
| label | Widget? | ❌ | null | Group label |
| direction | Axis | ❌ | Axis.vertical | Layout direction |
| colorVariant | AuraColorVariant? | ❌ | null | Radio color |

**State Transitions**:
- None → Selected (first selection)
- Option A → Option B (selection change)

---

### AuraRadioListTile<T>

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| value | T | ✅ | - | This tile's value |
| groupValue | T? | ✅ | - | Currently selected value |
| onChanged | ValueChanged<T?>? | ✅ | - | Selection callback |
| title | Widget | ✅ | - | Tile title |
| subtitle | Widget? | ❌ | null | Tile subtitle |
| colorVariant | AuraColorVariant? | ❌ | null | Radio color |
| disabled | bool | ❌ | false | Disabled state |

**State Transitions**: Same as AuraRadio

---

### AuraTooltip

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| message | String | ✅ | - | Tooltip text |
| child | Widget | ✅ | - | Widget to wrap |
| preferBelow | bool | ❌ | true | Position preference |
| colorVariant | AuraColorVariant? | ❌ | null | Tooltip background |

**State Transitions**:
- Hidden → Visible (on hover/long-press)
- Visible → Hidden (on exit/timeout)

---

### AuraSelectableText

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| data | String | ✅ | - | Text content |
| style | TextStyle? | ❌ | null | Text style |
| colorVariant | AuraColorVariant? | ❌ | null | Text color |
| textAlign | TextAlign? | ❌ | null | Text alignment |
| maxLines | int? | ❌ | null | Max lines |

**State Transitions**:
- Normal → Selected (user selection)
- Selected → Copied (clipboard action)

## Relationships

```
AuraRadioGroup<T>
    ├── AuraRadioOption<T> (1:N)
    └── AuraRadio<T> (1:N, via internal composition)

AuraRadioListTile<T>
    └── AuraRadio<T> (1:1, internal composition)

showAuraConfirmDialog()
    └── AuraConfirmDialog (1:1, creates)

showAuraAlertDialog()
    └── AuraAlertDialog (1:1, creates)

showAuraSnackBar()
    └── SnackBar (1:1, creates Material widget)
```

## Validation Rules

### AuraConfirmDialog
- title must not be empty
- message must not be empty
- If isDestructive: confirm button uses AuraColorVariant.error

### AuraRadioGroup<T>
- options must not be empty (documented behavior: empty = no radios)
- value should match one option's value (not enforced)

### AuraRadio<T>
- When disabled: onChanged must be null or ignored
- groupValue changes trigger visual update only

### AuraTooltip
- message should be concise (< 100 chars recommended)
- child must not be null

### AuraSelectableText
- data can be any length (scrollable if needed)

## Entity Summary

| Entity | Type | Atomic Level | Stateful |
|--------|------|--------------|----------|
| AuraButtonVariant | enum | - | No |
| AuraConfirmDialog | widget | organism | No |
| AuraAlertDialog | widget | organism | No |
| AuraSnackBarVariant | enum | - | No |
| AuraRadioOption<T> | class | molecule | No |
| AuraRadio<T> | widget | molecule | No |
| AuraRadioGroup<T> | widget | organism | No |
| AuraRadioListTile<T> | widget | organism | No |
| AuraTooltip | widget | atom | No |
| AuraSelectableText | widget | atom | No |
