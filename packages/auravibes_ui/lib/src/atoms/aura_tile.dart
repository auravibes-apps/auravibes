// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/atoms/aura_sized_box.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable tile component following the Aura design system.
///
/// Tiles are horizontally expanded interactive elements similar to buttons
/// but designed for broader content areas and different interaction patterns.
/// They support multiple variants, sizes, and states while maintaining
/// consistency with the design tokens.
class AuraTile extends StatelessWidget {
  // Null onTap creates a non-interactive tile for status rows.
  // ignore: unnecessary-nullable
  /// Creates a Aura tile.
  const AuraTile({
    required this.child,
    super.key,
    this.onTap,
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
    final loadingColorVariant = _getLoadingColorVariant();
    final leading = this.leading;
    final trailing = this.trailing;
    final tileChild = child;
    final isChildEmpty =
        tileChild is SizedBox && tileChild.width == 0 && tileChild.height == 0;
    final Widget content;
    if (isLoading) {
      content = Center(
        child: AuraLoadingCircle.compact(
          colorVariant: loadingColorVariant,
        ),
      );
    } else if (isChildEmpty && leading != null && trailing == null) {
      content = Center(child: leading);
    } else {
      content = Row(
        children: [
          if (leading != null) ...[
            leading,
            const AuraSizedBox(width: .sm),
          ],
          Flexible(
            fit: .tight,
            child: DefaultTextStyle(
              style: _getTextStyle(
                auraColors,
                typography: context.auraTheme.typography,
              ),
              child: child,
            ),
          ),
          if (trailing != null) ...[
            const AuraSizedBox(width: .sm),
            trailing,
          ],
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          child: AnimatedContainer(
            padding: _getPadding(spacing: context.auraTheme.spacing),
            decoration: BoxDecoration(
              color: _getBackgroundColor(auraColors),
              borderRadius: BorderRadius.all(
                Radius.circular(
                  context.auraTheme.fromBorderRadius(.lg),
                ),
              ),
              boxShadow: _getBoxShadow(),
            ),
            child: content,
            duration: auraTheme.animation.normal,
          ),
          onTap: enabled && !isLoading ? onTap : null,
          borderRadius: BorderRadius.all(
            Radius.circular(
              context.auraTheme.fromBorderRadius(.lg),
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    if (!enabled) return colors.outlineVariant;

    return switch (variant) {
      AuraTileVariant.primary => colors.primary,
      AuraTileVariant.surface => colors.surface,
      AuraTileVariant.ghost => Colors.transparent,
      AuraTileVariant.selected => colors.primary.withValues(alpha: 0.1),
      AuraTileVariant.error => colors.error,
    };
  }

  List<BoxShadow> _getBoxShadow() {
    if (variant == AuraTileVariant.surface) {
      return [DesignShadows.sm];
    }

    return [];
  }

  AuraColorVariant _getLoadingColorVariant() {
    return switch (variant) {
      AuraTileVariant.primary => AuraColorVariant.onPrimary,
      AuraTileVariant.surface => AuraColorVariant.onSurface,
      AuraTileVariant.ghost => AuraColorVariant.primary,
      AuraTileVariant.selected => AuraColorVariant.primary,
      AuraTileVariant.error => AuraColorVariant.onError,
    };
  }

  TextStyle _getTextStyle(
    AuraColorScheme colors, {
    required AuraTypographyScale typography,
  }) {
    final fontSize = switch (size) {
      AuraTileSize.small => typography.fontSizeSm,
      AuraTileSize.medium => typography.fontSizeBase,
      AuraTileSize.large => typography.fontSizeLg,
    };

    final fontWeight = switch (size) {
      AuraTileSize.small => typography.fontWeightMedium,
      AuraTileSize.medium => typography.fontWeightMedium,
      AuraTileSize.large => typography.fontWeightSemibold,
    };

    final textColor = !enabled
        ? colors.onSurfaceVariant
        : switch (variant) {
            AuraTileVariant.primary => colors.onPrimary,
            AuraTileVariant.surface => colors.onSurface,
            AuraTileVariant.ghost => colors.primary,
            AuraTileVariant.selected => colors.primary,
            AuraTileVariant.error => colors.onError,
          };

    return TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: typography.lineHeightBase,
    );
  }

  EdgeInsets _getPadding({required AuraSpacingScale spacing}) {
    return switch (size) {
      AuraTileSize.small => EdgeInsets.symmetric(
        vertical: spacing.sm,
        horizontal: spacing.md,
      ),
      AuraTileSize.medium => EdgeInsets.symmetric(
        vertical: spacing.md,
        horizontal: spacing.lg,
      ),
      AuraTileSize.large => EdgeInsets.symmetric(
        vertical: spacing.lg,
        horizontal: spacing.xl,
      ),
    };
  }
}

/// The visual variant of a [AuraTile].
enum AuraTileVariant {
  /// A filled tile with primary color background.
  primary,

  /// A tile with surface background and subtle shadow.
  surface,

  /// A tile with transparent background and no border.
  ghost,

  /// A tile with subtle primary tint background, no shadow.
  /// Used for selection states in navigation lists.
  selected,

  /// A tile with error color background.
  error,
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
