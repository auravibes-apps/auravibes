import 'package:auravibes_ui/src/atoms/aura_avatar.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/widgets.dart';

/// A compact, wrapping group of avatars with an overflow count.
class AuraAvatarGroup extends StatelessWidget {
  /// Creates a group; [maxVisible] counts avatars before the overflow badge.
  const new({
    required this.children,
    super.key,
    this.maxVisible = 5,
    this.overflowSemanticLabel,
  }) : assert(maxVisible >= 0, 'maxVisible must be non-negative');

  /// Avatars in reading order.
  final List<Widget> children;

  /// Maximum number of visible avatars, excluding the overflow badge.
  final int maxVisible;

  /// Localized description of hidden members, such as “3 more people”.
  final String? overflowSemanticLabel;

  @override
  Widget build(BuildContext context) => _AuraAvatarGroupContent(
    children: children,
    maxVisible: maxVisible,
    overflowSemanticLabel: overflowSemanticLabel,
    spacing: context.auraTheme.spacing.xs,
  );
}

class _AuraAvatarGroupContent extends StatelessWidget {
  new({
    required List<Widget> children,
    required int maxVisible,
    required String? overflowSemanticLabel,
    required double spacing,
  }) : _child = Wrap(
         spacing: spacing,
         runSpacing: spacing,
         children: [
           ...children.take(maxVisible),
           if (children.length > maxVisible)
             AuraAvatar(
               child: Text('+${children.length - maxVisible}'),
               semanticLabel: overflowSemanticLabel,
             ),
         ],
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}
