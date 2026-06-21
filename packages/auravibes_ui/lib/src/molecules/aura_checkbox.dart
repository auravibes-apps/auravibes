// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart'
    show AuraColorVariant, DesignColors;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// An Aura checkbox that follows the const-first design system.
class AuraCheckbox extends StatelessWidget {
  /// Creates an Aura checkbox.
  const AuraCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
    this.colorVariant,
    this.disabled = false,
    this.autofocus = false,
  }) : _visualOnly = false;

  const AuraCheckbox._visual({
    required this.value,
    required this.colorVariant,
    required this.disabled,
  }) : onChanged = null,
       autofocus = false,
       _visualOnly = true;

  /// Whether the checkbox is selected.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Color variant used when selected.
  final AuraColorVariant? colorVariant;

  /// Whether the checkbox is disabled.
  final bool disabled;

  /// Whether this checkbox should request focus when built.
  final bool autofocus;

  final bool _visualOnly;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;

    if (_visualOnly) {
      final isFocused = _CheckboxFocusState.of(context);

      return _CheckboxVisual(
        value: value,
        colorVariant: colorVariant,
        disabled: isDisabled,
        isFocused: isFocused,
      );
    }

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
              colorVariant: colorVariant,
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

const _checkIcon = IconData(0xe5ca, fontFamily: 'MaterialIcons');

/// A full-width settings row with an Aura checkbox, title, and optional
/// subtitle.
class AuraCheckboxListTile extends StatelessWidget {
  /// Creates an Aura checkbox list tile.
  const AuraCheckboxListTile({
    required this.value,
    required this.onChanged,
    required this.title,
    super.key,
    this.subtitle,
    this.colorVariant,
    this.disabled = false,
    this.autofocus = false,
  });

  /// Whether the checkbox is selected.
  final bool value;

  /// Called when the user toggles the checkbox.
  final ValueChanged<bool>? onChanged;

  /// The title widget.
  final Widget title;

  /// Optional subtitle widget.
  final Widget? subtitle;

  /// Color variant used when selected.
  final AuraColorVariant? colorVariant;

  /// Whether the tile is disabled.
  final bool disabled;

  /// Whether this checkbox tile should request focus when built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;
    final subtitle = this.subtitle;

    return Semantics(
      child: _CheckboxInteraction(
        value: value,
        isDisabled: isDisabled,
        onChanged: onChanged,
        autofocus: autofocus,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuraCheckbox._visual(
              value: value,
              colorVariant: colorVariant,
              disabled: isDisabled,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AuraText(child: title),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    AuraText(
                      child: subtitle,
                      style: AuraTextStyle.bodySmall,
                      color: AuraColorVariant.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      enabled: !isDisabled,
      checked: value,
    );
  }
}

class _CheckboxInteraction extends StatefulWidget {
  const _CheckboxInteraction({
    required this.value,
    required this.isDisabled,
    required this.onChanged,
    required this.autofocus,
    required this.child,
  });

  final bool value;
  final bool isDisabled;
  final ValueChanged<bool>? onChanged;
  final bool autofocus;
  final Widget child;

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
            onInvoke: (_) {
              if (isInteractive) {
                widget.onChanged?.call(!widget.value);
              }

              return null;
            },
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
            child: Opacity(
              opacity: widget.isDisabled ? 0.6 : 1,
              child: _CheckboxFocusState(
                isFocused: _isFocused,
                child: widget.child,
              ),
            ),
            onTap: isInteractive
                ? () => widget.onChanged?.call(!widget.value)
                : null,
            behavior: HitTestBehavior.opaque,
          ),
        ),
      ),
    );
  }
}

class _CheckboxFocusState extends InheritedWidget {
  const _CheckboxFocusState({
    required this.isFocused,
    required super.child,
  });

  final bool isFocused;

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

class _CheckboxVisual extends StatelessWidget {
  const _CheckboxVisual({
    required this.value,
    required this.colorVariant,
    required this.disabled,
    required this.isFocused,
  });

  final bool value;
  final AuraColorVariant? colorVariant;
  final bool disabled;
  final bool isFocused;

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
      width: 24,
      height: 24,
      child: value
          ? const AuraIcon(
              _checkIcon,
              size: AuraIconSize.extraSmall,
              color: AuraColorVariant.onPrimary,
            )
          : null,
      duration: context.auraTheme.animation.fast,
    );
  }

  Color _getActiveColor(BuildContext context) {
    final auraColors = context.auraColors;

    return auraColors.getColorOrNull(colorVariant) ?? auraColors.primary;
  }
}
