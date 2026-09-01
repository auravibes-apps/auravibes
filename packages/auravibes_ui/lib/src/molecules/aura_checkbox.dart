// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraTint, DesignColors;
import 'package:flutter/services.dart';
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
    final isDisabled = disabled || onChanged == null;

    return Semantics(
      child: _CheckboxInteraction(
        value: value,
        isDisabled: isDisabled,
        onChanged: onChanged,
        autofocus: autofocus,
        child: Builder(
          builder: (context) {
            final isFocused = _CheckboxFocusState.of(context);

            return _CheckboxVisual(
              value: value,
              tint: tint,
              disabled: isDisabled,
              isFocused: isFocused,
            );
          },
        ),
      ),
      enabled: !isDisabled,
      checked: value,
    );
  }
}

class const _CheckboxMarkPainter({required final Color color})
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.5)
      ..lineTo(size.width * 0.4, size.height * 0.8)
      ..lineTo(size.width * 0.9, size.height * 0.2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckboxMarkPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

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

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: _handleActivate,
          ),
        },
        child: FocusableActionDetector(
          enabled: isInteractive,
          autofocus: widget.autofocus,
          onShowFocusHighlight: (value) => setState(() {
            _isFocused = value;
          }),
          mouseCursor: isInteractive
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: GestureDetector(
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Opacity(
                  opacity: widget.isDisabled ? 0.6 : 1,
                  child: _CheckboxFocusState(
                    isFocused: _isFocused,
                    child: widget.child,
                  ),
                ),
              ),
            ),
            onTap: isInteractive
                ? () => widget.onChanged?.call(!widget.value)
                : null,
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }

  Null _handleActivate(ActivateIntent _) {
    if (!widget.isDisabled && widget.onChanged != null) {
      widget.onChanged?.call(!widget.value);
    }

    return null;
  }
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
  static const _boxSize = 24.0;
  static const _checkMarkSize = 12.0;
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final activeColor = _getActiveColor(context);
    final borderColor = disabled ? auraColors.outlineVariant : activeColor;

    return AnimatedContainer(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value ? activeColor : DesignColors.transparent,
        border: Border.all(color: borderColor, width: isFocused ? 3 : 2),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      width: _boxSize,
      height: _boxSize,
      child: value
          ? SizedBox(
              width: _checkMarkSize,
              height: _checkMarkSize,
              child: CustomPaint(
                painter: _CheckboxMarkPainter(
                  color: auraColors.onTint(tint ?? AuraTint.primary),
                ),
              ),
            )
          : null,
      duration: context.auraTheme.animation.fast,
    );
  }

  Color _getActiveColor(BuildContext context) {
    final auraColors = context.auraColors;

    return auraColors.colorFor(tint ?? AuraTint.primary);
  }
}
