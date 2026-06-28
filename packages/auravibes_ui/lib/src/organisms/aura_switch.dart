// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A customizable switch component following the Aura design system.
///
/// This switch supports multiple sizes and states (on/off, disabled, loading)
/// while maintaining consistency with the design tokens.
class AuraSwitch extends StatefulWidget {
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
  State<AuraSwitch> createState() => _AuraSwitchState();
}

class _AuraSwitchState extends State<AuraSwitch> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;

    final onChanged = widget.onChanged;
    final isInteractive =
        !widget.disabled && !widget.isLoading && onChanged != null;

    final trackWidth = _getTrackWidth();
    final trackHeight = _getTrackHeight();
    final thumbSize = _getThumbSize();
    final thumbPadding = _getThumbPadding();

    final thumbOffset = widget.value
        ? trackWidth - thumbSize - thumbPadding * 2
        : 0.0;

    final trackColor = _getTrackColor(auraColors);
    final thumbColor = _getThumbColor(auraColors);
    final loadingTint = _getLoadingTint();

    void handleToggle() => onChanged?.call(!widget.value);

    return Semantics(
      child: FocusableActionDetector(
        enabled: isInteractive,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              handleToggle();

              return null;
            },
          ),
        },
        mouseCursor: isInteractive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _isFocused = value),
        child: GestureDetector(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: Center(
              child: AnimatedContainer(
                padding: EdgeInsets.all(thumbPadding),
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(trackHeight / 2),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: auraColors.primary.withValues(alpha: 0.24),
                            spreadRadius: 3,
                          ),
                        ]
                      : null,
                ),
                width: trackWidth,
                height: trackHeight,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      child: AnimatedContainer(
                        decoration: BoxDecoration(
                          color: thumbColor,
                          boxShadow: widget.disabled
                              ? null
                              : [DesignShadows.sm],
                          shape: BoxShape.circle,
                        ),
                        width: thumbSize,
                        height: thumbSize,
                        child: widget.isLoading
                            ? AuraLoadingCircle(
                                tint: loadingTint,
                                size: thumbSize * 0.6,
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
          ),
          onTap: isInteractive ? handleToggle : null,
          behavior: HitTestBehavior.opaque,
        ),
      ),
      enabled: isInteractive,
      toggled: widget.value,
    );
  }

  double _getTrackWidth() {
    return switch (widget.size) {
      AuraSwitchSize.sm => 36.0,
      AuraSwitchSize.base => 44.0,
      AuraSwitchSize.lg => 52.0,
    };
  }

  double _getTrackHeight() {
    return switch (widget.size) {
      AuraSwitchSize.sm => 20.0,
      AuraSwitchSize.base => 24.0,
      AuraSwitchSize.lg => 28.0,
    };
  }

  double _getThumbSize() {
    return switch (widget.size) {
      AuraSwitchSize.sm => 16.0,
      AuraSwitchSize.base => 20.0,
      AuraSwitchSize.lg => 24.0,
    };
  }

  double _getThumbPadding() => AuraSwitch._thumbPadding;

  Color _getTrackColor(AuraColorScheme colors) {
    if (widget.disabled) {
      return colors.outlineVariant;
    }

    return widget.value ? colors.primary : colors.outline;
  }

  Color _getThumbColor(AuraColorScheme colors) => colors.surface;

  AuraTint _getLoadingTint() => AuraTint.primary;
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
