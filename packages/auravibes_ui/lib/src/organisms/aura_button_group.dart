// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-moving-to-variable
// Required: UI components repeat theme and layout lookups intentionally.
// ignore_for_file: prefer-single-widget-per-file
// Required: UI components keep related private widgets together.
import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A customizable button group component following the Aura design system.
///
/// This component supports three modes:
/// - [AuraButtonGroup.single] - Radio-like behavior where only one option
///   can be selected
/// - [AuraButtonGroup.multi] - Toggle behavior where multiple can be selected
/// - [AuraButtonGroup.action] - Clickable buttons without selection state
class AuraButtonGroup<T> extends StatelessWidget {
  /// Creates a single-selection button group (radio behavior).
  ///
  /// Only one item can be selected at a time.
  const AuraButtonGroup.single({
    required this.items,
    required this.selectedValue,
    required ValueChanged<T> this.onChanged,
    super.key,
    this.size = AuraButtonGroupSize.base,
    this.variant = AuraButtonGroupVariant.outlined,
    this.orientation = Axis.horizontal,
    this.disabled = false,
    this.isLoading = false,
  }) : selectedValues = null,
       onMultiChanged = null,
       onPressed = null,
       _mode = _ButtonGroupMode.single;

  /// Creates a multi-selection button group (toggle behavior).
  ///
  /// Multiple items can be selected at the same time.
  const AuraButtonGroup.multi({
    required this.items,
    required Set<T> this.selectedValues,
    required ValueChanged<Set<T>> this.onMultiChanged,
    super.key,
    this.size = AuraButtonGroupSize.base,
    this.variant = AuraButtonGroupVariant.outlined,
    this.orientation = Axis.horizontal,
    this.disabled = false,
    this.isLoading = false,
  }) : selectedValue = null,
       onChanged = null,
       onPressed = null,
       _mode = _ButtonGroupMode.multi;

  /// Creates an action button group (clickable without selection state).
  ///
  /// Each button triggers its own action without maintaining selection.
  const AuraButtonGroup.action({
    required this.items,
    required ValueChanged<T> this.onPressed,
    super.key,
    this.size = AuraButtonGroupSize.base,
    this.variant = AuraButtonGroupVariant.outlined,
    this.orientation = Axis.horizontal,
    this.disabled = false,
    this.isLoading = false,
  }) : selectedValue = null,
       selectedValues = null,
       onChanged = null,
       onMultiChanged = null,
       _mode = _ButtonGroupMode.action;

  /// The items to display in the group.
  final List<AuraButtonGroupItem<T>> items;

  /// The currently selected value (for single mode).
  final T? selectedValue;

  /// The currently selected values (for multi mode).
  final Set<T>? selectedValues;

  /// Callback when selection changes (for single mode).
  final ValueChanged<T>? onChanged;

  /// Callback when selection changes (for multi mode).
  final ValueChanged<Set<T>>? onMultiChanged;

  /// Callback when a button is pressed (for action mode).
  final ValueChanged<T>? onPressed;

  /// The size of the button group.
  final AuraButtonGroupSize size;

  /// The visual variant of the button group.
  final AuraButtonGroupVariant variant;

  /// The orientation of the button group.
  final Axis orientation;

  /// Whether the button group is disabled.
  final bool disabled;

  /// Whether the button group is in a loading state.
  final bool isLoading;

  final _ButtonGroupMode _mode;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;
    final borderRadius = auraTheme.borderRadius.md;

    final children = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final isFirst = i == 0;
      final isLast = i == items.length - 1;

      final isSelected = _isSelected(item.value);
      final isItemDisabled = disabled || item.disabled;
      final isItemLoading = isLoading || item.isLoading;

      // Use Transform.translate to collapse double borders between items.
      // By shifting non-first items back by 1px (the border width).
      Widget child = _AuraButtonGroupItem(
        item: item,
        isSelected: isSelected,
        isFirst: isFirst,
        isLast: isLast,
        size: size,
        variant: variant,
        orientation: orientation,
        disabled: isItemDisabled,
        isLoading: isItemLoading,
        mode: _mode,
        onTap: isItemDisabled || isItemLoading ? null : () => _onTap(item),
        auraColors: auraColors,
        auraTheme: auraTheme,
      );

