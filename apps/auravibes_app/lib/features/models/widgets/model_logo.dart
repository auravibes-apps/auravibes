// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// Required: Existing test and UI helpers keep compact return flow.

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;

/// A reusable widget for displaying model provider logos.
class ModelLogo extends StatelessWidget {
  const ModelLogo({
    required this.modelId,
    this.height = 20,
    this.width,
    this.svgBuilder,
    this.httpClient,
    super.key,
  });

  final String modelId;
  final double height;
  final double? width;
  final Widget Function(BuildContext context, String url)? svgBuilder;
  final http.Client? httpClient;

  @override
  Widget build(BuildContext context) {
    final url = 'https://models.dev/logos/$modelId.svg';
    final svgBuilder = this.svgBuilder;
    if (svgBuilder != null) {
      return svgBuilder(context, url);
    }

    return SvgPicture.network(
      url,
      width: width,
      height: height,
      placeholderBuilder: (context) {
        return const AuraSpinner();
      },
      colorFilter: ColorFilter.mode(
        context.auraColors.onBackground,
        BlendMode.srcIn,
      ),
      errorBuilder: (context, error, stackTrace) {
        return const AuraText(
          child: TextLocale(
            LocaleKeys.models_screens_add_provider_search_no_icon,
          ),
        );
      },
      httpClient: httpClient,
    );
  }
}
