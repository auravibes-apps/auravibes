// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraTint, DesignColors, DesignInputSizes;
import 'package:flutter/widgets.dart';

export 'aura_checkbox_list_tile.dart';

/// An Aura checkbox that follows the const-first design system.
class AuraCheckbox extends StatelessWidget {
  /// Creates an Aura checkbox.
  const new({
    required this.value,
    required this.onChanged,
    super.key,
    this.tint,
    this.disabled = false,
    this.autofocus = false,
    this.semanticLabel = 'Checkbox',
  });

  /// Whether the checkbox is selected.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Tint used when selected.
  final AuraTint? tint;

  /// Whether the checkbox is disabled.
  final bool disabled;

  /// Whether this checkbox should request focus when built.
  final bool autofocus;

  /// A semantic label announced by assistive technologies.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final allowsValueChanges = AuraInteractionScope.of(context)
        .allowsValueChanges;
    final isDisabled = disabled || onChanged == null || !allowsValueChanges;
    return _CheckboxBuild(
      value: value,
      tint: tint,
      isDisabled: isDisabled,
      onChanged: isDisabled ? null : onChanged,
      autofocus: autofocus,
    );
  }
}

class const _CheckboxBuild({
  required final bool value,
  required final AuraTint? tint,
  required final bool isDisabled,
  required final ValueChanged<bool>? onChanged,
  required final bool autofocus,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _CheckboxInteraction(
      value: value,
      isDisabled: isDisabled,
      onChanged: onChanged,
      autofocus: autofocus,
      child: _CheckboxFocusAwareVisual(
        value: value,
        tint: tint,
        disabled: isDisabled,
      ),
    ),
    enabled: !isDisabled,
    checked: value,
  );
}

class const _CheckboxFocusAwareVisual({
  required final bool value,
  required final AuraTint? tint,
  required final bool disabled,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Builder(
    builder: (context) => _CheckboxVisual(
      value: value,
      tint: tint,
      disabled: disabled,
      isFocused: _CheckboxFocusState.of(context),
    ),
  );
}

class const _CheckboxMarkPainter({required final Color color})
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_checkboxMarkPath(size), _checkboxMarkPaint(color));
  }

  @override
  bool shouldRepaint(_CheckboxMarkPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

const _checkboxMarkStrokeWidth = 2.0;
const _checkboxMarkStartX = 0.1;
const _checkboxMarkStartY = 0.5;
const _checkboxMarkMiddleX = 0.4;
const _checkboxMarkMiddleY = 0.8;
const _checkboxMarkEndX = 0.9;
const _checkboxMarkEndY = 0.2;

Paint _checkboxMarkPaint(Color color) => Paint()
  ..color = color
  ..style = .stroke
  ..strokeCap = .round
  ..strokeJoin = .round
  ..strokeWidth = _checkboxMarkStrokeWidth;

Path _checkboxMarkPath(Size size) => Path()
  ..moveTo(size.width * _checkboxMarkStartX, size.height * _checkboxMarkStartY)
  ..lineTo(
    size.width * _checkboxMarkMiddleX,
    size.height * _checkboxMarkMiddleY,
  )
  ..lineTo(size.width * _checkboxMarkEndX, size.height * _checkboxMarkEndY);

class const _CheckboxInteraction({
  required final bool value,
  required final bool isDisabled,
  required final ValueChanged<bool>? onChanged,
  required final bool autofocus,
  required final Widget child,
}) extends StatefulWidget {
  @override
  State<_CheckboxInteraction> createState() => _CheckboxInteractionState();
}

class _CheckboxInteractionState extends State<_CheckboxInteraction> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isDisabled && widget.onChanged != null;

    return _CheckboxInteractionActions(
      isInteractive: isInteractive,
      autofocus: widget.autofocus,
      onActivate: _handleActivate,
      isDisabled: widget.isDisabled,
      value: widget.value,
      onChanged: widget.onChanged,
      isFocused: _isFocused,
      onFocusHighlight: _setFocused,
      child: widget.child,
    );
  }

  void _setFocused(bool value) => setState(() => _isFocused = value);

  Null _handleActivate(ActivateIntent _) {
    if (!widget.isDisabled && widget.onChanged != null) {
      widget.onChanged?.call(!widget.value);
    }

    return null;
  }
}

class const _CheckboxInteractionActions({
  required final bool isInteractive,
  required final bool autofocus,
  required final Null Function(ActivateIntent) onActivate,
  required final bool isDisabled,
  required final bool value,
  required final ValueChanged<bool>? onChanged,
  required final bool isFocused,
  required final ValueChanged<bool> onFocusHighlight,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const <ShortcutActivator, Intent>{
      SingleActivator(.enter): ActivateIntent(),
      SingleActivator(.space): ActivateIntent(),
    },
    child: _CheckboxActions(
      onActivate: onActivate,
      child: _CheckboxInteractionFocus(
        isInteractive: isInteractive,
        autofocus: autofocus,
        isDisabled: isDisabled,
        value: value,
        onChanged: onChanged,
        isFocused: isFocused,
        onFocusHighlight: onFocusHighlight,
        child: child,
      ),
    ),
  );
}

