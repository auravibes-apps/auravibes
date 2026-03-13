# Custom Aura Widgets Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor 8 Aura widgets from Material wrappers to full custom implementations with Aura aesthetics, removing Material dependency where possible while maintaining Flutter platform behavior.

**Architecture:** Each widget will be reimplemented using Flutter's basic widgets (CustomPaint, GestureDetector, AnimatedContainer, OverlayEntry) with Aura design tokens and colors. Keep Flutter's gesture handling and accessibility, remove Material visual styling.

**Tech Stack:** Flutter (Core widgets only), CustomPaint, OverlayEntry, GestureDetector, AnimationController

---

## Component Overview

| Widget | Current | Target | Difficulty |
|--------|---------|--------|------------|
| AuraTooltip | Wraps Material Tooltip | Custom OverlayEntry | Medium |
| AuraSelectableText | Wraps Material SelectableText | Custom SelectableText.rich | Low |
| showAuraSnackBar | Uses Material SnackBar | Custom OverlayEntry animation | High |
| AuraRadio | Wraps Material Radio | Custom CustomPaint circles | Medium |
| AuraRadioGroup | Uses Material RadioGroup | Custom Row/Column (already custom) | Low |
| AuraRadioListTile | Wraps Material RadioListTile | Custom ListTile + custom Radio | Medium |
| AuraConfirmDialog | Wraps Material AlertDialog | Custom OverlayEntry + animations | High |
| AuraAlertDialog | Wraps Material AlertDialog | Custom OverlayEntry + animations | High |

---

### Task 1: AuraTooltip - Full Custom Implementation

**Files:**
- Modify: `packages/auravibes_ui/lib/src/atoms/auravibes_tooltip.dart`
- Modify: `packages/auravibes_ui/test/src/atoms/auravibes_tooltip_test.dart`
- Modify: `packages/auravibes_ui/lib/src/atoms/atoms.dart` (if needed)

**Step 1: Write failing test**

```dart
// In test file, update to test custom implementation
// Test that it uses OverlayEntry instead of Material Tooltip
test('uses custom overlay instead of Material Tooltip', () {
  await tester.pumpWidget(
    const MaterialApp(
      home: AuraTooltip(
        message: 'Test tooltip',
        child: Text('Hover me'),
      ),
    ),
  );
  
  // Should NOT find Material Tooltip widget
  expect(find.byType(Tooltip), findsNothing);
  
  // Should find custom overlay entry after hover
  await tester.longPress(find.text('Hover me'));
  await tester.pumpAndSettle();
  expect(find.text('Test tooltip'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**
Expected: Test fails because current implementation uses Material Tooltip

**Step 3: Write custom implementation**

```dart
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AuraTooltip extends StatefulWidget {
  const AuraTooltip({
    required this.message,
    required this.child,
    super.key,
    this.colorVariant = AuraColorVariant.onSurface,
    this.showDuration = const Duration(seconds: 2),
    this.waitDuration = Duration.zero,
    this.preferBelow = true,
    this.verticalOffset = 24,
    this.margin = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final String message;
  final Widget child;
  final AuraColorVariant colorVariant;
  final Duration showDuration;
  final Duration waitDuration;
  final bool preferBelow;
  final double verticalOffset;
  final double margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  @override
  State<AuraTooltip> createState() => _AuraTooltipState();
}

class _AuraTooltipState extends State<AuraTooltip> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  late TapGestureRecognizer _tapGestureRecognizer;
  late HoverGestureRecognizer _hoverGestureRecognizer;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    _tapGestureRecognizer = TapGestureRecognizer()..onTapDown = _onTapDown;
    _hoverGestureRecognizer = HoverGestureRecognizer()..onHover = _onHover;
  }

  @override
  void dispose() {
    _hideTooltip();
    _tapGestureRecognizer.dispose();
    _hoverGestureRecognizer.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _showTooltip();
  }

  void _onHover(bool isHovering) {
    if (isHovering) {
      _showTooltip();
    } else {
      _hideTooltip();
    }
  }

  void _showTooltip() {
    if (_isShowing) return;
    _isShowing = true;

    final overlay = Overlay.of(contextBox = context.find);
    final renderRenderObject() as RenderBox;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => _AuraTooltipOverlay(
        message: widget.message,
        position: position,
        size: size,
        colorVariant: widget.colorVariant,
        padding: widget.padding,
        borderRadius: widget.borderRadius,
        preferBelow: widget.preferBelow,
        verticalOffset: widget.verticalOffset,
        margin: widget.margin,
        onDismiss: _hideTooltip,
      ),
    );

    overlay.insert(_overlayEntry!);
    
    // Auto-hide after duration
    Future.delayed(widget.showDuration, () {
      if (_isShowing) _hideTooltip();
    });
  }

  void _hideTooltip() {
    if (!_isShowing) return;
    _isShowing = false;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: widget.child,
      );
    }
  }
}

