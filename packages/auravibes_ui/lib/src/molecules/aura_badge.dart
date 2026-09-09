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
  const new({
    required this.child,
    super.key,
    this.variant = AuraBadgeVariant.primary,
    this.size = AuraBadgeSize.medium,
    this.semanticLabel,
  });

  /// Creates a Aura badge with text content.
  new text({
    required Widget child,
    Key? key,
    AuraBadgeVariant variant = AuraBadgeVariant.primary,
    AuraBadgeSize size = AuraBadgeSize.medium,
    String semanticLabel = '',
  }) : this(
         key: key,
         variant: variant,
         size: size,
         semanticLabel: semanticLabel.isEmpty ? null : semanticLabel,
         child: _AuraBadgeText(
           child: child,
           style: size == AuraBadgeSize.small
               ? AuraTextStyle.caption
               : AuraTextStyle.bodySmall,
         ),
       );

  /// Creates a Aura badge with a count number.
  new count({
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
         child: _AuraBadgeText(
           child: Text(count > maxCount ? '$maxCount+' : count.toString()),
           style: size == AuraBadgeSize.small
               ? AuraTextStyle.caption
               : AuraTextStyle.bodySmall,
         ),
       );

  /// Creates a Aura badge with a dot indicator.
  const new dot({
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
    final foreground = _getForegroundColor(auraColors);

    Widget badge = Container(
      padding: _getPadding(spacing: context.auraTheme.spacing),
      decoration: BoxDecoration(
        color: _getBackgroundColor(auraColors),
        border: variant == AuraBadgeVariant.outlined
            ? Border.all(color: _getBorderColor(auraColors))
            : null,
        borderRadius: BorderRadius.circular(
          context.auraTheme.fromBorderRadius(_getBorderRadius()),
        ),
      ),
      child: DefaultTextStyle(
        style: .new(
          color: foreground,
          fontWeight: context.auraTheme.typography.fontWeightMedium,
        ),
        child: IconTheme(
          data: .new(color: foreground),
          child: child,
        ),
      ),
    );

    if (semanticLabel != null) {
      badge = Semantics(child: badge, label: semanticLabel);
    }

    return badge;
  }

  EdgeInsets _getPadding({required AuraSpacingScale spacing}) {
    return switch (size) {
      .small => EdgeInsets.symmetric(vertical: 2, horizontal: spacing.xs),
      .medium => EdgeInsets.symmetric(
        vertical: spacing.xs,
        horizontal: spacing.sm,
      ),
      .large => EdgeInsets.symmetric(
        vertical: spacing.xs,
        horizontal: spacing.sm,
      ),
    };
  }

  AuraBorderRadius _getBorderRadius() {
    return switch (size) {
      .small => .sm,
      .medium => .sm,
      .large => .md,
    };
  }

  Color _getBackgroundColor(AuraColorScheme colors) {
    return switch (variant) {
      .primary => colors.primary,
      .secondary => colors.secondary,
      .success => colors.success,
      .warning => colors.warning,
      .error => colors.error,
      .info => colors.info,
      .neutral => colors.onSurfaceVariant,
      .outlined => DesignColors.transparent,
      .soft => _getSoftBackgroundColor(colors),
    };
  }

  Color _getForegroundColor(AuraColorScheme colors) {
    return switch (variant) {
      .primary => colors.onTint(.primary),
      .secondary => colors.onTint(.secondary),
      .success => colors.onTint(.success),
      .warning => colors.onTint(.warning),
      .error => colors.onTint(.error),
      .info => colors.onTint(.info),
      .neutral => colors.foregroundOnSurface,
      .outlined => _getOutlinedForegroundColor(colors),
      .soft => _getSoftForegroundColor(colors),
    };
  }

  Color _getBorderColor(AuraColorScheme colors) {
    return switch (variant) {
      .primary => colors.primary,
      .secondary => colors.secondary,
      .success => colors.success,
      .warning => colors.warning,
      .error => colors.error,
      .info => colors.info,
      .neutral => colors.onSurfaceVariant,
      .outlined => colors.outline,
      .soft => DesignColors.transparent,
    };
  }

  // Each helper is reached only from its own variant branch (soft/outlined),
  // so it ignores `variant` and returns the single value that arm produced.
  Color _getSoftBackgroundColor(AuraColorScheme colors) {
    return colors.primary.withValues(alpha: 0.1);
  }

  Color _getSoftForegroundColor(AuraColorScheme colors) {
    return colors.mutedForeground;
  }

  Color _getOutlinedForegroundColor(AuraColorScheme colors) {
    return colors.mutedForeground;
  }
}

class const _AuraBadgeText({
  required final Widget child,
  required final AuraTextStyle style,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final foreground = DefaultTextStyle.of(context).style.color;

    return AuraText(
      child: IconTheme(
        data: .new(color: foreground),
        child: DefaultTextStyle.merge(
          style: .new(color: foreground),
          child: child,
        ),
      ),
      style: style,
    );
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
