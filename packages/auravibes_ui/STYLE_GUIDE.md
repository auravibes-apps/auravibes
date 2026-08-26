# AuraVibes UI - Const-First Design Style Guide

## Overview

This guide establishes the **const-first design pattern** for the AuraVibes UI component library. Use enums for semantic choices and resolve them from the active Aura theme at build time. This preserves const-friendly APIs without pretending every low-level rendering primitive can accept an enum.

## Core Principle

**Components should use const-compatible selectors (`AuraTint`) for semantic accent colors.** Runtime colors remain valid for low-level primitives whose job is to render a resolved interaction layer.

### What This Means

- ✅ **Use Enums**: Component parameters use enum variants (e.g., `AuraTint.primary`)
- ✅ **Const-Friendly APIs**: Semantic styling choices are compile-time values;
  theme colors resolve at build time
- ✅ **Type Safety**: Invalid color values are caught at compile time, not runtime
- ❌ **No Runtime Colors**: Avoid passing `Color` objects to semantic component APIs
- ❗ **Exceptions**: `children`, title widgets, dropdown lists, and low-level
  primitives such as `AuraPressable.color` can be variable

## Pattern: Color Parameters

### ❌ Anti-Pattern (Before)

```dart
class MyWidget extends StatelessWidget {
  final Color? backgroundColor;
  
  const MyWidget({
    this.backgroundColor, // ❌ Runtime Color value
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Theme.of(context).primaryColor,
    );
  }
}

// Usage - requires runtime Color object
MyWidget(
  backgroundColor: Colors.red, // ❌ Not const-compatible
)
```

### ✅ Pattern (After)

```dart
class MyWidget extends StatelessWidget {
  final AuraTint? tint;
  
  const MyWidget({
    this.tint, // ✅ Const-compatible enum
  });
  
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    return Container(
      color: tint == null ? null : auraColors.colorFor(tint!),
    );
  }
}

// Usage - compile-time constant
const MyWidget(
  tint: AuraTint.primary, // ✅ Const-compatible
)
```

## Implementation Details

### 1. Enum-Based Color System

Use `AuraTint` for semantic accent parameters:

```dart
enum AuraTint {
  primary,
  secondary,
  tertiary,
  error,
  success,
  warning,
  info,
}
```

### 2. Theme Resolution

Colors are resolved from tints via `AuraColorScheme.colorFor()`:

```dart
Color colorFor(AuraTint tint) {
  return switch (tint) {
    AuraTint.primary => primary,
    AuraTint.secondary => secondary,
    AuraTint.tertiary => tertiary,
    AuraTint.error => error,
    AuraTint.success => success,
    AuraTint.warning => warning,
    AuraTint.info => info,
  };
}
```

`colorFor()` returns an opaque resolved color:

```dart
final color = auraColors.colorFor(AuraTint.primary);
```

### 3. Component Implementation

When implementing components:

1. **Declare enum parameters**:
   ```dart
   final AuraTint? tint;
   ```

2. **Resolve colors in build method**:
   ```dart
     @override
     Widget build(BuildContext context) {
       final auraColors = context.auraColors;
       final color = tint == null ? null : auraColors.colorFor(tint!);
       // Use color...
     }
   ```

3. **Pass enums to child components**:
   ```dart
   AuraIcon(
     icon,
     tint: AuraTint.primary, // ✅ Pass enum, not Color
   )
   ```

### 4. Handling Opacity Modifications

For states requiring opacity (disabled, hover, etc.):

**Option 1**: Keep opacity logic in parent component (for Text widgets)
```dart
Color _getTextColor(AuraColorScheme auraColors) {
  if (onTap == null) {
    return auraColors.onSurfaceVariant.withValues(alpha: 0.6);
  }
  return auraColors.primary;
}
```

**Option 2**: Add opacity-specific enum variants only when a repeated semantic
state needs a named design token.
```dart
enum AuraTint {
  // ... existing variants
  // Add a named tint only for a repeated semantic state.
}
```

