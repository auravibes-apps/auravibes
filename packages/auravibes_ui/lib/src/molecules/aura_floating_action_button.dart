import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/atoms/aura_tooltip.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable floating action button component following the Aura design
/// system.
///
/// This FAB supports different sizes, icons, extended variants with text,
/// and proper elevation and shadows.
class AuraFloatingActionButton extends StatelessWidget {
  /// Creates a Aura floating action button.
  const AuraFloatingActionButton({
    required this.onPressed,
    required this.icon,
    super.key,
    this.size = AuraFABSize.regular,
    this.tint,
    this.heroTag = const ValueKey<String>('aura_floating_action_button'),
    this.semanticLabel,
    this.tooltip,
  }) : text = null;

  /// Creates an extended Aura floating action button with text.
  const AuraFloatingActionButton.extended({
    required this.onPressed,
    required this.icon,
    required this.text,
    super.key,
    this.tint,
    this.heroTag = const ValueKey<String>('aura_floating_action_button'),
    this.semanticLabel,
    this.tooltip,
  }) : size = AuraFABSize.extended;

  /// The callback that is called when the button is pressed.
  final VoidCallback? onPressed;

  /// The icon to display.
  final IconData icon;

  /// The text to display (only for extended variant).
  final String? text;

  /// The size of the FAB.
  final AuraFABSize size;

  /// The tint of the FAB. If null, uses the primary tint.
  final AuraTint? tint;

  /// The tag used for the FAB hero animation.
  ///
  /// Set to null to disable hero animations when multiple FABs are present.
  final LocalKey? heroTag;

  /// A semantic label for the FAB for accessibility.
  final String? semanticLabel;

  /// The tooltip message to display when the FAB is long-pressed.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final labelText = text;
    final resolvedTint = tint ?? AuraTint.primary;
    final resolvedBackground = auraColors.colorFor(resolvedTint);
    final resolvedForeground = auraColors.onTint(resolvedTint);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(
        context.auraTheme.fromBorderRadius(_getBorderRadius()),
      ),
    );

    Widget fab;
    if (size == AuraFABSize.extended && labelText != null) {
      fab = FloatingActionButton.extended(
        foregroundColor: resolvedForeground,
        backgroundColor: resolvedBackground,
        heroTag: heroTag,
        elevation: _getElevation(),
        focusElevation: _getFocusElevation(),
        hoverElevation: _getHoverElevation(),
        highlightElevation: _getHighlightElevation(),
        onPressed: onPressed,
        shape: shape,
        icon: Icon(icon, color: resolvedForeground),
        label: AuraText(
          child: Text(
            labelText,
            style: TextStyle(
              color: resolvedForeground,
              fontWeight: context.auraTheme.typography.fontWeightMedium,
            ),
          ),
        ),
      );
    } else {
      fab = FloatingActionButton(
        child: Icon(
          icon,
          size: _getIconPixels(),
          color: resolvedForeground,
        ),
        foregroundColor: resolvedForeground,
        backgroundColor: resolvedBackground,
        heroTag: heroTag,
        elevation: _getElevation(),
        focusElevation: _getFocusElevation(),
        hoverElevation: _getHoverElevation(),
        highlightElevation: _getHighlightElevation(),
        onPressed: onPressed,
        shape: shape,
      );

      if (size == AuraFABSize.mini || size == AuraFABSize.large) {
        fab = SizedBox(
          width: _getFABSize(),
          height: _getFABSize(),
          child: fab,
        );
      }
    }

    final tooltip = this.tooltip;
    if (tooltip != null) {
      fab = AuraTooltip(
        message: tooltip,
        child: fab,
      );
    }

    if (semanticLabel != null) {
      fab = Semantics(
        child: fab,
        button: true,
        label: semanticLabel,
      );
    }

    return fab;
  }

  double _getFABSize() {
    return switch (size) {
      AuraFABSize.mini => 40.0,
      AuraFABSize.regular => 56.0,
      AuraFABSize.large => 72.0,
      AuraFABSize.extended => 56.0, // Height for extended.
    };
  }

  double _getIconPixels() {
    return switch (size) {
      AuraFABSize.mini => 16,
      AuraFABSize.regular => 20,
      AuraFABSize.large => 24,
      AuraFABSize.extended => 20,
    };
  }

  AuraBorderRadius _getBorderRadius() {
    return switch (size) {
      AuraFABSize.mini => .lg,
      AuraFABSize.regular => .xl,
      AuraFABSize.large => .xl,
      AuraFABSize.extended => .xl,
    };
  }

  double _getElevation() {
    return DesignElevation.md;
  }

  double _getFocusElevation() {
    return DesignElevation.lg;
  }

  double _getHoverElevation() {
    return DesignElevation.lg;
  }

  double _getHighlightElevation() {
    return DesignElevation.xl;
  }
}

/// The size of a [AuraFloatingActionButton].
enum AuraFABSize {
  /// Mini FAB (40x40).
  mini,

  /// Regular FAB (56x56) - default.
  regular,

  /// Large FAB (72x72).
  large,

  /// Extended FAB with text.
  extended,
}
