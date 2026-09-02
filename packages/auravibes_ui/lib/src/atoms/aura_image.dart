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
  const new({
    required this.url,
    super.key,
    this.fit = BoxFit.fill,
    this.semanticLabel,
    this.imageProvider,
    this.errorSemanticLabel = 'Image failed to load',
  });

  /// The URL of the image to display.
  final String url;

  /// How the image is resized to fit its container.
  final BoxFit fit;

  /// Accessibility text for the image.
  final String? semanticLabel;

  /// Optional local image provider used instead of [url].
  final ImageProvider<Object>? imageProvider;

  /// Accessibility text for the error state.
  final String? errorSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final semanticLabel = this.semanticLabel;
    final image = Image(
      image: imageProvider ?? NetworkImage(url),
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
    return Semantics(
      child: ColoredBox(
        color: context.auraColors.surfaceVariant,
        child: const Center(
          child: AuraPadding(
            child: AuraIcon(_brokenImageIcon, tint: AuraTint.error),
            padding: AuraEdgeInsetsGeometry.medium,
          ),
        ),
      ),
      container: true,
      image: true,
      label: errorSemanticLabel,
    );
  }
}
