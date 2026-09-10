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
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'AuraBadge(variant: $variant, size: $size)';

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    return _AuraBadgeSemantics(
      label: semanticLabel,
      child: _AuraBadgeSurface(
        child: child,
        size: size,
        foreground: _badgeForegroundColor(variant, auraColors),
        background: _badgeBackgroundColor(variant, auraColors),
        border: _badgeBorder(variant, auraColors),
      ),
    );
  }
}

class const _AuraBadgeSemantics({
  required final String? label,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      label == null ? child : Semantics(child: child, label: label);
}

class const _AuraBadgeSurface({
  required final Widget child,
  required final AuraBadgeSize size,
  required final Color foreground,
  required final Color background,
  required final Border? border,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: _badgePadding(size, context.auraTheme.spacing),
    decoration: BoxDecoration(
      color: background,
      border: border,
      borderRadius: BorderRadius.circular(
        context.auraTheme.fromBorderRadius(_badgeBorderRadius(size)),
      ),
    ),
    child: DefaultTextStyle(
      style: _badgeTextStyle(foreground, context.auraTheme),
      child: _AuraBadgeIconTheme(foreground: foreground, child: child),
    ),
  );
}

class const _AuraBadgeIconTheme({
  required final Color foreground,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconTheme(
    data: .new(color: foreground),
    child: child,
  );
}

TextStyle _badgeTextStyle(Color foreground, AuraTheme theme) =>
    TextStyle(color: foreground, fontWeight: theme.typography.fontWeightMedium);

EdgeInsets _badgePadding(AuraBadgeSize size, AuraSpacingScale spacing) =>
    switch (size) {
      .small => EdgeInsets.symmetric(vertical: 2, horizontal: spacing.xs),
      .medium || .large => EdgeInsets.symmetric(
        vertical: spacing.xs,
        horizontal: spacing.sm,
      ),
    };

AuraBorderRadius _badgeBorderRadius(AuraBadgeSize size) => switch (size) {
  .small || .medium => .sm,
  .large => .md,
};

Color _badgeBackgroundColor(AuraBadgeVariant variant, AuraColorScheme colors) =>
    switch (variant) {
      .primary => colors.primary,
      .secondary => colors.secondary,
      .success => colors.success,
      .warning => colors.warning,
      .error => colors.error,
      .info => colors.info,
      .neutral => colors.onSurfaceVariant,
      .outlined => DesignColors.transparent,
      .soft => colors.primary.withValues(alpha: 0.1),
    };

Color _badgeForegroundColor(AuraBadgeVariant variant, AuraColorScheme colors) =>
    switch (variant) {
      .primary => colors.onTint(.primary),
      .secondary => colors.onTint(.secondary),
      .success => colors.onTint(.success),
      .warning => colors.onTint(.warning),
      .error => colors.onTint(.error),
      .info => colors.onTint(.info),
      .neutral => colors.foregroundOnSurface,
      .outlined || .soft => colors.mutedForeground,
    };

Border? _badgeBorder(AuraBadgeVariant variant, AuraColorScheme colors) =>
    variant == .outlined ? Border.all(color: colors.outline) : null;

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
