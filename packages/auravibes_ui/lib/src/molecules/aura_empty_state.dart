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
  Widget build(BuildContext context) => _AuraEmptyStateContent(state: this);
}

class const _AuraEmptyStateContent({required final AuraEmptyState state})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final spacing = context.auraTheme.spacing;
    final state = this.state;

    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: _AuraEmptyStateChildren(state: state, spacing: spacing),
    );
  }
}

class const _AuraEmptyStateChildren({
  required final AuraEmptyState state,
  required final AuraSpacingScale spacing,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    spacing: spacing.sm,
    children: [
      ?state.icon,
      Semantics(
        child: AuraText(
          child: state.title,
          style: .heading6,
          textAlign: .center,
        ),
        header: true,
      ),
      if (state.description case final description?)
        AuraText(child: description, textAlign: .center),
      ?state.action,
    ],
  );
}
