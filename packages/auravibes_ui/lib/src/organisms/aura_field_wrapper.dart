// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_field_label.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/molecules/aura_field_hint.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable field wrapper component following the Aura design system.
///
/// This wrapper provides consistent visual styling for all input components
/// with borders, background colors, focus states, and error handling.
class AuraFieldWrapper extends StatefulWidget {
  /// Creates a Aura field wrapper.
  const new({
    required this.child,
    super.key,
    this.label,
    this.hint,
    this.error,
    this.isRequired = false,
    this.state = AuraFieldState.normal,
    this.isEnabled = true,
    this.isReadOnly = false,
    this.isFocused = false,
    this.onTap,
    this.onFocusChange,
    this.semanticLabel,
    this.semanticDescription,
  });

  /// The child widget to be wrapped (typically an input component).
  final Widget child;

  /// Optional label text to display above the field.
  final Widget? label;

  /// Optional hint text to display below the field.
  final Widget? hint;

  /// Optional error text to display below the field.
  final Widget? error;

  /// Whether the field is required.
  final bool isRequired;

  /// The visual state of the field.
  final AuraFieldState state;

  /// Whether the field is enabled.
  final bool isEnabled;

  /// Whether the field is read-only.
  final bool isReadOnly;

  /// Whether the field is currently focused.
  final bool isFocused;

  /// Callback when the field is tapped.
  final VoidCallback? onTap;

  /// Called when keyboard focus changes.
  final ValueChanged<bool>? onFocusChange;

  /// A semantic label for the field for accessibility.
  final String? semanticLabel;

  /// A semantic description for the field for accessibility.
  final String? semanticDescription;

  @override
  State<AuraFieldWrapper> createState() => _AuraFieldWrapperState();
}

class _AuraFieldWrapperState extends State<AuraFieldWrapper> {
  static const _disabledAlpha = 0.5;
  static const _focusAlpha = 0.1;
  static const _focusBlurRadius = 4.0;
  static const _focusSpreadRadius = 2.0;
  @override
  Widget build(BuildContext context) => _AuraFieldWrapperView.fromField(
    context: context,
    field: widget,
    colors: context.auraColors,
  );
}

class _AuraFieldWrapperView extends StatelessWidget {
  const new({required this.label, required this.child});

  new fromField({
    required BuildContext context,
    required AuraFieldWrapper field,
    required AuraColorScheme colors,
  }) : this(
         label: field.semanticLabel,
         child: _AuraFieldWrapperBody(
           children: [
             _AuraFieldWrapperLabel(field: field),
             _AuraFieldWrapperInputData.fromContext(
               context: context,
               field: field,
               colors: colors,
             ),
             _AuraFieldWrapperSupportingContent(field: field),
           ],
         ),
       );

  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(child: child, label: label);
}

class const _AuraFieldWrapperBody({required final List<Widget> children})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .start,
    children: children,
  );
}

class const _AuraFieldWrapperLabel({required final AuraFieldWrapper field})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final label = field.label;
    if (label == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        AuraFieldLabel(child: label, isRequired: field.isRequired),
        const AuraSizedBox(height: .xs),
      ],
    );
  }
}

class const _AuraFieldWrapperSupportingContent({
  required final AuraFieldWrapper field,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (field.hint == null && field.error == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .start,
      children: [
        const AuraSizedBox(height: .xs),
        AuraFieldHint(text: field.hint, error: field.error),
      ],
    );
  }
}

class _AuraFieldWrapperInputData extends StatelessWidget {
  const new({
    required this.child,
    required this.color,
    required this.decoration,
    required this.onPressed,
    required this.onFocusChange,
  });

  new fromContext({
    required BuildContext context,
    required AuraFieldWrapper field,
    required AuraColorScheme colors,
  }) : this(
         child: AnimatedContainer(
           decoration: _fieldInputDecoration(
             _fieldBorderColor(field, colors),
             _fieldBorderRadius(context),
             _fieldBoxShadow(field, colors),
           ),
           child: field.child,
           duration: DesignDuration.normal,
         ),
         color: colors.primary,
         decoration: _fieldSurfaceDecoration(
           _fieldBackgroundColor(field, colors),
           _fieldBorderRadius(context),
         ),
         onPressed: field.isEnabled ? field.onTap : null,
         onFocusChange: field.onFocusChange,
       );

  final Widget child;
  final Color color;
  final BoxDecoration decoration;
  final VoidCallback? onPressed;
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context) => AuraPressable(
    child: child,
    color: color,
    decoration: decoration,
    onPressed: onPressed,
    onFocusChange: onFocusChange,
  );
}

Color _fieldBackgroundColor(AuraFieldWrapper field, AuraColorScheme colors) {
  if (!field.isEnabled) {
    return colors.surfaceVariant.withValues(
      alpha: _AuraFieldWrapperState._disabledAlpha,
    );
  }
  if (field.isReadOnly) return colors.surfaceVariant;

  return colors.surface;
}

Color _fieldBorderColor(AuraFieldWrapper field, AuraColorScheme colors) {
  if (!field.isEnabled) return colors.outlineVariant;

  return switch (field.state) {
    .normal => field.isFocused ? colors.primary : colors.outline,
    .success => colors.success,
    .warning => colors.warning,
    .error => colors.error,
  };
}

List<BoxShadow>? _fieldBoxShadow(
  AuraFieldWrapper field,
  AuraColorScheme colors,
) {
  if (!field.isEnabled || field.isReadOnly) return null;
  if (field.state == AuraFieldState.error) {
    return _fieldBuildBoxShadow(colors.error);
  }
  if (field.isFocused) return _fieldBuildBoxShadow(colors.primary);

  return null;
}

List<BoxShadow> _fieldBuildBoxShadow(Color color) => [
  BoxShadow(
    color: color.withValues(alpha: _AuraFieldWrapperState._focusAlpha),
    blurRadius: _AuraFieldWrapperState._focusBlurRadius,
    spreadRadius: _AuraFieldWrapperState._focusSpreadRadius,
  ),
];

BorderRadius _fieldBorderRadius(BuildContext context) =>
    BorderRadius.all(.circular(context.auraTheme.fromBorderRadius(.xl)));

BoxDecoration _fieldSurfaceDecoration(
  Color backgroundColor,
  BorderRadius borderRadius,
) => BoxDecoration(color: backgroundColor, borderRadius: borderRadius);

BoxDecoration _fieldInputDecoration(
  Color borderColor,
  BorderRadius borderRadius,
  List<BoxShadow>? boxShadow,
) => BoxDecoration(
  border: Border.all(color: borderColor),
  borderRadius: borderRadius,
  boxShadow: boxShadow,
);

/// The visual state of a [AuraFieldWrapper].
enum AuraFieldState {
  /// Normal state.
  normal,

  /// Success state (green border).
  success,

  /// Warning state (yellow border).
  warning,

  /// Error state (red border).
  error,
}
