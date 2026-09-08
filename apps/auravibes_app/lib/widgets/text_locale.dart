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
  Widget build(BuildContext context) {
    return Text(
      data.tr(args: args, context: context),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
