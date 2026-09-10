import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class const TextLocale(
  final String data, {
  super.key,
  final List<String>? args,
  final TextStyle? style,
  final StrutStyle? strutStyle,
  final TextAlign? textAlign,
  final Locale? locale,
  final bool? softWrap,
  final TextOverflow? overflow,
  final TextScaler? textScaler,
  final int? maxLines,
  final String? semanticsLabel,
  final TextWidthBasis? textWidthBasis,
  final TextHeightBehavior? textHeightBehavior,
  final Color? selectionColor,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _TranslatedText(this, context);
}

class _TranslatedText extends Text {
  new(TextLocale source, BuildContext context)
    : super(
        source.data.tr(args: source.args, context: context),
        style: source.style,
        strutStyle: source.strutStyle,
        textAlign: source.textAlign,
        locale: source.locale,
        softWrap: source.softWrap,
        overflow: source.overflow,
        textScaler: source.textScaler,
        maxLines: source.maxLines,
        semanticsLabel: source.semanticsLabel,
        textWidthBasis: source.textWidthBasis,
        textHeightBehavior: source.textHeightBehavior,
        selectionColor: source.selectionColor,
      );
}
