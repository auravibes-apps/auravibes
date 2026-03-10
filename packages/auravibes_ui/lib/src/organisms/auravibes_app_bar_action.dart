import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/molecules/auravibes_badge.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable app bar action button component following the Aura design
/// system.
///
/// This action button is specifically designed for use in app bars and provides
/// proper touch targets, badge support, and accessibility features.
class AuraAppBarAction extends StatelessWidget {
  /// Creates a Aura app bar action button.
  const AuraAppBarAction({
    required this.icon,
    required this.onPressed,
    super.key,
    this.badge,
    this.color,
    this.semanticLabel,
    this.tooltip,
  });

  /// The icon to display.
  final IconData icon;

  /// The callback that is called when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional badge to display on the action button.
  final AuraBadge? badge;

  /// The color of the icon. If null, uses the default app bar icon color.
  final Color? color;

  /// A semantic label for the button for accessibility.
  final String? semanticLabel;

  /// The tooltip message to display when the button is long-pressed.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final iconColor = color ?? _getDefaultIconColor(context, auraColors);

    Widget actionButton = IconButton(
      onPressed: onPressed,
      icon: AuraIcon(
        icon,
        color: AuraColorVariant.onSurfaceVariant,
        semanticLabel: semanticLabel,
      ),
      iconSize: 24,
      padding: const EdgeInsets.all(DesignSpacing.sm),
      constraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 48,
      ),
      style: IconButton.styleFrom(
        foregroundColor: iconColor,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignBorderRadius.md),
        ),
      ),
    );

    if (badge != null) {
      actionButton = AuraPositionedBadge(
        badge: badge!,
        offset: const Offset(-4, 4),
        child: actionButton,
      );
    }

    if (tooltip != null) {
      actionButton = Tooltip(
        message: tooltip,
        child: actionButton,
      );
    }

    return actionButton;
  }

  Color _getDefaultIconColor(BuildContext context, AuraColorScheme auraColors) {
    // Check if there's an AppBar theme with foreground color
    final appBarTheme = Theme.of(context).appBarTheme;
    if (appBarTheme.foregroundColor != null) {
      return appBarTheme.foregroundColor!;
    }
    return auraColors.onSurface;
  }
}
