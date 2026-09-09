// Required: Existing test and UI helpers keep compact return flow.
// Required: UI components keep related private widgets together.
import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

/// A customizable button group component following the Aura design system.
///
/// This component supports three modes. [AuraButtonGroup.single] provides
/// radio-like behavior with one selected option. [AuraButtonGroup.multi]
/// provides toggle behavior with multiple selected options. The
/// [AuraButtonGroup.action] mode provides clickable buttons without selection
/// state.
class AuraButtonGroup<T> extends StatelessWidget {
  /// Creates a single-selection button group (radio behavior).
  ///
  /// Only one item can be selected at a time.
  const new single({
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
  const new multi({
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
  const new action({
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
  Widget build(BuildContext context) => _AuraButtonGroupLayout(
    group: this,
    auraColors: context.auraColors,
    auraTheme: context.auraTheme,
  );

  bool _isSelected(T value) {
    return switch (_mode) {
      .single => selectedValue == value,
      .multi => selectedValues?.contains(value) ?? false,
      .action => false,
    };
  }

  void _onTap(AuraButtonGroupItem<T> item) => switch (_mode) {
    .single => _onSingleTap(item.value),
    .multi => _onMultiTap(item.value),
    .action => _onActionTap(item.value),
  };

  void _onSingleTap(T value) => onChanged?.call(value);

  void _onActionTap(T value) => onPressed?.call(value);

  void _onMultiTap(T value) {
    final currentSet = Set<T>.from(selectedValues ?? {});
    _toggleValue(currentSet, value);
    onMultiChanged?.call(currentSet);
  }

  void _toggleValue(Set<T> values, T value) {
    if (values.contains(value)) {
      final _ = values.remove(value);
    } else {
      final _ = values.add(value);
    }
  }
}

class const _AuraButtonGroupLayout<T>({
  required final AuraButtonGroup<T> group,
  required final AuraColorScheme auraColors,
  required final AuraTheme auraTheme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraButtonGroupFrame(
    children: _AuraButtonGroupChildren<T>(
      group: group,
      auraColors: auraColors,
      auraTheme: auraTheme,
    ).children,
    orientation: group.orientation,
    borderRadius: auraTheme.fromBorderRadius(.md),
  );
}

class const _AuraButtonGroupFrame({
  required final List<Widget> children,
  required final Axis orientation,
  required final double borderRadius,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: orientation == Axis.horizontal
        ? Row(mainAxisSize: .min, children: children)
        : Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: children,
          ),
  );
}

class const _AuraButtonGroupChildren<T>({
  required final AuraButtonGroup<T> group,
  required final AuraColorScheme auraColors,
  required final AuraTheme auraTheme,
}) {
  List<Widget> get children => [
    for (var index = 0; index < group.items.length; index++)
      _item(index, group.items[index]),
  ];

  Widget _item(int index, AuraButtonGroupItem<T> item) {
    final data = _AuraButtonGroupItemData<T>(
      group: group,
      item: item,
      index: index,
      auraColors: auraColors,
      auraTheme: auraTheme,
    );

    return _AuraButtonGroupItemSlot(
      child: _AuraButtonGroupItem(data: data),
      shifted: data.isShifted,
      orientation: group.orientation,
    );
  }
}

class const _AuraButtonGroupItemData<T>({
  required final AuraButtonGroup<T> group,
  required final AuraButtonGroupItem<T> item,
  required final int index,
  required final AuraColorScheme auraColors,
  required final AuraTheme auraTheme,
}) {
  bool get isSelected => group._isSelected(item.value);

  bool get isFirst => index == 0;

  bool get isLast => index == group.items.length - 1;

  bool get disabled => group.disabled || item.disabled;

  bool get isLoading => group.isLoading || item.isLoading;

  _ButtonGroupMode get mode => group._mode;

  AuraButtonGroupSize get size => group.size;

  AuraButtonGroupVariant get variant => group.variant;

  Axis get orientation => group.orientation;

  VoidCallback? get onTap => disabled || isLoading ? null : _handleTap;

  bool get isShifted => !isFirst && variant != AuraButtonGroupVariant.ghost;

  void _handleTap() => group._onTap(item);
}

class const _AuraButtonGroupItemSlot({
  required final Widget child,
  required final bool shifted,
  required final Axis orientation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (!shifted) return child;

    return Transform.translate(
      offset: orientation == Axis.horizontal
          ? const Offset(-1, 0)
          : const Offset(0, -1),
      child: child,
    );
  }
}

class const _AuraButtonGroupItem<T>({
  required final _AuraButtonGroupItemData<T> data,
}) extends StatefulWidget {
  AuraButtonGroupItem<T> get item => data.item;
  bool get isSelected => data.isSelected;
  bool get isFirst => data.isFirst;
  bool get isLast => data.isLast;
  AuraButtonGroupSize get size => data.size;
  AuraButtonGroupVariant get variant => data.variant;
  Axis get orientation => data.orientation;
  bool get disabled => data.disabled;
  bool get isLoading => data.isLoading;
  _ButtonGroupMode get mode => data.mode;
  VoidCallback? get onTap => data.onTap;
  AuraColorScheme get auraColors => data.auraColors;
  AuraTheme get auraTheme => data.auraTheme;

  @override
  State<_AuraButtonGroupItem<T>> createState() =>
      _AuraButtonGroupItemState<T>();
}

class _AuraButtonGroupItemState<T> extends State<_AuraButtonGroupItem<T>> {
  static const _hoverAlpha = 0.1;
  static const _activeAlpha = 0.2;
  static const _selectedAlpha = 0.6;
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) =>
      _AuraButtonGroupItemView(data: _getPresentation());

  _AuraButtonGroupItemPresentation<T> _getPresentation() =>
      _AuraButtonGroupItemPresentation(
        item: widget,
        colors: _getColors(),
        dimensions: _getDimensions(),
        onHover: _setHovering,
        onPressed: _setPressed,
      );

  void _setHovering(bool value) => setState(() => _isHovering = value);

  void _setPressed(bool value) => setState(() => _isPressed = value);

  _AuraButtonGroupItemColors _getColors() => _AuraButtonGroupItemColors(
    backgroundColor: _getBackgroundColor(),
    foregroundColor: _getForegroundColor(),
    border: _getBorder(),
  );

  _AuraButtonGroupItemDimensions _getDimensions() =>
      _AuraButtonGroupItemDimensions(
        padding: _getPadding(),
        fontSize: _getFontSize(),
        iconSize: _getIconSize(),
        loadingSize: _getLoadingSize(),
      );

  EdgeInsets _getPadding() =>
      _paddingForSize(widget.size, widget.auraTheme.spacing);

  EdgeInsets _paddingForSize(
    AuraButtonGroupSize size,
    AuraSpacingScale spacing,
  ) => switch (size) {
    .sm => EdgeInsets.symmetric(vertical: spacing.xs, horizontal: spacing.sm),
    .base => EdgeInsets.symmetric(vertical: spacing.sm, horizontal: spacing.md),
    .lg => EdgeInsets.symmetric(vertical: spacing.md, horizontal: spacing.lg),
  };

  Color _getBackgroundColor() {
    final colors = widget.auraColors;

    if (widget.disabled) {
      return colors.outlineVariant.withValues(alpha: 0.5);
    }

    return _getVariantBackgroundColor(
      colors,
      isActive: widget.isSelected || _isPressed,
      isHovered: _isHovering && !_isPressed,
    );
  }

  Color _getVariantBackgroundColor(
    AuraColorScheme colors, {
    required bool isActive,
    required bool isHovered,
  }) => switch (widget.variant) {
    .filled => _getFilledBackgroundColor(
      colors,
      isActive: isActive,
      isHovered: isHovered,
    ),
    .outlined => _getOutlinedBackgroundColor(
      colors,
      isActive: isActive,
      isHovered: isHovered,
    ),
    .ghost => _getGhostBackgroundColor(
      colors,
      isActive: isActive,
      isHovered: isHovered,
    ),
  };

  Color _getFilledBackgroundColor(
    AuraColorScheme colors, {
    required bool isActive,
    required bool isHovered,
  }) {
    if (isActive) return colors.primary;
    if (isHovered) return colors.primary.withValues(alpha: 0.8);

    return colors.primary.withValues(alpha: _selectedAlpha);
  }

  Color _getOutlinedBackgroundColor(
    AuraColorScheme colors, {
    required bool isActive,
    required bool isHovered,
  }) {
    if (isActive) return colors.primary;
    if (isHovered) return colors.primary.withValues(alpha: _hoverAlpha);

    return DesignColors.transparent;
  }

  Color _getGhostBackgroundColor(
    AuraColorScheme colors, {
    required bool isActive,
    required bool isHovered,
  }) {
    if (isActive) return colors.primary.withValues(alpha: _activeAlpha);
    if (isHovered) return colors.primary.withValues(alpha: _hoverAlpha);

    return DesignColors.transparent;
  }

  Color _getForegroundColor() {
    final colors = widget.auraColors;

    if (widget.disabled) {
      return colors.onSurfaceVariant;
    }

    return _foregroundForVariant(
      colors,
      widget.variant,
      widget.isSelected || _isPressed,
    );
  }

  Color _foregroundForVariant(
    AuraColorScheme colors,
    AuraButtonGroupVariant variant,
    bool isActive,
  ) => switch (variant) {
    .filled => colors.onTint(.primary),
    .outlined => isActive ? colors.onTint(.primary) : colors.primary,
    .ghost => colors.primary,
  };

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
    final typography = widget.auraTheme.typography;

    return switch (widget.size) {
      .sm => typography.fontSizeSm,
      .base => typography.fontSizeBase,
      .lg => typography.fontSizeLg,
    };
  }

  double _getIconSize() {
    return switch (widget.size) {
      .sm => 16.0,
      .base => 20.0,
      .lg => 24.0,
    };
  }

  double _getLoadingSize() {
    return switch (widget.size) {
      .sm => 14.0,
      .base => 18.0,
      .lg => 22.0,
    };
  }
}

class const _AuraButtonGroupItemColors({
  required final Color backgroundColor,
  required final Color foregroundColor,
  required final Border? border,
});

class const _AuraButtonGroupItemDimensions({
  required final EdgeInsets padding,
  required final double fontSize,
  required final double iconSize,
  required final double loadingSize,
});

class const _AuraButtonGroupItemPresentation<T>({
  required final _AuraButtonGroupItem<T> item,
  required final _AuraButtonGroupItemColors colors,
  required final _AuraButtonGroupItemDimensions dimensions,
  required final ValueChanged<bool> onHover,
  required final ValueChanged<bool> onPressed,
});

class const _AuraButtonGroupItemView<T>({
  required final _AuraButtonGroupItemPresentation<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => data.onHover(true),
    onExit: (_) => data.onHover(false),
    cursor: _itemCursor(data.item),
    child: _AuraButtonGroupItemSemantics(data: data),
  );
}

MouseCursor _itemCursor(_AuraButtonGroupItem<dynamic> item) =>
    item.disabled || item.isLoading
    ? SystemMouseCursors.basic
    : SystemMouseCursors.click;

class const _AuraButtonGroupItemSemantics<T>({
  required final _AuraButtonGroupItemPresentation<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraButtonGroupSemanticsContainer(
    child: _AuraButtonGroupItemGesture(data: data),
    data: data,
  );
}

class const _AuraButtonGroupSemanticsContainer<T>({
  required final Widget child,
  required final _AuraButtonGroupItemPresentation<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics.fromProperties(
    child: child,
    container: true,
    excludeSemantics: true,
    properties: _buttonSemanticsProperties(data),
  );
}

SemanticsProperties _buttonSemanticsProperties(
  _AuraButtonGroupItemPresentation<dynamic> data,
) => _itemSemanticsProperties(data.item);

SemanticsProperties _itemSemanticsProperties(
  _AuraButtonGroupItem<dynamic> item,
) => SemanticsProperties(
  enabled: !item.disabled && !item.isLoading,
  selected: item.isSelected,
  button: item.mode == _ButtonGroupMode.action,
  label: item.item.semanticLabel ?? 'Button',
  onTap: item.onTap,
);

class const _AuraButtonGroupItemGesture<T>({
  required final _AuraButtonGroupItemPresentation<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Center(child: _AuraButtonGroupGestureDetector(data: data)),
  );
}

class const _AuraButtonGroupGestureDetector<T>({
  required final _AuraButtonGroupItemPresentation<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _AuraButtonGroupAnimatedContent(data: data),
    onTapDown: (_) => data.onPressed(true),
    onTapUp: (_) => data.onPressed(false),
    onTap: data.item.onTap,
    onTapCancel: () => data.onPressed(false),
    excludeFromSemantics: true,
  );
}

class const _AuraButtonGroupAnimatedContent<T>({
  required final _AuraButtonGroupItemPresentation<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    padding: data.dimensions.padding,
    decoration: BoxDecoration(
      color: data.colors.backgroundColor,
      border: data.colors.border,
    ),
    child: _AuraButtonGroupItemContent(data: data),
    duration: data.item.auraTheme.animation.normal,
  );
}

class const _AuraButtonGroupItemContent<T>({
  required final _AuraButtonGroupItemPresentation<T> data,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => data.item.isLoading
      ? _AuraButtonGroupLoading(
          item: data.item,
          size: data.dimensions.loadingSize,
        )
      : _AuraButtonGroupLabel(
          item: data.item,
          colors: data.colors,
          dimensions: data.dimensions,
        );
}

class const _AuraButtonGroupLoading<T>({
  required final _AuraButtonGroupItem<T> item,
  required final double size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraLoadingCircle(
    tint: .primary,
    size: size,
    itemBuilder: (context, _) => DecoratedBox(
      decoration: BoxDecoration(
        color: item.auraColors.onTint(.primary),
        shape: .circle,
      ),
    ),
  );
}

class const _AuraButtonGroupLabel<T>({
  required final _AuraButtonGroupItem<T> item,
  required final _AuraButtonGroupItemColors colors,
  required final _AuraButtonGroupItemDimensions dimensions,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: .new(
      color: colors.foregroundColor,
      fontSize: dimensions.fontSize,
      fontWeight: item.auraTheme.typography.fontWeightMedium,
    ),
    child: IconTheme(
      data: .new(size: dimensions.iconSize, color: colors.foregroundColor),
      child: item.item.child,
    ),
  );
}

/// Represents an item in an [AuraButtonGroup].
class AuraButtonGroupItem<T> {
  /// Creates a button group item.
  const new({
    required this.value,
    required this.child,
    this.disabled = false,
    this.isLoading = false,
    this.semanticLabel,
  });

  /// The value associated with this item.
  final T value;

  /// The widget to display inside this item.
  final Widget child;

  /// Whether this specific item is disabled.
  final bool disabled;

  /// Whether this specific item is in a loading state.
  final bool isLoading;

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;
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

enum _ButtonGroupMode { single, multi, action }
