// Required: Existing test and UI helpers keep compact return flow.
// Required: UI components keep related private widgets together.
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/material.dart';

/// A customizable badge component following the Aura design system.
///
/// This badge widget provides consistent styling for status indicators,
/// labels, and notification counts across the application.
class AuraBadge extends StatelessWidget {
  /// Creates a Aura badge.
  const AuraBadge({
    required this.child,
    super.key,
    this.variant = AuraBadgeVariant.primary,
    this.size = AuraBadgeSize.medium,
    this.semanticLabel,
  });

  /// Creates a Aura badge with text content.
  AuraBadge.text({
    required Widget child,
    Key? key,
    AuraBadgeVariant variant = AuraBadgeVariant.primary,
    AuraBadgeSize size = AuraBadgeSize.medium,
    String? semanticLabel,
  }) : this(
         key: key,
         variant: variant,
         size: size,
         semanticLabel: semanticLabel,
         child: AuraText(
           child: child,
           style: size == AuraBadgeSize.small
               ? AuraTextStyle.caption
               : AuraTextStyle.bodySmall,
         ),
       );

  /// Creates a Aura badge with a count number.
  AuraBadge.count({
    required int count,
    Key? key,
    AuraBadgeVariant variant = AuraBadgeVariant.primary,
    AuraBadgeSize size = AuraBadgeSize.medium,
    String? semanticLabel,
    int maxCount = 99,
  }) : this(
         key: key,
         variant: variant,
         size: size,
         semanticLabel: semanticLabel ?? '$count notifications',
         child: AuraText(
           child: Text(count > maxCount ? '$maxCount+' : count.toString()),
           style: size == AuraBadgeSize.small
               ? AuraTextStyle.caption
               : AuraTextStyle.bodySmall,
         ),
       );

  /// Creates a Aura badge with a dot indicator.
  const AuraBadge.dot({
    Key? key,
    AuraBadgeVariant variant = AuraBadgeVariant.primary,
    String? semanticLabel,
  }) : this(
         child: const SizedBox(width: 6, height: 6),
         key: key,
         variant: variant,
         size: AuraBadgeSize.small,
         semanticLabel: semanticLabel ?? 'notification indicator',
       );

  /// The widget to display inside the badge.
  final Widget child;

  /// The visual variant of the badge.
  final AuraBadgeVariant variant;

  /// The size of the badge.
  final AuraBadgeSize size;

  /// A semantic label for the badge for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;

    Widget badge = Container(
      padding: _getPadding(spacing: context.auraTheme.spacing),
      decoration: BoxDecoration(
        color: _getBackgroundColor(auraColors),
        border: variant == AuraBadgeVariant.outlined
            ? Border.all(
                color: _getBorderColor(auraColors),
              )
            : null,
        borderRadius: BorderRadius.circular(
          context.auraTheme.fromBorderRadius(_getBorderRadius()),
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: _getForegroundColor(auraColors),
          fontWeight: context.auraTheme.typography.fontWeightMedium,
        ),
        child: child,
      ),
    );

    if (semanticLabel != null) {
      badge = Semantics(
        child: badge,
        label: semanticLabel,
      );
    }

    return badge;
  }

  EdgeInsets _getPadding({required AuraSpacingScale spacing}) {
    return switch (size) {
      AuraBadgeSize.small => EdgeInsets.symmetric(
        vertical: 2,
        horizontal: spacing.xs,
      ),
      AuraBadgeSize.medium => EdgeInsets.symmetric(
        vertical: spacing.xs,
        horizontal: spacing.sm,
      ),
      AuraBadgeSize.large => EdgeInsets.symmetric(
        vertical: spacing.xs,
        horizontal: spacing.sm,
      ),
    };
  }

  AuraBorderRadius _getBorderRadius() {
    return switch (size) {
      AuraBadgeSize.small => AuraBorderRadius.sm,
      AuraBadgeSize.medium => AuraBorderRadius.sm,
      AuraBadgeSize.large => AuraBorderRadius.md,
    };
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    return switch (variant) {
      AuraBadgeVariant.primary => colors.primary,
      AuraBadgeVariant.secondary => colors.secondary,
      AuraBadgeVariant.success => colors.success,
      AuraBadgeVariant.warning => colors.warning,
      AuraBadgeVariant.error => colors.error,
      AuraBadgeVariant.info => colors.info,
      AuraBadgeVariant.neutral => colors.onSurfaceVariant,
      AuraBadgeVariant.outlined => Colors.transparent,
      AuraBadgeVariant.soft => _getSoftBackgroundColor(colors),
    };
  }

  Color _getForegroundColor(AuraColorScheme colors) {
    return switch (variant) {
      AuraBadgeVariant.primary => colors.onPrimary,
      AuraBadgeVariant.secondary => colors.onSecondary,
      AuraBadgeVariant.success => colors.onSuccess,
      AuraBadgeVariant.warning => colors.onWarning,
      AuraBadgeVariant.error => colors.onError,
      AuraBadgeVariant.info => colors.onInfo,
      AuraBadgeVariant.neutral => colors.onSurface,
      AuraBadgeVariant.outlined => _getOutlinedForegroundColor(colors),
      AuraBadgeVariant.soft => _getSoftForegroundColor(colors),
    };
  }

  Color _getBorderColor(AuraColorScheme colors) {
    return switch (variant) {
      AuraBadgeVariant.primary => colors.primary,
      AuraBadgeVariant.secondary => colors.secondary,
      AuraBadgeVariant.success => colors.success,
      AuraBadgeVariant.warning => colors.warning,
      AuraBadgeVariant.error => colors.error,
      AuraBadgeVariant.info => colors.info,
      AuraBadgeVariant.neutral => colors.onSurfaceVariant,
      AuraBadgeVariant.outlined => colors.outline,
      AuraBadgeVariant.soft => Colors.transparent,
    };
  }

  // Each helper is reached only from its own variant branch (soft/outlined),
  // so it ignores `variant` and returns the single value that arm produced.
  Color _getSoftBackgroundColor(AuraColorScheme colors) {
    return colors.primary.withValues(alpha: 0.1);
  }

  Color _getSoftForegroundColor(AuraColorScheme colors) {
    return colors.onSurfaceVariant;
  }

  Color _getOutlinedForegroundColor(AuraColorScheme colors) {
    return colors.onSurfaceVariant;
  }
}

/// The visual variant of a [AuraBadge].
enum AuraBadgeVariant {
  /// Primary color badge.
  primary,

  /// Secondary color badge.
  secondary,

  /// Success color badge (green).
  success,

  /// Warning color badge (yellow).
  warning,

  /// Error color badge (red).
  error,

  /// Info color badge (blue).
  info,

  /// Neutral color badge (gray).
  neutral,

  /// Badge with transparent background and border.
  outlined,

  /// Badge with soft background color.
  soft,
}

/// The size of a [AuraBadge].
enum AuraBadgeSize {
  /// Small badge.
  small,

  /// Medium badge (default).
  medium,

  /// Large badge.
  large,
}
