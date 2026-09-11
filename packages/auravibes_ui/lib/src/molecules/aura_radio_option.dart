// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A custom painter for drawing the radio button circles.
///
/// Draws an outer circle with border and an inner filled circle when selected.
class _RadioPainter({
  required final bool isSelected,
  required final bool isFocused,
  required final Color color,
  required final Color borderColor,
}) extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 2; // Account for stroke width.

    if (isFocused) _paintFocus(canvas, center, outerRadius);
    _paintOuter(canvas, center, outerRadius);
    if (isSelected) _paintSelection(canvas, center, outerRadius);
  }

  @override
  bool shouldRepaint(_RadioPainter oldDelegate) {
    return isSelected != oldDelegate.isSelected ||
        isFocused != oldDelegate.isFocused ||
        color != oldDelegate.color ||
        borderColor != oldDelegate.borderColor;
  }

  void _paintFocus(Canvas canvas, Offset center, double outerRadius) {
    final focusPaint = Paint()
      ..color = color.withValues(alpha: 0.24)
      ..style = .stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, outerRadius + 1, focusPaint);
  }

  void _paintOuter(Canvas canvas, Offset center, double outerRadius) {
    final outerPaint = Paint()
      ..color = borderColor
      ..style = .stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, outerRadius, outerPaint);
  }

  void _paintSelection(Canvas canvas, Offset center, double outerRadius) {
    final innerPaint = Paint()
      ..color = color
      ..style = .fill;

    canvas.drawCircle(center, outerRadius * 0.5, innerPaint);
  }
}

/// A configuration class for radio options in a group.
///
/// Used with AuraRadioGroup to define the available selections.
class AuraRadioOption<T> {
  /// Creates a radio option with a value, label, and optional subtitle.
  const new({
    required this.value,
    required this.label,
    this.subtitle,
    this.disabled = false,
    this.semanticLabel,
  });

  /// The value this option represents.
  final T value;

  /// The display label for this option.
  final Widget label;

  /// Optional subtitle displayed below the label.
  final Widget? subtitle;

  /// Whether this option is disabled.
  final bool disabled;

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;

  /// Whether this option provides a subtitle widget.
  bool hasSubtitle() => subtitle != null;
}

/// An individual radio button that communicates with its parent group.
///
/// Follows the const-first design pattern using [AuraTint] for
/// compile-time color configuration.
///
/// Selection contract. An equal value and group value is selected and has no
/// interaction. An unequal value is unselected and tappable. A disabled item
/// or an item with a null callback is greyed out and has no response.
///
/// Example.
///
/// ```dart
/// AuraRadio<String>(
///   value: 'option1',
///   groupValue: selectedValue,
///   onChanged: (value) => setState(() => selectedValue = value),
///   tint: AuraTint.primary,
/// )
/// ```
class AuraRadio<T> extends StatefulWidget {
  /// Creates an AuraRadio widget.
  const new({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    super.key,
    this.tint,
    this.disabled = false,
    this.semanticLabel = 'Radio button',
  });

  /// The value represented by this radio button.
  final T value;

  /// The currently selected value in the group.
  final T? groupValue;

  /// Called when the user selects this radio button.
  ///
  /// If null, the radio button will be disabled.
  final ValueChanged<T?>? onChanged;

  /// The tint for the radio button when selected.
  final AuraTint? tint;

  /// Whether the radio button is disabled.
  final bool disabled;

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;

  @override
  State<AuraRadio<T>> createState() => _AuraRadioState<T>();
}

