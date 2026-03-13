# Implementation Plan: UI Library Widget Expansion

**Branch**: `001-ui-library-widgets` | **Date**: 2026-03-11 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-ui-library-widgets/spec.md`

## Summary

Expand the `auravibes_ui` package with missing Material Design widgets to eliminate direct Material imports in the main app. This includes:
- **P1**: Dialog system (`AuraConfirmDialog`, `AuraAlertDialog`, `showAuraDialog()`) and `text` button variant
- **P2**: SnackBar notifications (`showAuraSnackBar()`) and Radio selection components (`AuraRadio`, `AuraRadioGroup`, `AuraRadioListTile`)
- **P3**: Tooltip (`AuraTooltip`) and SelectableText (`AuraSelectableText`)

All components will follow the const-first design pattern using `AuraColorVariant` enums.

## Technical Context

**Language/Version**: Dart 3.11+ (Flutter 3.41.4+ via FVM)
**Primary Dependencies**: Flutter SDK, flutter_portal, gpt_markdown, riverpod (existing)
**Storage**: N/A (UI components only)
**Testing**: Flutter widget tests, 80%+ coverage required
**Target Platform**: Cross-platform (iOS, Android, macOS, Windows, Linux, Web)
**Project Type**: Flutter UI library package (auravibes_ui)
**Performance Goals**: 60 fps animations, <16ms frame time
**Constraints**: Const-compatible components, atomic design hierarchy
**Scale/Scope**: 8 new components/variants across atoms, molecules, and organisms

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Start with User Needs | ✅ PASS | 6 prioritized user stories with acceptance criteria |
| II. Design with Data | ✅ PASS | N/A - UI components only, no data persistence |
| III. Package-First Architecture | ✅ PASS | All components go to `packages/auravibes_ui/` |
| IV. UI Kit Mandate | ✅ PASS | Uses design tokens, follows atomic design |
| V. Test-Driven Development | ✅ PASS | Widget tests required before implementation |
| VI. Fail Fast + Explicit Errors | ✅ PASS | Components use explicit callbacks, no silent failures |
| VII. Simplicity + YAGNI | ✅ PASS | Only widgets currently used in app |
| VIII. Observability + Performance | ✅ PASS | Standard Flutter performance expectations |
| IX. Security + Privacy | ✅ PASS | N/A - UI components only |
| X. Code Quality Standards | ✅ PASS | very_good_analysis, dart format, dartdoc required |

**Gate Status**: ✅ ALL GATES PASS - Proceed to Phase 0

## Project Structure

### Documentation (this feature)

```text
specs/001-ui-library-widgets/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md          # Phase 0 output - Widget patterns research
├── data-model.md        # Phase 1 output - Component data models
├── quickstart.md        # Phase 1 output - Usage examples
├── contracts/           # Phase 1 output - API contracts
│   └── widget-apis.md   # Widget constructor signatures
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
packages/auravibes_ui/
├── lib/
│   ├── ui.dart                          # Main export file (UPDATE)
│   └── src/
│       ├── atoms/
│       │   ├── atoms.dart               # Export file (UPDATE)
│       │   ├── auravibes_selectable_text.dart  # NEW (P3)
│       │   └── auravibes_tooltip.dart          # NEW (P3)
│       ├── molecules/
│       │   ├── molecules.dart           # Export file (UPDATE)
│       │   ├── auravibes_button.dart    # UPDATE: Add text variant
│       │   ├── auravibes_radio.dart     # NEW (P2)
│       │   └── auravibes_snackbar.dart  # NEW (P2)
│       └── organisms/
│           ├── organisms.dart           # Export file (UPDATE)
│           ├── auravibes_dialog.dart    # NEW (P1)
│           └── auravibes_radio_group.dart # NEW (P2)
└── test/
    ├── atoms/
    │   ├── auravibes_selectable_text_test.dart  # NEW
    │   └── auravibes_tooltip_test.dart          # NEW
    ├── molecules/
    │   ├── auravibes_button_text_test.dart      # NEW
    │   ├── auravibes_radio_test.dart            # NEW
    │   └── auravibes_snackbar_test.dart         # NEW
    └── organisms/
        ├── auravibes_dialog_test.dart           # NEW
        └── auravibes_radio_group_test.dart      # NEW
