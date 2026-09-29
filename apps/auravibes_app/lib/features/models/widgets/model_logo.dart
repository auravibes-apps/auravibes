// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

/// A reusable widget for displaying model provider logos.
class const ModelLogo({
  required super.modelId,
  super.height,
  super.width,
  super.svgBuilder,
  super.httpClient,
  super.key,
}) extends _ModelLogo;

class const _ModelLogo({
  required final String modelId,
  final double height = 20,
  final double? width,
  final Widget Function(BuildContext context, String url)? svgBuilder,
  final http.Client? httpClient,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final url = 'https://models.dev/logos/$modelId.svg';
    final svgBuilder = this.svgBuilder;
    if (svgBuilder != null) {
      return svgBuilder(context, url);
    }

    return _ModelLogoNetwork(
      url: url,
      color: context.auraColors.onBackground,
      height: height,
      width: width,
      httpClient: httpClient,
    );
  }
}

class _ModelLogoNetwork extends StatelessWidget {
  const new({
    required this.url,
    required this.color,
    required this.height,
    this.width,
    this.httpClient,
  });

  final String url;
  final Color color;
  final double height;
  final double? width;
  final http.Client? httpClient;
  @override
  Widget build(BuildContext context) => SvgPicture.network(
    url,
    width: width ?? height,
    height: height,
    placeholderBuilder: _buildPlaceholder,
    colorFilter: .mode(color, .srcIn),
    errorBuilder: (context, _, _) => _buildError(context),
    imageBuilder: (_, child) => _buildAnimatedImage(child),
    httpClient: httpClient,
  );

  Widget _buildPlaceholder(BuildContext context) => SizedBox(
    width: width ?? height,
    height: height,
    child: ColoredBox(color: context.auraColors.surfaceVariant),
  );

  Widget _buildError(BuildContext context) => _ModelLogoErrorFallback(
    width: width ?? height,
    height: height,
    label: LocaleKeys.models_screens_add_provider_search_no_icon.tr(
      context: context,
    ),
  );

  Widget _buildAnimatedImage(Widget child) => _ModelLogoFadeIn(child: child);
}

class const _ModelLogoErrorFallback({
  required final double width,
  required final double height,
  required final String label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: ColoredBox(
      color: context.auraColors.surfaceVariant,
      child: Center(
        child: Semantics(
          child: Icon(
            Icons.broken_image_outlined,
            size: 16,
            color: context.auraColors.onSurfaceVariant,
          ),
          label: label,
        ),
      ),
    ),
  );
}

class const _ModelLogoFadeIn({required final Widget child})
    extends StatelessWidget {
  static final _tween = Tween<double>(begin: 0, end: 1);

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: _tween,
    duration: _durationFor(context),
    builder: (_, opacity, child) =>
        _ModelLogoOpacity(opacity: opacity, child: child),
    child: child,
  );

  static Duration _durationFor(BuildContext context) =>
      TickerMode.valuesOf(context).enabled
      ? context.auraTheme.animation.fast
      : Duration.zero;
}

class const _ModelLogoOpacity({
  required final double opacity,
  required final Widget? child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Opacity(opacity: opacity, child: child);
}
