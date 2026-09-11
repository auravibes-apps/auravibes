import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// A user-initiated text link. URL handling belongs to the application.
class AuraLink extends StatelessWidget {
  /// Creates a text link.
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.semanticLabel,
  });

  /// Visible, caller-localized link text.
  final String label;

  /// Called only after a user activates the link.
  final VoidCallback? onPressed;

  /// Optional accessible label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled =
        AuraInteractionScope.of(context).allowsNavigation && onPressed != null;

    return _AuraLinkSemantics(
      label: semanticLabel,
      enabled: enabled,
      child: _AuraLinkInteraction(
        label: label,
        enabled: enabled,
        onPressed: onPressed,
      ),
    );
  }
}

class const _AuraLinkSemantics({
  required final String? label,
  required final bool enabled,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Semantics(child: child, enabled: enabled, link: true, label: label);
}

class const _AuraLinkInteraction({
  required final String label,
  required final bool enabled,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _AuraLinkMouseRegion(
    label: label,
    enabled: enabled,
    onPressed: onPressed,
  );
}

class const _AuraLinkMouseRegion({
  required final String label,
  required final bool enabled,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: _AuraLinkGesture(
      label: label,
      enabled: enabled,
      onPressed: onPressed,
    ),
  );
}

class const _AuraLinkGesture({
  required final String label,
  required final bool enabled,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    child: _AuraLinkLabel(label: label),
    onTap: enabled ? onPressed : null,
  );
}

class const _AuraLinkLabel({required final String label})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraText(
    child: Text(
      label,
      style: .new(
        color: context.auraColors.primary,
        decoration: TextDecoration.underline,
      ),
    ),
  );
}
