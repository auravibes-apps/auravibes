import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/molecules/auravibes_badge.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable navigation item component following the Aura design system.
///
/// This navigation item supports icons, text, badges, and different states
/// for use in navigation bars, drawers, and other navigation contexts.
class AuraNavigationItem extends StatelessWidget {
  /// Creates a Aura navigation item.
  const AuraNavigationItem({
    required this.onTap,
    super.key,
    this.icon,
    this.text,
    this.badge,
    this.isActive = false,
    this.size = AuraNavigationItemSize.normal,
    this.semanticLabel,
  });

  /// The callback that is called when the item is tapped.
  final VoidCallback? onTap;

  /// The icon to display.
  final IconData? icon;

  /// The text to display.
  final String? text;

  /// Optional badge to display on the item.
  final AuraBadge? badge;

  /// Whether the item is in an active state.
  final bool isActive;

  /// The size of the navigation item.
  final AuraNavigationItemSize size;

  /// A semantic label for the item for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    var content = _buildContent(auraColors);

    if (badge != null) {
      content = AuraPositionedBadge(
        badge: badge!,
        child: content,
      );
    }

    return Semantics(
      label: semanticLabel ?? text,
      selected: isActive,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_getBorderRadius()),
          child: Container(
            padding: _getPadding(),
            decoration: BoxDecoration(
              color: _getBackgroundColor(auraColors),
              borderRadius: BorderRadius.circular(_getBorderRadius()),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AuraColorScheme auraColors) {
    final iconColor = _getIconColor(auraColors);
    final textColor = _getTextColor(auraColors);

    return switch (size) {
      AuraNavigationItemSize.compact => _buildCompactContent(
        iconColor,
        textColor,
      ),
      AuraNavigationItemSize.normal => _buildNormalContent(
        iconColor,
        textColor,
      ),
      AuraNavigationItemSize.expanded => _buildExpandedContent(
        iconColor,
        textColor,
      ),
    };
  }

  Widget _buildCompactContent(AuraColorVariant iconColor, Color textColor) {
    if (icon != null) {
      return AuraIcon(
        icon!,
        size: AuraIconSize.small,
        color: iconColor,
      );
    }

    if (text != null) {
      return AuraText(
        style: AuraTextStyle.caption,
        child: Text(
          text!,

          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildNormalContent(AuraColorVariant iconColor, Color textColor) {
    if (icon != null && text != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuraIcon(
            icon!,
            color: iconColor,
          ),
          const SizedBox(height: DesignSpacing.xs),
          AuraText(
            style: AuraTextStyle.caption,
            child: Text(
              text!,

              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
              ),
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return AuraIcon(
        icon!,
        color: iconColor,
      );
    }

    if (text != null) {
      return AuraText(
        style: AuraTextStyle.bodySmall,
        child: Text(
          text!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: textColor),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildExpandedContent(AuraColorVariant iconColor, Color textColor) {
    if (icon != null && text != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuraIcon(
            icon!,
            color: iconColor,
          ),
          const SizedBox(width: DesignSpacing.sm),
          Flexible(
            child: AuraText(
              child: Text(
                text!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor),
              ),
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return AuraIcon(
        icon!,
        color: iconColor,
      );
    }

    if (text != null) {
      return AuraText(
        child: Text(
          text!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  EdgeInsets _getPadding() {
    return switch (size) {
      AuraNavigationItemSize.compact => const EdgeInsets.all(DesignSpacing.xs),
      AuraNavigationItemSize.normal => const EdgeInsets.symmetric(
        horizontal: DesignSpacing.sm,
        vertical: DesignSpacing.xs,
      ),
      AuraNavigationItemSize.expanded => const EdgeInsets.symmetric(
        horizontal: DesignSpacing.md,
        vertical: DesignSpacing.sm,
      ),
    };
  }

  double _getBorderRadius() {
    return switch (size) {
      AuraNavigationItemSize.compact => DesignBorderRadius.sm,
      AuraNavigationItemSize.normal => DesignBorderRadius.md,
      AuraNavigationItemSize.expanded => DesignBorderRadius.md,
    };
  }

  Color _getBackgroundColor(AuraColorScheme auraColors) {
    if (!isActive) return Colors.transparent;

    return auraColors.primary.withValues(alpha: 0.1);
  }

  AuraColorVariant _getIconColor(AuraColorScheme auraColors) {
    if (onTap == null) {
      return AuraColorVariant.onSurfaceVariant;
    }

    if (isActive) return AuraColorVariant.primary;

    return AuraColorVariant.onSurfaceVariant;
  }

  Color _getTextColor(AuraColorScheme auraColors) {
    if (onTap == null) {
      return auraColors.onSurfaceVariant.withValues(alpha: 0.6);
    }

    if (isActive) return auraColors.primary;

    return auraColors.onSurface;
  }
}

/// The size of a [AuraNavigationItem].
enum AuraNavigationItemSize {
  /// Compact size with minimal padding.
  compact,

  /// Normal size (default).
  normal,

  /// Expanded size with more padding and larger text.
  expanded,
}