```

**Structure Decision**: All components go to `packages/auravibes_ui/` following atomic design:
- **Atoms**: Tooltip, SelectableText (basic building blocks)
- **Molecules**: Radio, SnackBar (composed of atoms)
- **Organisms**: Dialog, RadioGroup (complex compositions)
- **Updated**: AuraButton gets new `text` variant

## Complexity Tracking

> No violations - all gates pass.

## Phase 0: Research Summary

### Widget Design Patterns

**Decision**: Use Flutter Material widgets as internal implementation with Aura styling wrappers
**Rationale**: 
- Maintains consistent platform behavior (accessibility, gestures)
- Reduces implementation complexity
- Allows focus on styling/API design rather than reinventing interactions

**Alternatives considered**:
- Custom implementations: Rejected - too much complexity for standard widgets
- Third-party packages: Rejected - creates external dependencies for core UI

### Const-First Design Pattern

**Decision**: All color parameters use `AuraColorVariant` enum, resolved via `context.auraColors.getColor()`
**Rationale**: Matches existing STYLE_GUIDE.md requirements
**Pattern**:
```dart
class AuraWidget extends StatelessWidget {
  final AuraColorVariant? colorVariant;
  
  const AuraWidget({this.colorVariant}); // const-compatible
  
  @override
  Widget build(BuildContext context) {
    final color = context.auraColors.getColor(colorVariant) ?? context.auraColors.primary;
    // use color
  }
}
```

### Dialog Architecture

**Decision**: Provide both widget and helper function patterns
- `AuraConfirmDialog` / `AuraAlertDialog` widgets for composition
- `showAuraDialog()` / `showAuraConfirmDialog()` helpers for imperative use
**Rationale**: Matches Flutter's `showDialog` pattern while providing Aura styling

### Radio State Management

**Decision**: Use Flutter's built-in `Radio` semantics with custom styling via wrapper
**Rationale**: 
- Maintains accessibility (screen readers understand radio groups)
- Follows Material Design guidelines for radio behavior
- Custom styling via Aura design tokens

### SnackBar Integration

**Decision**: Wrap `ScaffoldMessenger.showSnackBar` with `showAuraSnackBar()` helper
**Rationale**: 
- Maintains standard snackbar positioning and behavior
- Adds Aura styling via `SnackBar` theme customization
- Provides convenient API with semantic variants

## Phase 1: Component Contracts

### AuraButton.text Variant

```dart
// Add to existing AuraButton
enum AuraButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  elevated,
  text,  // NEW - transparent background, no border
}

// Text variant styling:
// - Transparent background
// - No border
// - Text color from colorVariant or primary
// - No padding by default (inline use)
```

### AuraConfirmDialog

```dart
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
  
  final Widget title;
  final Widget message;
  final Widget? confirmLabel;
  final Widget? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final AuraColorVariant? colorVariant;
}

// Helper function
Future<bool?> showAuraConfirmDialog({
  required BuildContext context,
  required Widget title,
  required Widget message,
  Widget? confirmLabel,
  Widget? cancelLabel,
  bool isDestructive = false,
  AuraColorVariant? colorVariant,
});
```

### AuraAlertDialog

```dart
class AuraAlertDialog extends StatelessWidget {
  const AuraAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.dismissLabel,
    this.colorVariant,
  });
  
  final Widget title;
  final Widget message;
  final Widget? dismissLabel;
  final AuraColorVariant? colorVariant;
}

// Helper function
Future<void> showAuraAlertDialog({
  required BuildContext context,
  required Widget title,
  required Widget message,
  Widget? dismissLabel,
  AuraColorVariant? colorVariant,
});
```

### AuraSnackBar

```dart
enum AuraSnackBarVariant {
  default_,
  success,
  error,
  warning,
  info,
}

ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAuraSnackBar({
  required BuildContext context,
  required Widget content,
  AuraSnackBarVariant variant = AuraSnackBarVariant.default_,
  Duration duration = const Duration(seconds: 4),
  Widget? actionLabel,
  VoidCallback? onAction,
});
```

### AuraRadio & AuraRadioGroup

```dart
class AuraRadio<T> extends StatelessWidget {
  const AuraRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.colorVariant,
    this.disabled = false,
  });
  
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final AuraColorVariant? colorVariant;
  final bool disabled;
}

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
  
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<AuraRadioOption<T>> options;
  final Widget? label;
  final Axis direction;
  final AuraColorVariant? colorVariant;
}

class AuraRadioOption<T> {
  const AuraRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
  });
  
  final T value;
  final Widget label;
  final Widget? subtitle;
}
```

### AuraRadioListTile

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
  
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget title;
  final Widget? subtitle;
  final AuraColorVariant? colorVariant;
  final bool disabled;
}
```

### AuraTooltip

```dart
class AuraTooltip extends StatelessWidget {
  const AuraTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
    this.colorVariant,
  });
  
  final String message;
  final Widget child;
  final bool preferBelow;
  final AuraColorVariant? colorVariant;
}
```

### AuraSelectableText

