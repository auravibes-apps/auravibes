// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
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
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: _getBackgroundColor(auraColors),
        border: variant == AuraBadgeVariant.outlined
            ? Border.all(
                color: _getBorderColor(auraColors),
              )
            : null,
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          color: _getForegroundColor(auraColors),
          fontWeight: DesignTypography.fontWeightMedium,
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

  EdgeInsets _getPadding() {
    return switch (size) {
      AuraBadgeSize.small => const EdgeInsets.symmetric(
        vertical: 2,
        horizontal: DesignSpacing.xs,
      ),
      AuraBadgeSize.medium => const EdgeInsets.symmetric(
        vertical: DesignSpacing.xs,
        horizontal: DesignSpacing.sm,
      ),
      AuraBadgeSize.large => const EdgeInsets.symmetric(
        vertical: DesignSpacing.xs,
        horizontal: DesignSpacing.sm,
      ),
    };
  }

  double _getBorderRadius() {
    return switch (size) {
      AuraBadgeSize.small => DesignBorderRadius.sm,
      AuraBadgeSize.medium => DesignBorderRadius.sm,
      AuraBadgeSize.large => DesignBorderRadius.md,
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

  Color _getSoftBackgroundColor(AuraColorScheme colors) {
    return switch (variant) {
      AuraBadgeVariant.primary => colors.primary.withValues(alpha: 0.1),
      AuraBadgeVariant.secondary => colors.secondary.withValues(alpha: 0.1),
      AuraBadgeVariant.success => colors.success.withValues(alpha: 0.1),
      AuraBadgeVariant.warning => colors.warning.withValues(alpha: 0.1),
      AuraBadgeVariant.error => colors.error.withValues(alpha: 0.1),
      AuraBadgeVariant.info => colors.info.withValues(alpha: 0.1),
      AuraBadgeVariant.neutral => colors.onSurfaceVariant.withValues(
        alpha: 0.1,
      ),
      AuraBadgeVariant.outlined => colors.surfaceVariant,
      AuraBadgeVariant.soft => colors.primary.withValues(alpha: 0.1),
    };
  }

  Color _getSoftForegroundColor(AuraColorScheme colors) {
    return switch (variant) {
      AuraBadgeVariant.primary => colors.primaryVariant,
      AuraBadgeVariant.secondary => colors.secondaryVariant,
      AuraBadgeVariant.success => colors.success,
      AuraBadgeVariant.warning => colors.warning,
      AuraBadgeVariant.error => colors.error,
      AuraBadgeVariant.info => colors.info,
      AuraBadgeVariant.neutral => colors.onSurfaceVariant,
      _ => colors.onSurfaceVariant,
    };
  }

  Color _getOutlinedForegroundColor(AuraColorScheme colors) {
    return switch (variant) {
      AuraBadgeVariant.primary => colors.primary,
      AuraBadgeVariant.secondary => colors.secondary,
      AuraBadgeVariant.success => colors.success,
      AuraBadgeVariant.warning => colors.warning,
      AuraBadgeVariant.error => colors.error,
      AuraBadgeVariant.info => colors.info,
      AuraBadgeVariant.neutral => colors.onSurfaceVariant,
      _ => colors.onSurfaceVariant,
    };
  }
}

/// A specialized badge component that can be positioned relative to another
/// widget.
///
/// This is commonly used for notification badges on icons or avatars.
class AuraPositionedBadge extends StatelessWidget {
  /// Creates a positioned Aura badge.
  const AuraPositionedBadge({
    required this.child,
    required this.badge,
    super.key,
    this.position = AuraBadgePosition.topRight,
    this.offset,
  });

  /// The widget to position the badge relative to.
  final Widget child;

  /// The badge to display.
  final AuraBadge badge;

  /// The position of the badge relative to the child.
  final AuraBadgePosition position;

  /// Optional offset to fine-tune the badge position.
  final Offset? offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: _getLeft(),
          top: _getTop(),
          right: _getRight(),
          bottom: _getBottom(),
          child: badge,
        ),
      ],
    );
  }

  double? _getTop() {
    final baseOffset = offset?.dy ?? 0;
    return switch (position) {
      AuraBadgePosition.topLeft ||
      AuraBadgePosition.topRight => -8.0 + baseOffset,
      AuraBadgePosition.bottomLeft || AuraBadgePosition.bottomRight => null,
    };
  }

  double? _getRight() {
    final baseOffset = offset?.dx ?? 0;
    return switch (position) {
      AuraBadgePosition.topRight ||
      AuraBadgePosition.bottomRight => -8.0 + baseOffset,
      AuraBadgePosition.topLeft || AuraBadgePosition.bottomLeft => null,
    };
  }

  double? _getBottom() {
    final baseOffset = offset?.dy ?? 0;
    return switch (position) {
      AuraBadgePosition.bottomLeft ||
      AuraBadgePosition.bottomRight => -8.0 + baseOffset,
      AuraBadgePosition.topLeft || AuraBadgePosition.topRight => null,
    };
  }

  double? _getLeft() {
    final baseOffset = offset?.dx ?? 0;
    return switch (position) {
      AuraBadgePosition.topLeft ||
      AuraBadgePosition.bottomLeft => -8.0 + baseOffset,
      AuraBadgePosition.topRight || AuraBadgePosition.bottomRight => null,
    };
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

/// The position of a [AuraPositionedBadge].
enum AuraBadgePosition {
  /// Top-left corner.
  topLeft,

  /// Top-right corner.
  topRight,

  /// Bottom-left corner.
  bottomLeft,

  /// Bottom-right corner.
  bottomRight,
}
