import 'package:auravibes_ui/src/atoms/aura_icon_button.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/material.dart';

export 'aura_icon_button.dart';

/// A customizable icon component following the Aura design system.
class AuraIcon extends StatelessWidget {
  static const _extraSmallSize = 12.0;
  static const _smallSize = 16.0;
  static const _mediumSize = 20.0;
  static const _largeSize = 24.0;
  static const _extraLargeSize = 32.0;
  static const _hugeSize = 48.0;

  /// Creates an Aura icon.
  const new(
    this.icon, {
    super.key,
    this.size = AuraIconSize.medium,
    this.tint,
    this.semanticLabel,
  });

  /// The icon to display.
  final IconData icon;

  /// The size of the icon.
  final AuraIconSize size;

  /// The tint of the icon.
  final AuraTint? tint;

  /// A semantic label for the icon for accessibility.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final auraColors = context.auraColors;
    final tint = this.tint;
    final iconColor = tint == null
        ? auraColors.onSurface
        : auraColors.colorFor(tint);

    return Semantics(
      child: Icon(icon, size: _getIconSize(), color: iconColor),
      label: semanticLabel,
    );
  }

  double _getIconSize() {
    return switch (size) {
      AuraIconSize.extraSmall => _extraSmallSize,
      AuraIconSize.small => _smallSize,
      AuraIconSize.medium => _mediumSize,
      AuraIconSize.large => _largeSize,
      AuraIconSize.extraLarge => _extraLargeSize,
      AuraIconSize.huge => _hugeSize,
    };
  }
}