class _AuraRadioState<T> extends State<AuraRadio<T>> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) =>
      _AuraRadioPresentation.fromState(this, context);

  bool _isDisabled(BuildContext context) {
    return widget.disabled ||
        widget.onChanged == null ||
        !AuraInteractionScope.of(context).allowsValueChanges;
  }

  void _setHovered(bool value) => setState(() => _isHovered = value);

  void _setFocused(bool value) => setState(() => _isFocused = value);

  Color _getActiveColor(BuildContext context) {
    final auraColors = context.auraColors;

    return auraColors.colorFor(widget.tint ?? AuraTint.primary);
  }

  Color _getBorderColor(BuildContext context, bool isDisabled) {
    final auraColors = context.auraColors;
    if (isDisabled) return auraColors.outlineVariant;
    if (widget.value == widget.groupValue || _isFocused || _isHovered) {
      return _getActiveColor(context);
    }

    return auraColors.onSurfaceVariant;
  }

  void _select() {
    if (widget.disabled ||
        widget.onChanged == null ||
        !AuraInteractionScope.of(context).allowsValueChanges) {
      return;
    }

    widget.onChanged?.call(widget.value);
  }
}

class _AuraRadioPresentation extends StatelessWidget {
  const new({
    required this.isDisabled,
    required this.isSelected,
    required this.isFocused,
    required this.color,
    required this.borderColor,
    required this.semanticLabel,
    required this.onSelect,
    required this.onHover,
    required this.onFocusChange,
  });

  new fromState(_AuraRadioState<dynamic> state, BuildContext context)
    : this(
        isDisabled: state._isDisabled(context),
        isSelected: state.widget.value == state.widget.groupValue,
        isFocused: state._isFocused,
        color: state._getActiveColor(context),
        borderColor: state._getBorderColor(context, state._isDisabled(context)),
        semanticLabel: state.widget.semanticLabel,
        onSelect: state._select,
        onHover: state._setHovered,
        onFocusChange: state._setFocused,
      );

  final bool isDisabled;
  final bool isSelected;
  final bool isFocused;
  final Color color;
  final Color borderColor;
  final String? semanticLabel;
  final VoidCallback onSelect;
  final ValueChanged<bool> onHover;
  final ValueChanged<bool> onFocusChange;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      child: _AuraRadioFocusDetector(presentation: this),
      enabled: !isDisabled,
      checked: isSelected,
      inMutuallyExclusiveGroup: true,
      label: semanticLabel,
      onTap: isDisabled ? null : onSelect,
    );
  }
}

class const _AuraRadioFocusDetector({
  required final _AuraRadioPresentation presentation,
}) extends StatelessWidget {
  Map<ShortcutActivator, Intent> get _shortcuts => const {
    SingleActivator(.enter): ActivateIntent(),
    SingleActivator(.space): ActivateIntent(),
  };

  Map<Type, Action<Intent>> get _actions => {
    ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate),
  };

  MouseCursor get _mouseCursor => presentation.isDisabled
      ? SystemMouseCursors.forbidden
      : SystemMouseCursors.click;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: !presentation.isDisabled,
      shortcuts: _shortcuts,
      actions: _actions,
      onShowHoverHighlight: presentation.onHover,
      onFocusChange: presentation.onFocusChange,
      mouseCursor: _mouseCursor,
      child: _AuraRadioTapTarget(presentation: presentation),
    );
  }

  Null _activate(ActivateIntent _) {
    presentation.onSelect();

    return null;
  }
}

class const _AuraRadioTapTarget({
  required final _AuraRadioPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: _AuraRadioIndicator(presentation: presentation),
      onTap: presentation.isDisabled ? null : presentation.onSelect,
      behavior: .opaque,
      excludeFromSemantics: true,
    );
  }
}

class const _AuraRadioIndicator({
  required final _AuraRadioPresentation presentation,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: DesignInputSizes.heightLg,
      height: DesignInputSizes.heightLg,
      child: Center(child: _AuraRadioPaint(presentation: presentation)),
    );
  }
}

class _AuraRadioPaint extends StatelessWidget {
  static const _radioSize = 24.0;

  new({required _AuraRadioPresentation presentation})
    : _child = Opacity(
        opacity: presentation.isDisabled ? 0.6 : 1.0,
        child: SizedBox(
          width: _radioSize,
          height: _radioSize,
          child: CustomPaint(
            painter: _RadioPainter(
              isSelected: presentation.isSelected,
              isFocused: presentation.isFocused,
              color: presentation.color,
              borderColor: presentation.borderColor,
            ),
          ),
        ),
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}
