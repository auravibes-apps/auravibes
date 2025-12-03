import 'package:auravibes_ui/src/atoms/auravibes_loading.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
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

    return GestureDetector(
      onTap: isInteractive ? () => onChanged!(!value) : null,
      child: MouseRegion(
        cursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: auraTheme.animation.normal,
          width: trackWidth,
          height: trackHeight,
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(trackHeight / 2),
          ),
          padding: EdgeInsets.all(thumbPadding),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: auraTheme.animation.normal,
                curve: Curves.easeInOut,
                left: thumbOffset,
                top: 0,
                bottom: 0,
                child: AnimatedContainer(
                  duration: auraTheme.animation.normal,
                  width: thumbSize,
                  height: thumbSize,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    shape: BoxShape.circle,
                    boxShadow: disabled ? null : [DesignShadows.sm],
                  ),
                  child: isLoading
                      ? Center(
                          child: SizedBox(
                            width: thumbSize * 0.6,
                            height: thumbSize * 0.6,
                            child: AuraLoadingCircle(
                              size: thumbSize * 0.6,
                              color: value
                                  ? auraColors.primary
                                  : auraColors.onSurfaceVariant,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
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

  double _getThumbPadding() {
    return 2;
  }

  Color _getTrackColor(AuraColorScheme colors) {
    if (disabled) {
      return colors.outlineVariant;
    }
    return value ? colors.primary : colors.outline;
  }

  Color _getThumbColor(AuraColorScheme colors) {
    if (disabled) {
      return colors.surface;
    }
    return colors.surface;
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
