// ignore_for_file: no-magic-number
// Required: UI tokens and layout use fixed design values.
// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.
// ignore_for_file: no-equal-arguments
// Required: UI geometry uses repeated values for symmetric layout.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A customizable switch component following the Aura design system.
///
/// This switch supports multiple sizes and states (on/off, disabled, loading)
/// while maintaining consistency with the design tokens.
class AuraSwitch extends StatelessWidget {
  /// Creates an Aura switch.
  const AuraSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.size = AuraSwitchSize.base,
    this.disabled = false,
    this.isLoading = false,
  });

  /// The padding between the track edge and the thumb.
  /// This creates the visual gap that makes the thumb appear to float
  /// inside the track, consistent across all sizes.
  static const double _thumbPadding = 2;

  /// Whether the switch is on or off.
  final bool value;

  /// Called when the user toggles the switch.
  ///
  /// This callback is not called when the switch is disabled or loading.
  final ValueChanged<bool>? onChanged;

  /// The size of the switch.
  final AuraSwitchSize size;

  /// Whether the switch is disabled.
  final bool disabled;

  /// Whether the switch is in a loading state.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;

    final isInteractive = !disabled && !isLoading && onChanged != null;

    final trackWidth = _getTrackWidth();
    final trackHeight = _getTrackHeight();
    final thumbSize = _getThumbSize();
    final thumbPadding = _getThumbPadding();

    final thumbOffset = value ? trackWidth - thumbSize - thumbPadding * 2 : 0.0;

    final trackColor = _getTrackColor(auraColors);
    final thumbColor = _getThumbColor(auraColors);
    final loadingColorVariant = _getLoadingColorVariant();

    return GestureDetector(
      child: MouseRegion(
        cursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          padding: EdgeInsets.all(thumbPadding),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(trackHeight / 2),
          ),
          width: trackWidth,
          height: trackHeight,
          child: Stack(
            children: [
              AnimatedPositioned(
                child: AnimatedContainer(
                  decoration: BoxDecoration(
                    color: thumbColor,
                    boxShadow: disabled ? null : [DesignShadows.sm],
                    shape: BoxShape.circle,
                  ),
                  width: thumbSize,
                  height: thumbSize,
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            width: thumbSize * 0.6,
                            height: thumbSize * 0.6,
                            child: AuraLoadingCircle(
                              colorVariant: loadingColorVariant,
                              size: thumbSize * 0.6,
                            ),
                          ),
                        )
                      : null,
                  duration: auraTheme.animation.normal,
                ),
                left: thumbOffset,
                top: 0,
                bottom: 0,
                curve: Curves.easeInOut,
                duration: auraTheme.animation.normal,
              ),
            ],
          ),
          duration: auraTheme.animation.normal,
        ),
      ),
      onTap: isInteractive ? () => onChanged!(!value) : null,
    );
  }

  double _getTrackWidth() {
    return switch (size) {
      AuraSwitchSize.sm => 36.0,
      AuraSwitchSize.base => 44.0,
      AuraSwitchSize.lg => 52.0,
    };
  }

  double _getTrackHeight() {
    return switch (size) {
      AuraSwitchSize.sm => 20.0,
      AuraSwitchSize.base => 24.0,
      AuraSwitchSize.lg => 28.0,
    };
  }

  double _getThumbSize() {
    return switch (size) {
      AuraSwitchSize.sm => 16.0,
      AuraSwitchSize.base => 20.0,
      AuraSwitchSize.lg => 24.0,
    };
  }

  double _getThumbPadding() => _thumbPadding;

  Color _getTrackColor(AuraColorScheme colors) {
    if (disabled) {
      return colors.outlineVariant;
    }
    return value ? colors.primary : colors.outline;
  }

  Color _getThumbColor(AuraColorScheme colors) => colors.surface;

  AuraColorVariant _getLoadingColorVariant() {
    if (value) return AuraColorVariant.primary;
    return AuraColorVariant.onSurfaceVariant;
  }
}

/// The size of an [AuraSwitch].
enum AuraSwitchSize {
  /// A small switch.
  sm,

  /// A base/medium switch (default).
  base,

  /// A large switch.
  lg,
}
