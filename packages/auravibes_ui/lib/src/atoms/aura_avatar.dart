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
    final diameter = context.auraTheme.fromSpacing(size);
    final foreground = colors.onTint(tint);
    final image = imageProvider;

    return Semantics(
      child: ClipOval(
        child: SizedBox.square(
          child: ColoredBox(
            color: colors.colorFor(tint),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: IconTheme(
                data: IconThemeData(color: foreground),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(child: child),
                    if (image != null)
                      Image(
                        image: image,
                        errorBuilder: _imageError,
                        excludeFromSemantics: true,
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
              ),
            ),
          ),
          dimension: diameter,
        ),
      ),
      excludeSemantics: semanticLabel != null,
      image: true,
      label: semanticLabel,
    );
  }

  static Widget _imageError(BuildContext _, Object _, StackTrace? _) =>
      const SizedBox.shrink();
}