## Interactive State Contract

Aura interaction is a state layer over a component's persistent decoration.
`AuraPressable.color` is the resolved, opaque base hue for that layer; its
alpha is intentionally ignored. The primitive owns these values:

- inactive: transparent state layer;
- hover or keyboard focus: 8% base-color layer;
- pressed: 16% base-color layer;
- focus: a visible 2px Aura focus ring outside the target.

Do not pass `primary.withValues(alpha: ...)` to `AuraPressable.color`. That
reintroduces the old bug where the primitive applied opacity to an already
transparent color: an opaque color became 50% on hover and 100% while pressed,
while a pre-dimmed color became too faint. Pass the opaque theme color and put
any persistent surface fill in `decoration`.

### Tabs

`AuraTabs` is a static compositional control. Each item owns a title and child;
selection changes content and calls the callback. It does not route, load,
persist, or bind server data.

For the underline-tab pattern:

- accept each title as a widget so callers can compose text, icons, or other
  Aura content; provide `semanticLabel` when a custom title has no useful
  semantics;
- use a 48px minimum tab target (`AuraSpacing.xl2`), including padding;
- keep inactive tab backgrounds transparent;
- keep hover/focus/pressed layers inside each tab target;
- use `AuraBorderRadius.md` (6px) for the state layer;
- use primary text plus a 2px primary underline for the selected tab;
- use one 1px divider below the complete tab strip;
- do not draw a border around each tab or turn its whole area into a filled
  pill;
- keep selected state persistent while hover remains transient. Hovering
  `Details` must not select it when `Activity` is selected.

The indicator must have an explicit width bounded by its tab. A widthless
indicator placed as a child of an unbounded horizontal `Row` can collapse to
zero, producing a selected tab with no visible underline. Use a bounded
`Stack`/`Positioned(left: 0, right: 0, bottom: 0)` (or an equivalent layout)
and keep the indicator separate from the hit target so it cannot intercept
pointer input.

## Validation Checklist

Before completing an interactive component:

1. Inspect the primitive implementation and all callers for duplicated alpha,
   decoration, focus, and hit-target behavior.
2. Test inactive, hovered, pressed, focused, and selected states, including an
   inactive hovered tab while another tab is selected.
3. Assert content and callback changes, invalid/empty input behavior, semantic
   role/selected state, keyboard activation, minimum target size, and visible
   indicator geometry.
4. Render the Widgetbook story and inspect spacing, contrast, radius, borders,
   and state bounds. Do not infer visual correctness from a passing build.
5. Keep component visuals on Aura primitives and tokens. Do not introduce
   Material `TabBar`/`TabBarView` styling merely because their API is familiar.

## Components Checklist

All components must follow this pattern:

- [x] **AuraContainer** - Uses `variant: AuraContainerVariant`
- [x] **AuraAvatar** - Uses Aura semantic selectors where applicable
- [x] **AuraIcon** - Uses `tint: AuraTint?`
- [x] **AuraIconButton** - Uses Aura semantic selectors where applicable
- [x] **AuraDivider** - Uses Aura semantic selectors where applicable
- [x] **AuraFloatingActionButton** - Uses Aura semantic selectors where applicable
- [x] **AuraButton** - Uses Aura semantic selectors where applicable
- [x] **AuraBadge** - Uses variant enums
- [x] **AuraText** - Uses `tint: AuraTint?`

## Testing Guidelines

When testing const-first components:

1. **Use enum values in tests**:
   ```dart
   const customTint = AuraTint.error;
   
   await tester.pumpWidget(
     MaterialApp(
       home: AuraIcon(
         Icons.star,
         tint: customTint,
       ),
     ),
   );
   ```

2. **Verify color is resolved**:
   ```dart
   final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
   expect(iconWidget.color, isNotNull); // Color is resolved from enum
   ```