class const _CheckboxActions({
  required final Null Function(ActivateIntent) onActivate,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Actions(
    actions: <Type, Action<Intent>>{
      ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: onActivate),
    },
    child: child,
  );
}

class const _CheckboxInteractionFocus({
  required final bool isInteractive,
  required final bool autofocus,
  required final bool isDisabled,
  required final bool value,
  required final ValueChanged<bool>? onChanged,
  required final bool isFocused,
  required final ValueChanged<bool> onFocusHighlight,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: isInteractive,
      autofocus: autofocus,
      onShowFocusHighlight: onFocusHighlight,
      mouseCursor: isInteractive
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: _CheckboxInteractionGesture(
        isInteractive: isInteractive,
        isDisabled: isDisabled,
        value: value,
        onChanged: onChanged,
        isFocused: isFocused,
        child: child,
      ),
    );
  }
}

class const _CheckboxInteractionGesture({
  required final bool isInteractive,
  required final bool isDisabled,
  required final bool value,
  required final ValueChanged<bool>? onChanged,
  required final bool isFocused,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _CheckboxGestureTarget(
      isDisabled: isDisabled,
      isFocused: isFocused,
      child: child,
    ),
    onTap: isInteractive ? () => onChanged?.call(!value) : null,
    behavior: .opaque,
    excludeFromSemantics: true,
  );
}

class const _CheckboxGestureTarget({
  required final bool isDisabled,
  required final bool isFocused,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: DesignInputSizes.heightLg,
    height: DesignInputSizes.heightLg,
    child: Center(
      child: Opacity(
        opacity: isDisabled ? 0.6 : 1,
        child: _CheckboxFocusState(isFocused: isFocused, child: child),
      ),
    ),
  );
}

class const _CheckboxFocusState({
  required final bool isFocused,
  required super.child,
}) extends InheritedWidget {
  static bool of(BuildContext context) {
    final state = context
        .dependOnInheritedWidgetOfExactType<_CheckboxFocusState>();

    return state?.isFocused ?? false;
  }

  @override
  bool updateShouldNotify(_CheckboxFocusState oldWidget) {
    return isFocused != oldWidget.isFocused;
  }
}

class const _CheckboxVisual({
  required final bool value,
  required final AuraTint? tint,
  required final bool disabled,
  required final bool isFocused,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final activeColor = _getActiveColor(context);
    final borderColor = disabled ? auraColors.outlineVariant : activeColor;

    return _CheckboxVisualContainer(
      value: value,
      activeColor: activeColor,
      borderColor: borderColor,
      markColor: auraColors.onTint(tint ?? AuraTint.primary),
      isFocused: isFocused,
    );
  }

  Color _getActiveColor(BuildContext context) {
    final auraColors = context.auraColors;

    return auraColors.colorFor(tint ?? AuraTint.primary);
  }
}

class const _CheckboxVisualContainer({
  required final bool value,
  required final Color activeColor,
  required final Color borderColor,
  required final Color markColor,
  required final bool isFocused,
}) extends StatelessWidget {
  static const _boxSize = 24.0;
  static const _checkMarkSize = 12.0;
  static const _focusedBorderWidth = 3.0;
  static const _defaultBorderWidth = 2.0;

  @override
  Widget build(BuildContext context) => _CheckboxAnimatedBox(
    decoration: _checkboxDecoration(
      fillColor: value ? activeColor : DesignColors.transparent,
      borderColor: borderColor,
      borderWidth: isFocused ? _focusedBorderWidth : _defaultBorderWidth,
    ),
    child: value
        ? _CheckboxVisualMark(color: markColor, size: _checkMarkSize)
        : null,
  );
}

class const _CheckboxAnimatedBox({
  required final BoxDecoration decoration,
  required final Widget? child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    alignment: Alignment.center,
    decoration: decoration,
    width: _CheckboxVisualContainer._boxSize,
    height: _CheckboxVisualContainer._boxSize,
    duration: context.auraTheme.animation.fast,
    child: child,
  );
}

BoxDecoration _checkboxDecoration({
  required Color fillColor,
  required Color borderColor,
  required double borderWidth,
}) {
  return BoxDecoration(
    color: fillColor,
    border: Border.all(color: borderColor, width: borderWidth),
    borderRadius: const BorderRadius.all(.circular(4)),
  );
}

class const _CheckboxVisualMark({
  required final Color color,
  required final double size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CheckboxMarkPainter(color: color)),
    );
  }
}
