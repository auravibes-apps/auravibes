# Research: UI Library Widget Expansion

**Feature**: 001-ui-library-widgets
**Date**: 2026-03-11
**Status**: Complete

## Research Questions

### Q1: Should we wrap Material widgets or create custom implementations?

**Decision**: Wrap Material widgets with Aura styling

**Rationale**:
- Material widgets provide battle-tested accessibility (screen readers, semantics)
- Platform conventions (tap targets, gesture recognition) work out of the box
- Focus management and keyboard navigation handled automatically
- Less code to maintain, faster implementation
- Can customize appearance via theming

**Alternatives Considered**:
1. **Custom implementations**: Would require re-implementing accessibility, focus management, gesture detection. Too much effort for standard widgets.
2. **Third-party packages**: Creates external dependency for core functionality. Not worth the risk.

**Implementation Pattern**:
```dart
class AuraConfirmDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.auraColors.surface,
      title: title,
      content: message,
      actions: [
        AuraButton(variant: AuraButtonVariant.text, ...),
        AuraButton(variant: AuraButtonVariant.text, colorVariant: AuraColorVariant.error, ...),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.lg),
      ),
    );
  }
}
```

---

### Q2: How to handle const-compatibility with AuraColorVariant?

**Decision**: Resolve colors at build time using `context.auraColors.getColor()`

**Rationale**:
- Matches existing STYLE_GUIDE.md pattern
- All components remain const-constructible
- Color resolution happens in build() which has context access
- Type-safe: invalid variants caught at compile time

**Pattern**:
```dart
class AuraWidget extends StatelessWidget {
  final AuraColorVariant? colorVariant;
  
  // Constructor is const-compatible
  const AuraWidget({
    super.key,
    this.colorVariant,
  });
  
  @override
  Widget build(BuildContext context) {
    // Resolve color at build time
    final color = context.auraColors.getColor(colorVariant) 
        ?? context.auraColors.primary;
    
    return ColoredBox(color: color);
  }
}
```

**Key Points**:
- Never accept `Color?` as parameter - always `AuraColorVariant?`
- Always provide fallback in `getColor()` call
- Document the default color in dartdoc

---

### Q3: Dialog API - Widget vs Helper Function?

**Decision**: Provide both widget and helper function patterns

**Rationale**:
- Widgets enable composition in complex UIs
- Helper functions match Flutter's `showDialog` pattern
- Developers can choose based on use case
- Both patterns are well-understood in Flutter ecosystem

**Widget Pattern** (for composition):
```dart
showDialog(
  context: context,
  builder: (context) => AuraConfirmDialog(
    title: Text('Delete item?'),
    message: Text('This cannot be undone.'),
    onConfirm: () => handleDelete(),
  ),
);
```

**Helper Function Pattern** (for convenience):
```dart
final confirmed = await showAuraConfirmDialog(
  context: context,
  title: Text('Delete item?'),
  message: Text('This cannot be undone.'),
  isDestructive: true,
);
if (confirmed ?? false) handleDelete();
```

---

### Q4: SnackBar integration with existing ScaffoldMessenger?

**Decision**: Create `showAuraSnackBar()` helper that wraps `ScaffoldMessenger.of(context).showSnackBar()`

**Rationale**:
- ScaffoldMessenger is the Flutter standard for snackbars
- Must have Scaffold ancestor (documented requirement)
- Can customize SnackBar theme globally via Theme
- Helper provides convenient API with Aura variants

**Implementation**:
```dart
ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAuraSnackBar({
  required BuildContext context,
  required Widget content,
  AuraSnackBarVariant variant = AuraSnackBarVariant.default_,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final auraColors = context.auraColors;
  
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: content,
      duration: duration,
      backgroundColor: _getBackgroundColor(auraColors, variant),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction ?? () {},
              textColor: _getForegroundColor(auraColors, variant),
            )
          : null,
    ),
  );
}
```

---

### Q5: Radio state management approach?

**Decision**: Use Flutter's built-in radio semantics with Aura styling

**Rationale**:
- Radio group behavior (mutual exclusivity) is complex to implement correctly
- Screen readers expect standard radio semantics
- Material Radio widget handles all edge cases
- We add Aura styling via wrapper widgets

