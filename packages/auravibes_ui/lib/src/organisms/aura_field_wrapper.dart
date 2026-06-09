// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_field_label.dart';
import 'package:auravibes_ui/src/atoms/aura_pressable.dart';
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
  const AuraFieldWrapper({
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

  /// A semantic label for the field for accessibility.
  final String? semanticLabel;

  /// A semantic description for the field for accessibility.
  final String? semanticDescription;

  @override
  State<AuraFieldWrapper> createState() => _AuraFieldWrapperState();
}

class _AuraFieldWrapperState extends State<AuraFieldWrapper> {
  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final label = widget.label;

    return Semantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null)
            AuraFieldLabel(child: label, isRequired: widget.isRequired),
          if (label != null) const SizedBox(height: DesignSpacing.xs),
          AuraPressable(
            child: AnimatedContainer(
              decoration: BoxDecoration(
                // Color: _getBackgroundColor(auraColors),.
                border: Border.all(
                  color: _getBorderColor(auraColors),
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(DesignBorderRadius.xl),
                ),
                boxShadow: _getBoxShadow(auraColors),
              ),
              child: widget.child,
              duration: DesignDuration.normal,
            ),
            color: auraColors.primary,
            decoration: BoxDecoration(
              color: _getBackgroundColor(auraColors),
              borderRadius: const BorderRadius.all(
                Radius.circular(DesignBorderRadius.xl),
              ),
              // Color: auraColors.primary,.
            ),
            onPressed: widget.isEnabled ? widget.onTap : null,
          ),
          if (widget.hint != null || widget.error != null)
            const SizedBox(height: DesignSpacing.xs),
          if (widget.hint != null || widget.error != null)
            AuraFieldHint(text: widget.hint, error: widget.error),
        ],
      ),
      label: widget.semanticLabel,
    );
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (!widget.isEnabled) return colors.surfaceVariant.withValues(alpha: 0.5);
    if (widget.isReadOnly) return colors.surfaceVariant;

    return colors.surface;
  }

  Color _getBorderColor(AuraColorScheme colors) {
    if (!widget.isEnabled) return colors.outlineVariant;

    return switch (widget.state) {
      AuraFieldState.normal =>
        widget.isFocused ? colors.primary : colors.outline,
      AuraFieldState.success => colors.success,
      AuraFieldState.warning => colors.warning,
      AuraFieldState.error => colors.error,
    };
  }

  List<BoxShadow>? _getBoxShadow(AuraColorScheme colors) {
    if (!widget.isEnabled || widget.isReadOnly) return null;

    if (widget.isFocused && widget.state != AuraFieldState.error) {
      return [
        BoxShadow(
          color: colors.primary.withValues(alpha: 0.1),
          blurRadius: 4,
          spreadRadius: 2,
        ),
      ];
    }

    if (widget.state == AuraFieldState.error) {
      return [
        BoxShadow(
          color: colors.error.withValues(alpha: 0.1),
          blurRadius: 4,
          spreadRadius: 2,
        ),
      ];
    }

    return null;
  }
}

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
