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
  new({
    required this.url,
    required this.color,
    required this.height,
    this.width,
    this.httpClient,
  }) : picture = SvgPicture.network(
         url,
         width: width ?? height,
         height: height,
         placeholderBuilder: (context) => SizedBox(
           width: width ?? height,
           height: height,
           child: ColoredBox(color: context.auraColors.surfaceVariant),
         ),
         colorFilter: .mode(color, .srcIn),
         errorBuilder: (context, _, _) => SizedBox(
           width: width ?? height,
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
                 label: LocaleKeys.models_screens_add_provider_search_no_icon
                     .tr(context: context),
               ),
             ),
           ),
         ),
         imageBuilder: (context, child) => TweenAnimationBuilder<double>(
           tween: .new(begin: 0, end: 1),
           duration: TickerMode.valuesOf(context).enabled
               ? context.auraTheme.animation.fast
               : Duration.zero,
           builder: (_, opacity, child) =>
               Opacity(opacity: opacity, child: child),
           child: child,
         ),
         httpClient: httpClient,
       );

  final String url;
  final Color color;
  final double height;
  final double? width;
  final http.Client? httpClient;
  final SvgPicture picture;

  @override
  Widget build(BuildContext context) => picture;
}