**Implementation**:
```dart
class AuraRadio<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final AuraColorVariant? colorVariant;
  
  @override
  Widget build(BuildContext context) {
    final color = context.auraColors.getColor(colorVariant) 
        ?? context.auraColors.primary;
    
    return Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: color,
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return context.auraColors.onSurfaceVariant;
        }
        return color;
      }),
    );
  }
}
```

**RadioGroup Pattern**:
```dart
class AuraRadioGroup<T> extends StatelessWidget {
  final T? value;
  final ValueChanged<T?>? onChanged;
  final List<AuraRadioOption<T>> options;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) => 
        AuraRadioListTile<T>(
          value: option.value,
          groupValue: value,
          onChanged: onChanged,
          title: option.label,
          subtitle: option.subtitle,
        ),
      ).toList(),
    );
  }
}
```

---

### Q6: TextButton variant in existing AuraButton?

**Decision**: Add `text` variant to `AuraButtonVariant` enum

**Rationale**:
- Consistent API - all button types use same widget
- Matches Material Design 3 button variants
- Easy migration path: `TextButton(...)` → `AuraButton(variant: AuraButtonVariant.text, ...)`
- Leverages existing styling infrastructure

**Implementation Changes**:
```dart
enum AuraButtonVariant {
  primary,
  secondary,
  outlined,
  ghost,
  elevated,
  text,  // NEW
}

// In AuraButton:
Color _getBackgroundColor(AuraColorScheme colors) {
  return switch (variant) {
    // ... existing cases
    AuraButtonVariant.text => DesignColors.transparent,
  };
}

Color _getForegroundColor(AuraColorScheme colors) {
  return switch (variant) {
    // ... existing cases
    AuraButtonVariant.text => colors.getColor(colorVariant) ?? colors.primary,
  };
}

Border? _getBorder(AuraColorScheme colors) {
  return switch (variant) {
    // ... existing cases
    AuraButtonVariant.text => null,  // No border
  };
}

List<BoxShadow> _getBoxShadow() {
  return switch (variant) {
    // ... existing cases
    AuraButtonVariant.text => [],  // No shadow
  };
}
```

---

### Q7: Tooltip and SelectableText - Simple wrappers?

**Decision**: Yes, simple wrappers with Aura color variants

**Rationale**:
- Material Tooltip and SelectableText work well
- Main customization needed is colors
- Keep implementation minimal

**Tooltip Implementation**:
```dart
class AuraTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final bool preferBelow;
  final AuraColorVariant? colorVariant;
  
  @override
  Widget build(BuildContext context) {
    final bgColor = context.auraColors.getColor(colorVariant) 
        ?? context.auraColors.onSurface;
    
    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(context.auraTheme.borderRadius.sm),
      ),
      textStyle: TextStyle(
        color: context.auraColors.surface,
        fontSize: context.auraTheme.typography.sizes.sm,
      ),
      child: child,
    );
  }
}
```

**SelectableText Implementation**:
```dart
class AuraSelectableText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final AuraColorVariant? colorVariant;
  
  @override
  Widget build(BuildContext context) {
    final color = context.auraColors.getColor(colorVariant) 
        ?? context.auraColors.onSurface;
    
    return SelectableText(
      data,
      style: (style ?? const TextStyle()).copyWith(color: color),
    );
  }
}
```

---

## Summary of Decisions

| Question | Decision | Key Benefit |
|----------|----------|-------------|
| Material wrap vs custom | Wrap Material widgets | Accessibility + less code |
| Const compatibility | Resolve in build() | Type-safe, compile-time checks |
| Dialog API | Widget + helper function | Flexibility for developers |
| SnackBar integration | ScaffoldMessenger wrapper | Standard Flutter pattern |
| Radio state | Material Radio with Aura styling | Correct semantics, Aura look |
| TextButton | Add to AuraButtonVariant | Consistent button API |
| Tooltip/SelectableText | Simple wrappers | Minimal complexity |

All decisions align with:
- STYLE_GUIDE.md const-first design
- Atomic design hierarchy
- Flutter best practices
- Constitution principles (simplicity, testability, user needs)
