import 'package:auravibes_ui/src/tokens/auravibes_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable tile component following the Aura design system.
///
/// Tiles are horizontally expanded interactive elements similar to buttons
/// but designed for broader content areas and different interaction patterns.
/// They support multiple variants, sizes, and states while maintaining
/// consistency with the design tokens.
class AuraTile extends StatelessWidget {
  /// Creates a Aura tile.
  const AuraTile({
    required this.onTap,
    required this.child,
    super.key,
    this.variant = AuraTileVariant.primary,
    this.size = AuraTileSize.medium,
    this.isLoading = false,
    this.leading,
    this.trailing,
    this.enabled = true,
  });

  /// The callback that is called when the tile is tapped.
  final VoidCallback? onTap;

  /// The widget to display inside the tile.
  final Widget child;

  /// The visual variant of the tile.
  final AuraTileVariant variant;

  /// The size of the tile.
  final AuraTileSize size;

  /// Whether the tile is in a loading state.
  final bool isLoading;

  /// Optional widget to display before the main content.
  final Widget? leading;

  /// Optional widget to display after the main content.
  final Widget? trailing;

  /// Whether the tile is enabled for interaction.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final auraTheme = context.auraTheme;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (enabled && !isLoading) ? onTap : null,
          borderRadius: BorderRadius.circular(auraTheme.borderRadius.lg),
          child: AnimatedContainer(
            duration: auraTheme.animation.normal,
            padding: _getPadding(auraTheme.spacing),
            decoration: BoxDecoration(
              color: _getBackgroundColor(auraColors),
              borderRadius: BorderRadius.circular(auraTheme.borderRadius.lg),
              border: _getBorder(auraColors),
              boxShadow: _getBoxShadow(),
            ),
            child: _buildContent(auraColors, auraTheme),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(AuraColorScheme colors, AuraTheme theme) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getLoadingColor(colors),
            ),
          ),
        ),
      );
    }

    // Check if child is effectively empty (like SizedBox.shrink())
    final isChildEmpty =
        child is SizedBox &&
        (child as SizedBox).width == 0 &&
        (child as SizedBox).height == 0;

    if (isChildEmpty && leading != null && trailing == null) {
      // Icon-only case: center the leading icon
      return Center(child: leading);
    }

    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: theme.spacing.sm),
        ],
        Flexible(
          fit: .tight,
          child: DefaultTextStyle(
            style: _getTextStyle(colors, theme.typography),
            child: child,
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: theme.spacing.sm),
          trailing!,
        ],
      ],
    );
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (!enabled) return colors.outlineVariant;

    return switch (variant) {
      AuraTileVariant.primary => colors.primary,
      AuraTileVariant.secondary => colors.secondary,
      AuraTileVariant.surface => colors.surface,
      AuraTileVariant.outlined => Colors.transparent,
      AuraTileVariant.ghost => Colors.transparent,
      AuraTileVariant.selected => colors.primary.withValues(alpha: 0.1),
      AuraTileVariant.success => colors.success,
      AuraTileVariant.warning => colors.warning,
      AuraTileVariant.error => colors.error,
      AuraTileVariant.info => colors.info,
    };
  }

  Border? _getBorder(AuraColorScheme colors) {
    if (variant == AuraTileVariant.outlined) {
      return Border.all(
        color: enabled ? colors.outline : colors.outlineVariant,
      );
    }
    return null;
  }

  List<BoxShadow> _getBoxShadow() {
    if (variant == AuraTileVariant.surface) {
      return [DesignShadows.sm];
    }
    return [];
  }

  Color _getLoadingColor(AuraColorScheme colors) {
    return switch (variant) {
      AuraTileVariant.primary => colors.onPrimary,
      AuraTileVariant.secondary => colors.onSecondary,
      AuraTileVariant.surface => colors.onSurface,
      AuraTileVariant.outlined => colors.primary,
      AuraTileVariant.ghost => colors.primary,
      AuraTileVariant.selected => colors.primary,
      AuraTileVariant.success => colors.onSuccess,
      AuraTileVariant.warning => colors.onWarning,
      AuraTileVariant.error => colors.onError,
      AuraTileVariant.info => colors.onInfo,
    };
  }

  TextStyle _getTextStyle(
    AuraColorScheme colors,
    AuraTypographyTheme typography,
  ) {
    final fontSize = switch (size) {
      AuraTileSize.small => typography.sizes.sm,
      AuraTileSize.medium => typography.sizes.base,
      AuraTileSize.large => typography.sizes.lg,
    };

    final fontWeight = switch (size) {
      AuraTileSize.small => typography.weights.medium,
      AuraTileSize.medium => typography.weights.medium,
      AuraTileSize.large => typography.weights.semibold,
    };

    Color textColor;
    if (!enabled) {
      textColor = colors.onSurfaceVariant;
    } else {
      textColor = switch (variant) {
        AuraTileVariant.primary => colors.onPrimary,
        AuraTileVariant.secondary => colors.onSecondary,
        AuraTileVariant.surface => colors.onSurface,
        AuraTileVariant.outlined => colors.onSurface,
        AuraTileVariant.ghost => colors.primary,
        AuraTileVariant.selected => colors.primary,
        AuraTileVariant.success => colors.onSuccess,
        AuraTileVariant.warning => colors.onWarning,
        AuraTileVariant.error => colors.onError,
        AuraTileVariant.info => colors.onInfo,
      };
    }

    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textColor,
      height: typography.lineHeights.base,
    );
  }

  EdgeInsets _getPadding(AuraSpacingTheme spacing) {
    return switch (size) {
      AuraTileSize.small => EdgeInsets.symmetric(
        horizontal: spacing.md,
        vertical: spacing.sm,
      ),
      AuraTileSize.medium => EdgeInsets.symmetric(
        horizontal: spacing.lg,
        vertical: spacing.md,
      ),
      AuraTileSize.large => EdgeInsets.symmetric(
        horizontal: spacing.xl,
        vertical: spacing.lg,
      ),
    };
  }
}

/// The visual variant of a [AuraTile].
enum AuraTileVariant {
  /// A filled tile with primary color background.
  primary,

  /// A filled tile with secondary color background.
  secondary,

  /// A tile with surface background and subtle shadow.
  surface,

  /// A tile with transparent background and border.
  outlined,

  /// A tile with transparent background and no border.
  ghost,

  /// A tile with subtle primary tint background, no shadow.
  /// Used for selection states in navigation lists.
  selected,

  /// A tile with success color background.
  success,

  /// A tile with warning color background.
  warning,

  /// A tile with error color background.
  error,

  /// A tile with info color background.
  info,
}

/// The size of a [AuraTile].
enum AuraTileSize {
  /// A small tile.
  small,

  /// A medium tile (default).
  medium,

  /// A large tile.
  large,
}
