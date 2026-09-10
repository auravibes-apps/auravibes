import 'package:auravibes_ui/src/atoms/aura_icon.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// An inline semantic alert with optional icon and description.
class AuraCallout extends StatelessWidget {
  /// Creates a callout.
  const new({
    required this.title,
    super.key,
    this.description,
    this.icon,
    this.tint = AuraTint.info,
  });

  /// Caller-localized heading.
  final String title;

  /// Caller-localized supporting text.
  final String? description;

  /// Optional status icon.
  final IconData? icon;

  /// Semantic visual tone.
  final AuraTint tint;

  @override
  Widget build(BuildContext context) => _AuraCalloutSemantics(callout: this);
}

class const _AuraCalloutSemantics({required final AuraCallout callout})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: _AuraCalloutSurface.fromContext(callout, context),
    liveRegion: true,
  );
}

class _AuraCalloutSurface extends StatelessWidget {
  _AuraCalloutSurface({
    required AuraCallout callout,
    required AuraColorScheme colors,
    required AuraTheme theme,
  }) : _child = DecoratedBox(
         decoration: BoxDecoration(
           color: colors.colorFor(callout.tint).withValues(alpha: 0.12),
           borderRadius: BorderRadius.circular(theme.fromBorderRadius(.md)),
         ),
         child: _AuraCalloutContent(callout: callout, spacing: theme.spacing),
       );

  _AuraCalloutSurface.fromContext(AuraCallout callout, BuildContext context)
    : this(
        callout: callout,
        colors: context.auraColors,
        theme: context.auraTheme,
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _AuraCalloutContent extends StatelessWidget {
  _AuraCalloutContent({
    required AuraCallout callout,
    required AuraSpacingScale spacing,
  }) : _child = Padding(
         padding: EdgeInsets.all(spacing.md),
         child: Row(
           crossAxisAlignment: .start,
           spacing: spacing.sm,
           children: [
             if (callout.icon case final value?)
               AuraIcon(value, tint: callout.tint),
             Expanded(child: _AuraCalloutText(callout: callout)),
           ],
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _AuraCalloutText({required final AuraCallout callout})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    children: [
      AuraText(
        child: Text(callout.title),
        style: .bodyLarge,
        tint: callout.tint,
      ),
      if (callout.description case final value?)
        AuraText(child: Text(value), style: .bodySmall),
    ],
  );
}
