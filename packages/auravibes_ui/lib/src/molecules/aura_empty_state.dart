import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// A reusable empty region with caller-owned copy and optional action.
class AuraEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const new({
    required this.title,
    super.key,
    this.description,
    this.icon,
    this.action,
  });

  /// Primary message.
  final Widget title;

  /// Optional supporting message.
  final Widget? description;

  /// Optional illustration or icon.
  final Widget? icon;

  /// Optional caller-owned action.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.spacing;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: spacing.sm,
        children: [
          ?icon,
          Semantics(
            child: AuraText(
              child: title,
              style: AuraTextStyle.heading6,
              textAlign: TextAlign.center,
            ),
            header: true,
          ),
          if (description case final description?)
            AuraText(child: description, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    );
  }
}