      // Shift non-first items to collapse the double border.
      if (!isFirst && variant != AuraButtonGroupVariant.ghost) {
        child = Transform.translate(
          offset: orientation == Axis.horizontal
              ? const Offset(-1, 0)
              : const Offset(0, -1),
          child: child,
        );
      }

      children.add(child);
    }

    final content = orientation == Axis.horizontal
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: children,
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );

    // Wrap entire group in ClipRRect for rounded corners.
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: content,
    );
  }

  bool _isSelected(T value) {
    return switch (_mode) {
      _ButtonGroupMode.single => selectedValue == value,
      _ButtonGroupMode.multi => selectedValues?.contains(value) ?? false,
      _ButtonGroupMode.action => false,
    };
  }

  void _onTap(AuraButtonGroupItem<T> item) {
    switch (_mode) {
      case _ButtonGroupMode.single:
        onChanged?.call(item.value);
      case _ButtonGroupMode.multi:
        final currentSet = Set<T>.from(selectedValues ?? {});
        if (currentSet.contains(item.value)) {
          final _ = currentSet.remove(item.value);
        } else {
          final _ = currentSet.add(item.value);
        }
        onMultiChanged?.call(currentSet);
      case _ButtonGroupMode.action:
        onPressed?.call(item.value);
    }
  }
}

class _AuraButtonGroupItem<T> extends StatefulWidget {
  const _AuraButtonGroupItem({
    required this.item,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.size,
    required this.variant,
    required this.orientation,
    required this.disabled,
    required this.isLoading,
    required this.mode,
    required this.onTap,
    required this.auraColors,
    required this.auraTheme,
  });

  final AuraButtonGroupItem<T> item;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final AuraButtonGroupSize size;
  final AuraButtonGroupVariant variant;
  final Axis orientation;
  final bool disabled;
  final bool isLoading;
  final _ButtonGroupMode mode;
  final VoidCallback? onTap;
  final AuraColorScheme auraColors;
  final AuraTheme auraTheme;

  @override
  State<_AuraButtonGroupItem<T>> createState() =>
      _AuraButtonGroupItemState<T>();
}

