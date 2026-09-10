// Required: Existing test and UI helpers keep compact return flow.
// Required: UI components keep related private widgets together.
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef _BadgeDecorationRequest = ({
  double radius,
  Color background,
  Border? border,
});

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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AuraBadgeVariant>('variant', variant));
  }

  @override
  Widget build(BuildContext context) => _AuraBadgeBuilt(
    badge: this,
    colors: context.auraColors,
    theme: context.auraTheme,
  ).child;
}

class _AuraBadgeBuilt {
  _AuraBadgeBuilt({
    required AuraBadge badge,
    required AuraColorScheme colors,
    required AuraTheme theme,
  }) : child = _AuraBadgeSemantics(
         label: badge.semanticLabel,
         child: _AuraBadgeSurface(
           child: badge.child,
           size: badge.size,
           foreground: _badgeForegroundColor(badge.variant, colors),
           background: _badgeBackgroundColor(badge.variant, colors),
           border: _badgeBorder(badge.variant, colors),
           theme: theme,
         ),
       );

  final Widget child;
}

class const _AuraBadgeSemantics({
  required final String? label,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      label == null ? child : Semantics(child: child, label: label);
}

class _AuraBadgeSurface extends StatelessWidget {
  _AuraBadgeSurface({
    required Widget child,
    required AuraBadgeSize size,
    required Color foreground,
    required Color background,
    required Border? border,
    required AuraTheme theme,
  }) : _child = Container(
         padding: _badgePadding(size, theme.spacing),
         decoration: _badgeDecoration((
           radius: theme.fromBorderRadius(_badgeBorderRadius(size)),
           background: background,
           border: border,
         )),
         child: _AuraBadgeContent(
           child: child,
           foreground: foreground,
           theme: theme,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

BoxDecoration _badgeDecoration(_BadgeDecorationRequest request) =>
    BoxDecoration(
      color: request.background,
      border: request.border,
      borderRadius: BorderRadius.circular(request.radius),
    );

class const _AuraBadgeContent({
  required final Widget child,
  required final Color foreground,
  required final AuraTheme theme,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DefaultTextStyle(
    style: _badgeTextStyle(foreground, theme),
    child: _AuraBadgeIconTheme(foreground: foreground, child: child),
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

Color _badgeBackgroundColor(AuraBadgeVariant variant, AuraColorScheme colors) {
  if (variant == .outlined) return DesignColors.transparent;
  if (variant == .soft) return colors.primary.withValues(alpha: 0.1);
  if (variant == .neutral) return colors.onSurfaceVariant;

  return colors.colorFor(_badgeTint(variant));
}

Color _badgeForegroundColor(AuraBadgeVariant variant, AuraColorScheme colors) =>
    switch (variant) {
      .primary ||
      .secondary ||
      .success ||
      .warning ||
      .error ||
      .info => colors.onTint(_badgeTint(variant)),
      .neutral => colors.foregroundOnSurface,
      .outlined || .soft => colors.mutedForeground,
    };

AuraTint _badgeTint(AuraBadgeVariant variant) => switch (variant) {
  .primary => .primary,
  .secondary => .secondary,
  .success => .success,
  .warning => .warning,
  .error => .error,
  .info => .info,
  .neutral || .outlined || .soft => .primary,
};

Border? _badgeBorder(AuraBadgeVariant variant, AuraColorScheme colors) =>
    variant == .outlined
    ? Border.fromBorderSide(.new(color: colors.outline))
    : null;

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
