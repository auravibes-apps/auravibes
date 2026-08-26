import 'package:auravibes_ui/src/atoms/aura_edge_insets_geometry.dart'
    show AuraEdgeInsetsGeometry, AuraPadding;
import 'package:auravibes_ui/src/atoms/aura_icon.dart' show AuraIcon;
import 'package:auravibes_ui/src/atoms/aura_spinner.dart' show AuraSpinner;
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:auravibes_ui/src/tokens/design_tokens.dart' show AuraTint;
import 'package:flutter/widgets.dart';

/// Displays an image loaded from [url] with Aura loading and error states.
class AuraImage extends StatelessWidget {
  static const _brokenImageIcon = IconData(0xeeff, fontFamily: 'MaterialIcons');

  /// Creates an Aura image.
  const AuraImage({
    required this.url,
    super.key,
    this.fit = BoxFit.fill,
    this.semanticLabel,
  });

  /// The URL of the image to display.
  final String url;

  /// How the image is resized to fit its container.
  final BoxFit fit;

  /// Accessibility text for the image.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = this.semanticLabel;
    final image = Image.network(
      url,
      frameBuilder: _frameBuilder,
      errorBuilder: _errorBuilder,
      semanticLabel: semanticLabel,
      fit: fit,
    );

    if (semanticLabel == null) return image;

    return Semantics(
      child: image,
      container: true,
      excludeSemantics: true,
      image: true,
      label: semanticLabel,
    );
  }

  Widget _frameBuilder(
    BuildContext _,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded || frame != null) return child;

    return const Center(child: AuraSpinner());
  }

  Widget _errorBuilder(BuildContext context, Object _, StackTrace? _) {
    return ColoredBox(
      color: context.auraColors.surfaceVariant,
      child: const Center(
        child: AuraPadding(
          child: AuraIcon(_brokenImageIcon, tint: AuraTint.error),
          padding: AuraEdgeInsetsGeometry.medium,
        ),
      ),
    );
  }
}
