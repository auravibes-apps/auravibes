import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart';
import 'package:flutter/widgets.dart';

/// A circular image with caller-provided initials or icon as fallback.
class AuraAvatar extends StatelessWidget {
  /// Creates an avatar. [child] also appears while its image loads or fails.
  const new({
    required this.child,
    super.key,
    this.imageProvider,
    this.semanticLabel,
    this.size = AuraSpacing.xl2,
    this.tint = AuraTint.primary,
  });

  /// Initials or an icon supplied by the caller.
  final Widget child;

  /// Optional image, supporting local assets as well as network images.
  final ImageProvider<Object>? imageProvider;

  /// Localized identity label, replacing child semantics when supplied.
  final String? semanticLabel;

  /// Diameter from the active spacing scale.
  final AuraSpacing size;

  /// Semantic accent color.
  final AuraTint tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return Semantics(
      child: _AuraAvatarSurface(
        child: child,
        imageProvider: imageProvider,
        diameter: context.auraTheme.fromSpacing(size),
        backgroundColor: colors.colorFor(tint),
        foregroundColor: colors.onTint(tint),
      ),
      excludeSemantics: semanticLabel != null,
      image: true,
      label: semanticLabel,
    );
  }

  static Widget _imageError(BuildContext _, Object _, StackTrace? _) =>
      const SizedBox.shrink();
}

class const _AuraAvatarSurface({
  required final Widget child,
  required final ImageProvider<Object>? imageProvider,
  required final double diameter,
  required final Color backgroundColor,
  required final Color foregroundColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ClipOval(
    child: SizedBox.square(
      dimension: diameter,
      child: _AuraAvatarContent(
        child: child,
        imageProvider: imageProvider,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    ),
  );
}

class const _AuraAvatarContent({
  required final Widget child,
  required final ImageProvider<Object>? imageProvider,
  required final Color backgroundColor,
  required final Color foregroundColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: backgroundColor,
    child: DefaultTextStyle.merge(
      style: .new(color: foregroundColor),
      child: IconTheme(
        data: .new(color: foregroundColor),
        child: _AuraAvatarStack(child: child, imageProvider: imageProvider),
      ),
    ),
  );
}

class const _AuraAvatarStack({
  required final Widget child,
  required final ImageProvider<Object>? imageProvider,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    fit: .expand,
    children: [
      Center(child: child),
      if (imageProvider case final imageProvider?)
        Image(
          image: imageProvider,
          errorBuilder: AuraAvatar._imageError,
          excludeFromSemantics: true,
          fit: .cover,
        ),
    ],
  );
}