class _AuraButtonGroupItemState<T> extends State<_AuraButtonGroupItem<T>> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final padding = _getPadding();
    final backgroundColor = _getBackgroundColor();
    final foregroundColor = _getForegroundColor();
    final border = _getBorder();

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: widget.disabled || widget.isLoading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        child: AnimatedContainer(
          padding: padding,
          decoration: BoxDecoration(color: backgroundColor, border: border),
          child: widget.isLoading
              ? SizedBox(
                  width: _getLoadingSize(),
                  height: _getLoadingSize(),
                  child: AuraLoadingCircle(
                    colorVariant: _getLoadingColorVariant(),
                    size: _getLoadingSize(),
                  ),
                )
              : DefaultTextStyle(
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: _getFontSize(),
                    fontWeight: widget.auraTheme.typography.weights.medium,
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      size: _getIconSize(),
                      color: foregroundColor,
                    ),
                    child: widget.item.child,
                  ),
                ),
          duration: widget.auraTheme.animation.normal,
        ),
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onTapCancel: () => setState(() => _isPressed = false),
      ),
    );
  }

  EdgeInsets _getPadding() {
    return switch (widget.size) {
      AuraButtonGroupSize.sm => const EdgeInsets.symmetric(
        vertical: DesignSpacing.xs,
        horizontal: DesignSpacing.sm,
      ),
      AuraButtonGroupSize.base => const EdgeInsets.symmetric(
        vertical: DesignSpacing.sm,
        horizontal: DesignSpacing.md,
      ),
      AuraButtonGroupSize.lg => const EdgeInsets.symmetric(
        vertical: DesignSpacing.md,
        horizontal: DesignSpacing.lg,
      ),
    };
  }

  Color _getBackgroundColor() {
    final colors = widget.auraColors;

    if (widget.disabled) {
      return colors.outlineVariant.withValues(alpha: 0.5);
    }

    final isActive = widget.isSelected || _isPressed;
    final isHovered = _isHovering && !_isPressed;

    return switch (widget.variant) {
      AuraButtonGroupVariant.filled => _getFilledBackgroundColor(
        colors,
        isActive: isActive,
        isHovered: isHovered,
      ),
      AuraButtonGroupVariant.outlined => _getOutlinedBackgroundColor(
        colors,
        isActive: isActive,
        isHovered: isHovered,
      ),
      AuraButtonGroupVariant.ghost => _getGhostBackgroundColor(
        colors,
        isActive: isActive,
        isHovered: isHovered,
      ),
    };
  }

  Color _getFilledBackgroundColor(
    AuraColorScheme colors, {
    required bool isActive,
    required bool isHovered,
  }) {
    if (isActive) return colors.primary;
    if (isHovered) return colors.primary.withValues(alpha: 0.8);

    return colors.primary.withValues(alpha: 0.6);
  }

  Color _getOutlinedBackgroundColor(
    AuraColorScheme colors, {
    required bool isActive,
    required bool isHovered,
  }) {
    if (isActive) return colors.primary;
    if (isHovered) return colors.primary.withValues(alpha: 0.1);

    return DesignColors.transparent;
  }

  Color _getGhostBackgroundColor(
    AuraColorScheme colors, {
    required bool isActive,
    required bool isHovered,
  }) {
    if (isActive) return colors.primary.withValues(alpha: 0.2);
    if (isHovered) return colors.primary.withValues(alpha: 0.1);

    return DesignColors.transparent;
  }

  Color _getForegroundColor() {
    final colors = widget.auraColors;

    if (widget.disabled) {
      return colors.onSurfaceVariant;
    }

    final isActive = widget.isSelected || _isPressed;

    return switch (widget.variant) {
      AuraButtonGroupVariant.filled => colors.onPrimary,
      AuraButtonGroupVariant.outlined =>
        isActive ? colors.onPrimary : colors.primary,
      AuraButtonGroupVariant.ghost => colors.primary,
    };
  }

  AuraColorVariant _getLoadingColorVariant() {
    if (widget.disabled) return AuraColorVariant.onSurfaceVariant;

    final isActive = widget.isSelected || _isPressed;

    return switch (widget.variant) {
      AuraButtonGroupVariant.filled => AuraColorVariant.onPrimary,
      AuraButtonGroupVariant.outlined =>
        isActive ? AuraColorVariant.onPrimary : AuraColorVariant.primary,
      AuraButtonGroupVariant.ghost => AuraColorVariant.primary,
    };
  }

  Border? _getBorder() {
    final colors = widget.auraColors;

    if (widget.variant == AuraButtonGroupVariant.ghost) {
      return null;
    }

    final borderColor = widget.disabled
        ? colors.outlineVariant
        : colors.primary;

    // Use uniform border on all sides to support the parent ClipRRect.
    // The double borders between items are collapsed using Transform.translate.
    // In the parent widget.
    return Border.all(color: borderColor);
  }

  double _getFontSize() {
    return switch (widget.size) {
      AuraButtonGroupSize.sm => widget.auraTheme.typography.sizes.sm,
      AuraButtonGroupSize.base => widget.auraTheme.typography.sizes.base,
      AuraButtonGroupSize.lg => widget.auraTheme.typography.sizes.lg,
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      AuraButtonGroupSize.sm => 16.0,
      AuraButtonGroupSize.base => 20.0,
      AuraButtonGroupSize.lg => 24.0,
    };
  }

  double _getLoadingSize() {
    return switch (widget.size) {
      AuraButtonGroupSize.sm => 14.0,
      AuraButtonGroupSize.base => 18.0,
      AuraButtonGroupSize.lg => 22.0,
    };
  }
}

/// Represents an item in an [AuraButtonGroup].
class AuraButtonGroupItem<T> {
  /// Creates a button group item.
  const AuraButtonGroupItem({
    required this.value,
    required this.child,
    this.disabled = false,
    this.isLoading = false,
  });

  /// The value associated with this item.
  final T value;

  /// The widget to display inside this item.
  final Widget child;

  /// Whether this specific item is disabled.
  final bool disabled;

  /// Whether this specific item is in a loading state.
  final bool isLoading;
}

/// The size of an [AuraButtonGroup].
enum AuraButtonGroupSize {
  /// A small button group.
  sm,

  /// A base/medium button group (default).
  base,

  /// A large button group.
  lg,
}

/// The visual variant of an [AuraButtonGroup].
enum AuraButtonGroupVariant {
  /// A filled button group with solid background.
  filled,

  /// An outlined button group with border.
  outlined,

  /// A ghost button group with transparent background.
  ghost,
}

enum _ButtonGroupMode {
  single,
  multi,
  action,
}
