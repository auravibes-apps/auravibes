import 'package:auravibes_ui/src/atoms/auravibes_icon.dart';
import 'package:auravibes_ui/src/atoms/auravibes_text.dart';
import 'package:auravibes_ui/src/molecules/auravibes_badge.dart';
import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable tab item component following the Aura design system.
///
/// This tab item supports icons, text, badges, and active/inactive states
/// for use in tab bars and tab navigation contexts.
class AuraTabItem extends StatelessWidget {
  /// Creates a Aura tab item.
  const AuraTabItem({
    required this.onTap,
    super.key,
    this.icon,
    this.text,
    this.badge,
    this.isActive = false,
    this.semanticLabel,
  });

  /// The callback that is called when the tab is tapped.
  final VoidCallback? onTap;

  /// The icon to display.
  final IconData? icon;

  /// The text to display.
  final String? text;

  /// Optional badge to display on the tab.
  final AuraBadge? badge;

  /// Whether the tab is in an active state.
  final bool isActive;

  /// A semantic label for the tab for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    var content = _buildContent(auraColors);

    if (badge != null) {
      content = AuraPositionedBadge(
        badge: badge!,
        offset: const Offset(-4, 4),
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
          borderRadius: BorderRadius.circular(DesignBorderRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignSpacing.md,
              vertical: DesignSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: _getIndicatorColor(auraColors),
                  width: isActive ? 2.0 : 0.0,
                ),
              ),
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AuraColorScheme auraColors) {
    final iconColorVariant = _getIconColor();
    final textColor = _getTextColor(auraColors);
    final isDisabled = onTap == null;

    Widget buildIcon() {
      final iconWidget = AuraIcon(
        icon!,
        color: iconColorVariant,
      );
      // Apply opacity for disabled state to match text behavior
      return isDisabled ? Opacity(opacity: 0.6, child: iconWidget) : iconWidget;
    }

    if (icon != null && text != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildIcon(),
          const SizedBox(height: DesignSpacing.xs),
          AuraText(
            style: AuraTextStyle.caption,
            child: Text(
              text!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: isActive
                    ? DesignTypography.fontWeightMedium
                    : DesignTypography.fontWeightRegular,
              ),
            ),
          ),
        ],
      );
    }

    if (icon != null) {
      return buildIcon();
    }

    if (text != null) {
      return AuraText(
        child: Text(
          text!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontWeight: isActive
                ? DesignTypography.fontWeightMedium
                : DesignTypography.fontWeightRegular,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getIndicatorColor(AuraColorScheme auraColors) {
    if (!isActive) return Colors.transparent;
    return auraColors.primary;
  }

  AuraColorVariant _getIconColor() {
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
