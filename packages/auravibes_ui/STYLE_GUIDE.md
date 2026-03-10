# AuraVibes UI - Const-First Design Style Guide

## Overview

This guide establishes the **const-first design pattern** for the AuraVibes UI component library. The goal is to maximize compile-time constants by using enums instead of runtime `Color` values, enabling better performance, type safety, and maintainability.

## Core Principle

**Components should only accept const-compatible parameters (enums), not runtime `Color` values.**

### What This Means

- ✅ **Use Enums**: Component parameters use enum variants (e.g., `AuraColorVariant.primary`)
- ✅ **Compile-Time Constants**: All styling decisions are made at compile time
- ✅ **Type Safety**: Invalid color values are caught at compile time, not runtime
- ❌ **No Runtime Colors**: Avoid passing `Color` objects directly to components
- ❗ **Exception**: `children` and dropdown lists can be variable

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
  final AuraColorVariant? backgroundColor;
  
  const MyWidget({
    this.backgroundColor, // ✅ Const-compatible enum
  });
  
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    return Container(
      color: auraColors.getColor(backgroundColor) ?? auraColors.primary,
    );
  }
}

// Usage - compile-time constant
const MyWidget(
  backgroundColor: AuraColorVariant.primary, // ✅ Const-compatible
)
```

## Implementation Details

### 1. Enum-Based Color System

Use `AuraColorVariant` enum for all color parameters:

```dart
enum AuraColorVariant {
  // Core colors
  primary,
  onPrimary,
  secondary,
  onSurface,
  onSurfaceVariant,
  surfaceVariant,
  error,
  // Semantic colors
  success,
  warning,
  info,
}
```

### 2. Theme Resolution

Colors are resolved from enums via `AuraColorScheme.getColor()`:

```dart
Color? getColor(AuraColorVariant? variant) {
  return switch (variant) {
    null => null,
    AuraColorVariant.primary => primary,
    AuraColorVariant.onSurface => onSurface,
    AuraColorVariant.onSurfaceVariant => onSurfaceVariant,
    AuraColorVariant.surfaceVariant => surfaceVariant,
    AuraColorVariant.error => error,
    AuraColorVariant.onPrimary => onPrimary,
    AuraColorVariant.secondary => secondary,
    AuraColorVariant.success => success,
    AuraColorVariant.warning => warning,
    AuraColorVariant.info => info,
  };
}
```

**Note**: `getColor()` returns `Color?` - always provide a fallback when using:

```dart
final color = auraColors.getColor(variant) ?? auraColors.primary;
```

### 3. Component Implementation

When implementing components:

1. **Declare enum parameters**:
   ```dart
   final AuraColorVariant? backgroundColor;
   final AuraColorVariant? foregroundColor;
   ```

2. **Resolve colors in build method**:
   ```dart
   @override
   Widget build(BuildContext context) {
     final auraColors = context.auraColors;
     final bgColor = auraColors.getColor(backgroundColor) ?? auraColors.primary;
     // Use bgColor...
   }
   ```

3. **Pass enums to child components**:
   ```dart
   AuraIcon(
     icon,
     color: AuraColorVariant.primary, // ✅ Pass enum, not Color
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

**Option 2**: Add opacity-specific enum variants (future enhancement)
```dart
enum AuraColorVariant {
  // ... existing variants
  onSurfaceVariantDisabled, // Maps to onSurfaceVariant with 0.6 opacity
}
```

## Components Checklist

All components must follow this pattern:

- [x] **AuraContainer** - `backgroundColor: AuraColorVariant?`
- [x] **AuraAvatar** - `backgroundColor`, `foregroundColor: AuraColorVariant?`
- [x] **AuraIcon** - `color: AuraColorVariant?`
- [x] **AuraIconButton** - `color`, `backgroundColor: AuraColorVariant?`
- [x] **AuraDivider** - `color: AuraColorVariant?`
- [x] **AuraFloatingActionButton** - `backgroundColor`, `foregroundColor: AuraColorVariant?`
- [x] **AuraButton** - Uses `AuraColorVariant` enum
- [x] **AuraBadge** - Uses variant enums
- [x] **AuraText** - Uses `AuraColorVariant` enum

## Testing Guidelines

When testing const-first components:

1. **Use enum values in tests**:
   ```dart
   const customColor = AuraColorVariant.error;
   
   await tester.pumpWidget(
     const MaterialApp(
       home: AuraIcon(
         Icons.star,
         color: customColor,
       ),
     ),
   );
   ```

2. **Verify color is resolved**:
   ```dart
   final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
   expect(iconWidget.color, isNotNull); // Color is resolved from enum
   ```

3. **Don't test for exact Color equality**:
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

When encountering `Color?` parameters in components:

1. **Identify the parameter**: Find all `Color?` parameters
2. **Replace with enum**: Change `Color?` to `AuraColorVariant?`
3. **Update build method**: Resolve color using `auraColors.getColor()`
4. **Fix consumers**: Update all usages to pass enum values
5. **Update tests**: Change test color constants to enum values
6. **Run analysis**: Verify with `dart analyze`

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

// After
class AuraContainer extends StatelessWidget {
  final AuraColorVariant? backgroundColor;
  
  const AuraContainer({
    this.backgroundColor,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    return Container(
      color: auraColors.getColor(backgroundColor),
      child: child,
    );
  }
}
```

## References

- Flutter const optimization: https://api.flutter.dev/flutter/dart-core/const.html
- AuraColorVariant definition: `lib/src/tokens/design_tokens.dart`
- AuraColorScheme implementation: `lib/src/tokens/auravibes_theme.dart`

---

**Last Updated**: 2026-03-09  
**Version**: 1.0.0