```dart
class AuraSelectableText extends StatelessWidget {
  const AuraSelectableText(
    this.data, {
    super.key,
    this.style,
    this.colorVariant,
    this.textAlign,
    this.maxLines,
  });
  
  final String data;
  final TextStyle? style;
  final AuraColorVariant? colorVariant;
  final TextAlign? textAlign;
  final int? maxLines;
}
```

## Implementation Phases

### Phase 1: P1 Components (Critical)

1. **AuraButton.text variant**
   - Add `text` to `AuraButtonVariant` enum
   - Update `_getBackgroundColor()`, `_getForegroundColor()`, `_getBorder()`
   - Add padding adjustments for text variant (minimal)
   - Widget tests for text variant

2. **AuraConfirmDialog / AuraAlertDialog**
   - Create `auravibes_dialog.dart` in organisms
   - Implement `AuraConfirmDialog` widget
   - Implement `AuraAlertDialog` widget
   - Create `showAuraConfirmDialog()` helper
   - Create `showAuraAlertDialog()` helper
   - Widget tests for both dialog types

### Phase 2: P2 Components (Important)

3. **AuraSnackBar**
   - Create `auravibes_snackbar.dart` in molecules
   - Implement `showAuraSnackBar()` helper
   - Define `AuraSnackBarVariant` enum
   - Widget tests

4. **AuraRadio / AuraRadioGroup / AuraRadioListTile**
   - Create `auravibes_radio.dart` in molecules
   - Create `auravibes_radio_group.dart` in organisms
   - Implement `AuraRadio` widget
   - Implement `AuraRadioGroup` widget
   - Implement `AuraRadioListTile` widget
   - Define `AuraRadioOption<T>` class
   - Widget tests

### Phase 3: P3 Components (Nice-to-have)

5. **AuraTooltip**
   - Create `auravibes_tooltip.dart` in atoms
   - Wrap Material `Tooltip` with Aura styling
   - Widget tests

6. **AuraSelectableText**
   - Create `auravibes_selectable_text.dart` in atoms
   - Wrap Material `SelectableText` with Aura styling
   - Widget tests

## Testing Strategy

### Widget Tests (Required for each component)

```dart
// Test structure for each widget
group('AuraWidgetName', () {
  testWidgets('renders with required parameters', (tester) async {
    // Pump widget with minimal config
    // Verify widget appears in tree
  });
  
  testWidgets('applies colorVariant correctly', (tester) async {
    // Pump widget with specific AuraColorVariant
    // Verify colors match theme expectations
  });
  
  testWidgets('handles disabled state', (tester) async {
    // Pump widget with disabled: true
    // Verify opacity/greyed out appearance
    // Verify no response to taps
  });
  
  testWidgets('responds to user interaction', (tester) async {
    // Pump interactive widget
    // Simulate tap/gesture
    // Verify callback invoked
  });
});
```

### Coverage Requirements

- Each component: 80%+ line coverage
- All color variants tested
- All states (disabled, loading) tested
- Edge cases (empty content, long text) tested

## Migration Path

After implementation, migrate app usages:

1. **Dialogs** (15+ usages):
   - `tools_group_card.dart` - delete MCP confirmation
   - `conversation_tools_group_card.dart` - confirmation dialogs
   - `settings_screen.dart` - theme selection
   - `add_mcp_modal.dart`, `add_tool_modal.dart` - form dialogs
   - `tool_item_row.dart`, `list_model_credentials.dart` - confirmations

2. **TextButton** (12+ usages):
   - Replace `TextButton` with `AuraButton(variant: AuraButtonVariant.text)`
   - Replace `TextButton.styleFrom(foregroundColor: error)` with `colorVariant: AuraColorVariant.error`

3. **SnackBar** (2 usages):
   - `add_mcp_modal.dart` - success notification
   - `new_chat_screen.dart` - error notification

4. **RadioListTile** (3 usages):
   - `settings_screen.dart` - theme selection

5. **Tooltip** (2 usages):
   - `tools_group_header.dart`, `conversation_group_header.dart`

6. **SelectableText** (2 usages):
   - `tools_group_card.dart`, `conversation_tools_group_card.dart` - error messages

## Dependencies

- **Existing**: `AuraColorVariant`, `AuraColorScheme`, `AuraTypographyTheme`, `AuraSpacingTheme`
- **No new dependencies**: All widgets use Flutter SDK + existing design tokens

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Dialog styling inconsistency with Material | Medium | Medium | Use Material Dialog internally, apply Aura theming |
| SnackBar requires Scaffold ancestor | Low | Low | Document requirement, provide clear error messages |
| Radio group state management complexity | Low | Medium | Follow Flutter RadioGroup patterns exactly |
| Const compatibility issues | Low | High | Review each component against STYLE_GUIDE.md |