class _AuraTooltipOverlay extends StatelessWidget {
  final String message;
  final Offset position;
  final Size size;
  final AuraColorVariant colorVariant;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final bool preferBelow;
  final double verticalOffset;
  final double margin;
  final VoidCallback onDismiss;

  const _AuraTooltipOverlay({
    required this.message,
    required this.position,
    required this.size,
    required this.colorVariant,
    required this.padding,
    required this.borderRadius,
    required this.preferBelow,
    required this.verticalOffset,
    required this.margin,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final colors = context.auraColors;
    final backgroundColor = _getBackgroundColor(colors);
    final textColor = _getForegroundColor(colors);

    final tooltipHeight = 36.0; // Estimated
    final topPosition = position.dy - verticalOffset - tooltipHeight;
    final bottomPosition = position.dy + size.height + verticalOffset;
    
    final showAbove = preferBelow 
        ? (topPosition < margin) 
        : true;
    final yPosition = showAbove ? topPosition : bottomPosition;
    
    // Clamp to screen bounds
    final clampedY = yPosition.clamp(margin, screenSize.height - tooltipHeight - margin);
    
    final xPosition = (position.dx + size.width / 2).clamp(
      margin + 50, 
      screenSize.width - margin - 50,
    );

    return Positioned(
      left: xPosition - 50,
      top: clampedY,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Text(
            message,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    return switch (colorVariant) {
      AuraColorVariant.primary => colors.primary,
      AuraColorVariant.secondary => colors.secondary,
      AuraColorVariant.success => colors.success,
      AuraColorVariant.error => colors.error,
      AuraColorVariant.warning => colors.warning,
      AuraColorVariant.info => colors.info,
      AuraColorVariant.surfaceVariant => colors.surfaceVariant,
      AuraColorVariant.onSurface => colors.surface,
      AuraColorVariant.onSurfaceVariant => colors.surfaceVariant,
      AuraColorVariant.onPrimary => colors.primary,
    };
  }

  Color _getForegroundColor(AuraColorScheme colors) {
    return switch (colorVariant) {
      AuraColorVariant.primary => colors.onPrimary,
      AuraColorVariant.secondary => colors.onSecondary,
      AuraColorVariant.success => colors.onSuccess,
      AuraColorVariant.error => colors.onError,
      AuraColorVariant.warning => colors.onWarning,
      AuraColorVariant.info => colors.onInfo,
      AuraColorVariant.surfaceVariant => colors.onSurface,
      AuraColorVariant.onSurface => colors.onSurface,
      AuraColorVariant.onSurfaceVariant => colors.onSurfaceVariant,
      AuraColorVariant.onPrimary => colors.onPrimary,
    };
  }
}
```

**Step 4: Run test to verify it passes**
Expected: PASS - Custom tooltip no longer uses Material Tooltip

**Step 5: Commit**
```bash
git add packages/auravibes_ui/lib/src/atoms/auravibes_tooltip.dart
git commit -m "refactor: custom AuraTooltip with OverlayEntry instead of Material Tooltip"
```

---

### Task 2: AuraSelectableText - Full Custom Implementation

**Files:**
- Modify: `packages/auravibes_ui/lib/src/atoms/auravibes_selectable_text.dart`
- Modify: `packages/auravibes_ui/test/src/atoms/auravibes_selectable_text_test.dart`

**Step 1: Write failing test**

```dart
test('uses SelectableText.rich instead of Material SelectableText', () {
  await tester.pumpWidget(
    const MaterialApp(
      home: AuraSelectableText(
        data: 'Selectable text',
        style: AuraTextStyle.body,
      ),
    ),
  );
  
  // Should use SelectableText.rich (Material), not basic SelectableText
  final selectableText = tester.widget<SelectableText>(find.byType(SelectableText));
  expect(selectableText, isNotNull);
});
```

**Step 2: Run test to verify it fails**
Expected: PASS - already uses SelectableText.rich

**Step 3: Write custom implementation**

Note: This widget is already fairly custom - it wraps SelectableText.rich with Aura typography. The current implementation is acceptable as it uses Material's text selection which is complex to reimplement. Mark as acceptable.

**Step 4: Mark as acceptable - no changes needed**

---

### Task 3: showAuraSnackBar - Full Custom Implementation

**Files:**
- Modify: `packages/auravibes_ui/lib/src/molecules/auravibes_snackbar.dart`
- Modify: `packages/auravibes_ui/test/src/molecules/auravibes_snackbar_test.dart`

**Step 1: Write failing test**

```dart
test('uses custom OverlayEntry instead of Material SnackBar', () async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () {
              showAuraSnackBar(
                context: context,
                content: const Text('Test message'),
                variant: AuraSnackBarVariant.success,
              );
            },
            child: const Text('Show'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();

  // Should NOT use Material SnackBar
  expect(find.byType(SnackBar), findsNothing);
  
  // Should show custom message
  expect(find.text('Test message'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**
Expected: FAIL - currently uses SnackBar

**Step 3: Write custom implementation**

```dart
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:flutter/material.dart';

enum AuraSnackBarVariant {
  default_,
  success,
  error,
  warning,
  info,
}

/// Shows a custom Aura-styled snackbar notification using OverlayEntry.
ScaffoldFeatureController<_AuraSnackBar, void> showAuraSnackBar({
  required BuildContext context,
  required Widget content,
  AuraSnackBarVariant variant = AuraSnackBarVariant.default_,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final controller = _AuraSnackBarController();
  
  final overlay = Overlay.of(context);
  
  final entry = OverlayEntry(
    builder: (ctx) => _AuraSnackBar(
      controller: controller,
      content: content,
      variant: variant,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );
  
  controller._overlayEntry = entry;
  overlay.insert(entry);
  
  return ScaffoldFeatureController<_AuraSnackBar, void>(
    controller,
    () => controller.close(),
  );
}

class _AuraSnackBarController extends ChangeNotifier {
  OverlayEntry? _overlayEntry;
  bool _isClosed = false;
  
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    _overlayEntry?.remove();
    _overlayEntry = null;
    notifyListeners();
  }
}

class _AuraSnackBar extends StatefulWidget {
  final _AuraSnackBarController controller;
  final Widget content;
  final AuraSnackBarVariant variant;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _AuraSnackBar({
    required this.controller,
    required this.content,
    required this.variant,
    required this.duration,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<_AuraSnackBar> createState() => _AuraSnackBarState();
}

class _AuraSnackBarState extends State<_AuraSnackBar> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_animationController);
    
    _animationController.forward();
    
    // Auto-dismiss
    Future.delayed(widget.duration, _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _animationController.reverse().then((_) {
      widget.controller.close();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final backgroundColor = _getBackgroundColor(widget.variant, colors);
    final foregroundColor = _getForegroundColor(widget.variant, colors);

    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(child: DefaultTextStyle(
                    style: TextStyle(color: foregroundColor),
                    child: widget.content,
                  )),
                  if (widget.actionLabel != null && widget.onAction != null)
                    TextButton(
                      onPressed: () {
                        widget.onAction!();
                        _dismiss();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: foregroundColor,
                      ),
                      child: Text(widget.actionLabel!),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(AuraSnackBarVariant variant, AuraColorScheme colors) {
    return switch (variant) {
      AuraSnackBarVariant.default_ => colors.surfaceVariant,
      AuraSnackBarVariant.success => colors.success,
      AuraSnackBarVariant.error => colors.error,
      AuraSnackBarVariant.warning => colors.warning,
      AuraSnackBarVariant.info => colors.info,
    };
  }

  Color _getForegroundColor(AuraSnackBarVariant variant, AuraColorScheme colors) {
    return switch (variant) {
      AuraSnackBarVariant.default_ => colors.onSurfaceVariant,
      AuraSnackBarVariant.success => colors.onSuccess,
      AuraSnackBarVariant.error => colors.onError,
      AuraSnackBarVariant.warning => colors.onWarning,
      AuraSnackBarVariant.info => colors.onInfo,
    };
  }
}
```

**Step 4: Run test to verify it passes**
Expected: PASS - custom snackbar using OverlayEntry

**Step 5: Commit**
```bash
git add packages/auravibes_ui/lib/src/molecules/auravibes_snackbar.dart
git commit -m "refactor: custom showAuraSnackBar with OverlayEntry instead of Material SnackBar"
```

---

### Task 4: AuraRadio - Full Custom Implementation

**Files:**
- Modify: `packages/auravibes_ui/lib/src/molecules/auravibes_radio.dart`
- Modify: `packages/auravibes_ui/test/src/molecules/auravibes_radio_test.dart`

**Step 1: Write failing test**

```dart
test('uses CustomPaint instead of Material Radio', () {
  await tester.pumpWidget(
    MaterialApp(
      home: AuraRadio<String>(
        value: 'option1',
        groupValue: 'option1',
        onChanged: (v) {},
      ),
    ),
  );
  
  // Should NOT use Material Radio widget
  expect(find.byType(Radio<String>), findsNothing);
  
  // Should use CustomPaint for the radio circles
  expect(find.byType(CustomPaint), findsWidgets);
});
```

**Step 2: Run test to verify it fails**
Expected: FAIL - currently uses Material Radio

**Step 3: Write custom implementation**

```dart
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:flutter/material.dart';

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

/// Custom radio button using CustomPaint.
class AuraRadio<T extends Object> extends StatelessWidget {
  const AuraRadio({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
    this.colorVariant,
    this.disabled = false,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final AuraColorVariant? colorVariant;
  final bool disabled;

  bool get _isSelected => value == groupValue;

  Color _getActiveColor(BuildContext context) {
    final auraColors = context.auraColors;
    return switch (colorVariant) {
      AuraColorVariant.primary => auraColors.primary,
      AuraColorVariant.secondary => auraColors.secondary,
      AuraColorVariant.onSurface => auraColors.onSurface,
      AuraColorVariant.onSurfaceVariant => auraColors.onSurfaceVariant,
      AuraColorVariant.surfaceVariant => auraColors.surfaceVariant,
      AuraColorVariant.error => auraColors.error,
      AuraColorVariant.onPrimary => auraColors.onPrimary,
      AuraColorVariant.success => auraColors.success,
      AuraColorVariant.warning => auraColors.warning,
      AuraColorVariant.info => auraColors.info,
      null => auraColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnChanged = (disabled || onChanged == null)
        ? null
        : (T? v) => onChanged!(v);
    
    final activeColor = _getActiveColor(context);
    final isDisabled = disabled || onChanged == null;

    return GestureDetector(
      onTap: effectiveOnChanged != null 
          ? () => effectiveOnChanged(value)
          : null,
      child: MouseRegion(
        cursor: isDisabled 
            ? SystemMouseCursors.forbidden 
            : SystemMouseCursors.click,
        child: SizedBox(
          width: 24,
          height: 24,
          child: CustomPaint(
            painter: _AuraRadioPainter(
              isSelected: _isSelected,
              activeColor: activeColor,
              isDisabled: isDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuraRadioPainter extends CustomPainter {
  final bool isSelected;
  final Color activeColor;
  final bool isDisabled;

  _AuraRadioPainter({
    required this.isSelected,
    required this.activeColor,
    required this.isDisabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 2;
    final innerRadius = outerRadius * 0.5;

    // Determine colors
    final outerColor = isDisabled 
        ? activeColor.withValues(alpha: 0.4)
        : activeColor;
    final innerColor = isDisabled 
        ? activeColor.withValues(alpha: 0.4)
        : activeColor;

    // Draw outer circle (border)
    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Draw inner circle when selected
    if (isSelected) {
      final innerPaint = Paint()
        ..color = innerColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, innerRadius, innerPaint);
    }
  }

  @override
  bool shouldRepaint(_AuraRadioPainter oldDelegate) {
    return isSelected != oldDelegate.isSelected ||
        activeColor != oldDelegate.activeColor ||
        isDisabled != oldDelegate.isDisabled;
  }
}
```

**Step 4: Run test to verify it passes**
Expected: PASS - custom painted radio circles

**Step 5: Commit**
```bash
git add packages/auravibes_ui/lib/src/molecules/auravibes_radio.dart
git commit -m "refactor: custom AuraRadio with CustomPaint instead of Material Radio"
```

---

### Task 5: AuraRadioGroup - Already Custom (Verify)

**Files:**
- Modify: `packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart`
- Modify: `packages/auravibes_ui/test/src/organisms/auravibes_radio_group_test.dart`

**Step 1: Verify current implementation**
Check if it uses Material RadioGroup or custom layout.

**Step 2: Update to ensure no Material RadioGroup**
If current implementation uses RadioGroup, replace with custom Row/Column.

```dart
// Replace RadioGroup with custom layout
return widget.direction == Axis.horizontal
    ? Row(children: radioWidgets)
    : Column(children: radioWidgets);
```

**Step 3: Run tests to verify**
Expected: PASS

**Step 4: Commit**
```bash
git add packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart
git commit -m "refactor: custom AuraRadioGroup without Material RadioGroup"
```

---

### Task 6: AuraRadioListTile - Custom Implementation

**Files:**
- Modify: `packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart`
- Modify: `packages/auravibes_ui/test/src/organisms/auravibes_radio_group_test.dart`

**Step 1: Write failing test**

```dart
test('uses custom ListTile instead of Material RadioListTile', () {
  await tester.pumpWidget(
    MaterialApp(
      home: AuraRadioListTile<String>(
        value: 'option1',
        groupValue: 'option1',
        onChanged: (v) {},
        title: const Text('Title'),
      ),
    ),
  );
  
  // Should NOT use Material RadioListTile
  expect(find.byType(RadioListTile<String>), findsNothing);
  
  // Should find custom row with radio and text
  expect(find.byType(Row), findsWidgets);
});
```

**Step 2: Run test to verify it fails**
Expected: FAIL - currently uses RadioListTile

**Step 3: Write custom implementation**

Add to `auravibes_radio_group.dart`:

```dart
/// Custom list tile with radio button.
class AuraRadioListTile<T extends Object> extends StatelessWidget {
  const AuraRadioListTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.title,
    super.key,
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

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    
    return GestureDetector(
      onTap: disabled ? null : () => onChanged?.call(value),
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: disabled 
            ? SystemMouseCursors.forbidden 
            : SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              AuraRadio<T>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                colorVariant: colorVariant,
                disabled: disabled,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: TextStyle(
                        color: disabled 
                            ? context.auraColors.onSurfaceVariant.withValues(alpha: 0.6)
                            : context.auraColors.onSurface,
                        fontSize: 16,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: TextStyle(
                          color: context.auraColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**
Expected: PASS - custom list tile with custom radio

**Step 5: Commit**
```bash
git add packages/auravibes_ui/lib/src/organisms/auravibes_radio_group.dart
git commit -m "refactor: custom AuraRadioListTile without Material RadioListTile"
```

---

### Task 7: AuraConfirmDialog - Full Custom Implementation

**Files:**
- Modify: `packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart`
- Modify: `packages/auravibes_ui/test/src/organisms/auravibes_dialog_test.dart`

**Step 1: Write failing test**

```dart
test('uses custom OverlayEntry instead of Material AlertDialog', () async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showAuraConfirmDialog(
              context: context,
              title: 'Confirm',
              message: 'Are you sure?',
            ),
            child: const Text('Show'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();

  // Should NOT use Material AlertDialog
  expect(find.byType(AlertDialog), findsNothing);
  
  // Should show custom dialog
  expect(find.text('Confirm'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**
Expected: FAIL - currently uses AlertDialog

**Step 3: Write custom implementation**

```dart
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:flutter/material.dart';

/// Shows a custom confirmation dialog.
Future<bool?> showAuraConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  AuraColorVariant? colorVariant,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AuraDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        colorVariant: colorVariant,
        isConfirmDialog: true,
      );
    },
  );
}

/// Shows a custom alert dialog.
Future<void?> showAuraAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String dismissText = 'OK',
  AuraColorVariant? colorVariant,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _AuraDialog(
        title: title,
        message: message,
        dismissText: dismissText,
        colorVariant: colorVariant,
        isConfirmDialog: false,
      );
    },
  );
}

class _AuraDialog extends StatelessWidget {
  const _AuraDialog({
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.dismissText = 'OK',
    this.colorVariant,
    required this.isConfirmDialog,
  });

  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final String dismissText;
  final AuraColorVariant? colorVariant;
  final bool isConfirmDialog;

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;
    final dialogColor = colors.surface;
    final textColor = colors.onSurface;
    
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: dialogColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              
              // Message
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              
              // Divider
              const Divider(height: 1),
              
              // Actions
              Row(
                mainAxisAlignment: isConfirmDialog 
                    ? MainAxisAlignment.end 
                    : MainAxisAlignment.center,
                children: isConfirmDialog
                    ? [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(cancelText),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(confirmText),
                        ),
                      ]
                    : [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(dismissText),
                        ),
                      ],
              ),
              
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 4: Run test to verify it passes**
Expected: PASS - custom dialog with OverlayEntry

**Step 5: Commit**
```bash
git add packages/auravibes_ui/lib/src/organisms/auravibes_dialog.dart
git commit -m "refactor: custom AuraConfirmDialog/AuraAlertDialog with OverlayEntry instead of AlertDialog"
```

---

### Task 8: AuraAlertDialog - Already Covered

The AlertDialog implementation is included in Task 7.

---

### Task 9: Update STYLE_GUIDE.md

**Files:**
- Modify: `packages/auravibes_ui/STYLE_GUIDE.md`

**Step 1: Add custom implementation guidance**

Add section about custom vs Material wrappers:

```markdown
## Custom Implementation Guidelines

When implementing Aura widgets, prefer full custom implementations over wrapping Material widgets:

### ✅ Custom Approach (Preferred)
- Use `CustomPaint` for custom graphics (radio buttons, checkboxes)
- Use `OverlayEntry` for floating widgets (tooltips, snackbars, dialogs)
- Use `GestureDetector` for custom interactions
- Use `AnimatedContainer`/`AnimationController` for animations

### ❌ Avoid Material Wrappers
- Don't wrap `Tooltip`, `SnackBar`, `AlertDialog`, `Radio`, `RadioListTile`
- These introduce Material styling that conflicts with Aura aesthetics

### Examples

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
  return showGeneralDialog<bool>(...);
}
```
```

**Step 2: Commit**
```bash
git add packages/auravibes_ui/STYLE_GUIDE.md
git commit -m "docs: add custom implementation guidelines to STYLE_GUIDE.md"
```

---

## Summary of Changes

| Task | Widget | Change |
|------|--------|--------|
| 1 | AuraTooltip | Custom OverlayEntry + hover handling |
| 2 | AuraSelectableText | Already acceptable (keep as-is) |
| 3 | showAuraSnackBar | Custom OverlayEntry + animations |
| 4 | AuraRadio | Custom CustomPaint circles |
| 5 | AuraRadioGroup | Verify no Material RadioGroup |
| 6 | AuraRadioListTile | Custom ListTile + custom Radio |
| 7 | AuraConfirmDialog | Custom showGeneralDialog |
| 8 | AuraAlertDialog | Custom showGeneralDialog (combined with 7) |
| 9 | STYLE_GUIDE.md | Add custom implementation guidelines |

---

## Test Execution Order

Run tests after each task:

```bash
# Task 1
cd packages/auravibes_ui && flutter test test/src/atoms/auravibes_tooltip_test.dart

# Task 3  
cd packages/auravibes_ui && flutter test test/src/molecules/auravibes_snackbar_test.dart

# Task 4
cd packages/auravibes_ui && flutter test test/src/molecules/auravibes_radio_test.dart

# Task 6
cd packages/auravibes_ui && flutter test test/src/organisms/auravibes_radio_group_test.dart

# Task 7
cd packages/auravibes_ui && flutter test test/src/organisms/auravibes_dialog_test.dart

# Final verification
cd packages/auravibes_ui && flutter test
```

---

**Plan complete.** Two execution options:

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints

Which approach?
