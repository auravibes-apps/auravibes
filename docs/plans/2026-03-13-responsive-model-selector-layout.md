# Responsive Model Selector Layout Design

> **Date**: 2026-03-13
> **Branch**: 001-two-step-model-selector
> **Status**: Approved

## Problem

When the app is on mobile or desktop with a narrow horizontal width, the two-step model selector text wraps into multiple lines. Instead of expanding downward, it shrinks the header content, causing the title and left button to be cut off vertically.

## Solution

Implement a responsive layout with three breakpoints using existing `DesignBreakpoints` tokens:

| Width | Layout | Text Behavior |
|-------|--------|---------------|
| **≥ 768px** (`md`) | Side-by-side in `appBar.bottom` | Truncate long names with ellipsis |
| **640-768px** (`sm`-`md`) | Stacked vertically in `appBar.bottom` | Truncate long names with ellipsis |
| **< 640px** (`sm`) | Move to body content (below AppBar) | Full text, natural wrapping |

## Architecture

### Layout Decision Flow

```
Screen Width Check
       │
       ├─≥768px──► Side-by-side in appBar.bottom
       │
       ├─640-768px─► Stacked in appBar.bottom
       │
       └─<640px──► Selector in body content
```

### Components Modified

| File | Package | Change |
|------|---------|--------|
| `new_chat_screen.dart` | auravibes_app | Conditionally place selector in body vs appBar.bottom |
| `select_chat_model.dart` | auravibes_app | Add responsive Row/Column switching, text truncation |
| `auravibes_dropdown_selector.dart` | auravibes_ui | Add `maxLines: 1` + `overflow: TextOverflow.ellipsis` |

## Technical Details

### 1. new_chat_screen.dart

```dart
final screenWidth = MediaQuery.of(context).size.width;
final isSmallScreen = screenWidth < DesignBreakpoints.sm; // <640px

return AuraScreen(
  appBar: AuraAppBarWithDrawer(
    title: ...,
    bottom: isSmallScreen 
      ? null  // Selector moves to body on mobile
      : SelectCredentialsModelWidget(...),
  ),
  child: Column(
    children: [
      if (isSmallScreen) 
        SelectCredentialsModelWidget(...), // In body on mobile
      Expanded(child: ChatInputWidget(...)),
    ],
  ),
);
```

### 2. select_chat_model.dart

```dart
final screenWidth = MediaQuery.of(context).size.width;
final isCompact = screenWidth < DesignBreakpoints.md; // <768px

return isCompact
    ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProviderDropdown(...),
          SizedBox(height: DesignSpacing.sm),
          _ModelDropdown(...),
        ],
      )
    : Row(
        children: [
          Expanded(child: _ProviderDropdown(...)),
          SizedBox(width: DesignSpacing.sm),
          Expanded(child: _ModelDropdown(...)),
        ],
      );
```

### 3. auravibes_dropdown_selector.dart

In `_DropdownMenuState` option builder and `_getDisplayText()`:

```dart
Text(
  name,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

## Visual Reference

```
≥768px (Desktop/Tablet landscape):
┌─────────────────────────────────────────────┐
│ ☰  Start New Chat              [Actions]    │
├─────────────────────────────────────────────┤
│ [OpenAI ▼]  [gpt-4o-mini ▼]                 │  ← appBar.bottom
├─────────────────────────────────────────────┤
│                                             │
│            [Chat Input]                     │
│                                             │
└─────────────────────────────────────────────┘

640-768px (Tablet portrait):
┌────────────────────────────────┐
│ ☰  Start New Chat    [Actions] │
├────────────────────────────────┤
│ [OpenAI ▼]                     │  ← appBar.bottom (stacked)
│ [gpt-4o-mini ▼]                │
├────────────────────────────────┤
│                                │
│       [Chat Input]             │
│                                │
└────────────────────────────────┘

<640px (Mobile):
┌──────────────────────┐
│ ☰  Start New Chat    │
├──────────────────────┤
│                      │
│ [OpenAI ▼]           │  ← Body content
│ [gpt-4o-mini ▼]      │
│                      │
│   [Chat Input]       │
│                      │
└──────────────────────┘
```

## Testing

1. **Desktop wide (≥1024px)**: Side-by-side layout
2. **Tablet landscape (768-1024px)**: Side-by-side layout
3. **Tablet portrait (640-768px)**: Stacked layout in appBar
4. **Mobile (<640px)**: Selector in body content
5. **Long model names**: Verify truncation with ellipsis
6. **Screen rotation**: Layout rebuilds correctly

## Dependencies

- `DesignBreakpoints` from `auravibes_ui` (already exists)
- `MediaQuery` from Flutter (already used)
- No new dependencies required
