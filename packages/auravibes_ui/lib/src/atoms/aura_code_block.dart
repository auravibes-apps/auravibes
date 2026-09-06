import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';

/// A selectable, scrollable block of display-only code.
class AuraCodeBlock extends StatelessWidget {
  /// Creates a code block.
  const new({required this.code, super.key, this.language, this.semanticLabel});

  /// Literal code to display.
  final String code;

  /// Optional language label; this does not affect highlighting.
  final String? language;

  /// Optional accessible summary.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.auraColors.surfaceVariant,
        borderRadius: BorderRadius.circular(
          context.auraTheme.fromBorderRadius(.md),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.all(context.auraTheme.spacing.sm),
        child: AuraText(child: SelectableText(code), style: .code),
      ),
    ),
    label: semanticLabel ?? language,
  );
}