3. **Don't test for exact resolved Color equality unless testing a token contract**:
   ```dart
   // ❌ Bad - tests implementation details
   expect(iconWidget.color, Colors.red);
   
   // ✅ Good - tests behavior
   expect(iconWidget.color, isNotNull);
   ```

## Benefits

1. **Performance**: Compile-time constants enable better tree-shaking and optimization
2. **Type Safety**: Invalid colors caught at compile time
3. **Maintainability**: Centralized color management through theme
4. **Consistency**: Enforces use of design system colors
5. **Refactoring**: Easy to change color palette without touching component code

## Migration Guide

When encountering a semantic `Color?` parameter in a component:

1. **Identify the parameter**: Find all `Color?` parameters
2. **Replace with selector**: Change it to `AuraTint?` when the value is a
   semantic accent
3. **Update build method**: Resolve the tint using `auraColors.colorFor()`
4. **Fix consumers**: Update all usages to pass enum values
5. **Update tests**: Change test color constants to enum values
6. **Run analysis**: Verify with `dart analyze`

Do not mechanically migrate low-level rendering APIs. `AuraPressable.color`
must remain a resolved `Color` because it applies interaction alpha at render
time; pass it an opaque theme color.

## Example Migration

```dart
// Before
class AuraContainer extends StatelessWidget {
  final Color? backgroundColor;
  
  const AuraContainer({
    this.backgroundColor,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: child,
    );
  }
}

// After: semantic selector on a component
class AuraAccent extends StatelessWidget {
  final AuraTint? tint;
  final Widget child;
  
  const AuraAccent({
    this.tint,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    return Container(
      color: tint == null ? null : auraColors.colorFor(tint!),
      child: child,
    );
  }
}
```

## Custom Implementation Guidelines

When implementing Aura widgets, prefer full custom implementations over wrapping Material widgets:

### ✅ Custom Approach (Preferred)

- Use `CustomPaint` for custom graphics (radio buttons, checkboxes)
- Use `OverlayEntry` for floating widgets (tooltips, snackbars, dialogs)
- Use `GestureDetector` for custom interactions
- Use `AnimatedContainer`/`AnimationController` for animations
- Use `showGeneralDialog` for custom dialogs instead of `AlertDialog`

### ❌ Avoid Material Wrappers

The following Material widgets introduce styling that conflicts with Aura aesthetics and should be avoided:

| Material Widget | Custom Alternative |
|----------------|-------------------|
| `Tooltip` | Custom `OverlayEntry` with `Positioned` |
| `SnackBar` | Custom `OverlayEntry` with animations |
| `AlertDialog` | Custom `showGeneralDialog` with `Container` |
| `Radio` | Custom `CustomPaint` circles |
| `RadioListTile` | Custom `GestureDetector` + `AuraRadio` + layout |
| `SelectableText` | Acceptable - wraps complex text selection |

### Implementation Examples

**Custom Radio Button:**
```dart
class AuraRadio<T> extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(value),
      child: CustomPaint(
        painter: _AuraRadioPainter(isSelected: isSelected),
      ),
    );
  }
}
```

**Custom Dialog:**
```dart
Future<bool?> showAuraConfirmDialog(...) {
  return showGeneralDialog<bool>(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AuraDialog(/* ... */);
    },
  );
}
```

**Custom SnackBar:**
```dart
void showAuraSnackBar(...) {
  final entry = OverlayEntry(
    builder: (context) => _AuraSnackBar(/* ... */),
  );
  Overlay.of(context).insert(entry);
}
```

## References

- Flutter const optimization: https://api.flutter.dev/flutter/dart-core/const.html
- `AuraTint`, spacing, radius, and border definitions:
  `lib/src/tokens/design_tokens.dart`
- Aura color scheme implementation: `lib/src/tokens/aura_theme.dart`

---

**Last Updated**: 2026-08-26
**Version**: 1.2.0
