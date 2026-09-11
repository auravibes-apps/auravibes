import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

part 'aura_fieldset.dart';

/// A titled content section.
class AuraSection extends StatelessWidget {
  /// Creates a section.
  const new({
    required this.title,
    required this.child,
    super.key,
    this.description,
  });

  /// Heading text.
  final String title;

  /// Section content.
  final Widget child;

  /// Optional supporting text.
  final String? description;

  @override
  Widget build(BuildContext context) => _AuraSectionContent(
    title: title,
    child: child,
    spacing: context.auraTheme.spacing,
    description: description,
  );
}

class _AuraSectionContent extends StatelessWidget {
  new({
    required String title,
    required Widget child,
    required AuraSpacingScale spacing,
    String? description,
  }) : _child = Semantics(
         child: Column(
           crossAxisAlignment: .start,
           spacing: spacing.sm,
           children: [
             AuraText(child: Text(title), style: .heading5),
             if (description case final value?)
               AuraText(child: Text(value), style: .bodySmall),
             child,
           ],
         ),
         container: true,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}
