import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

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
  Widget build(BuildContext context) => Semantics(
    child: Column(
      crossAxisAlignment: .start,
      spacing: context.auraTheme.spacing.sm,
      children: [
        AuraText(child: Text(title), style: .heading5),
        if (description case final value?)
          AuraText(child: Text(value), style: .bodySmall),
        child,
      ],
    ),
    container: true,
  );
}

/// A section whose title acts as a form legend.
class AuraFieldset extends AuraSection {
  /// Creates a fieldset.
  const new({
    required super.title,
    required super.child,
    super.key,
    super.description,
  });
}
