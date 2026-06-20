import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class AppErrorWidget<T extends Object> extends StatelessWidget {
  const AppErrorWidget({
    required this.error,
    required this.stackTrace,
    this.action,
    super.key,
  });
  final T error;
  final StackTrace stackTrace;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AuraColumn(
          children: [
            const AuraIcon(
              Icons.error_outline,
              size: AuraIconSize.large,
              color: AuraColorVariant.error,
            ),
            const AuraText(
              child: _AppErrorText(
                LocaleKeys.common_error_title,
                maxLines: 2,
              ),
              style: AuraTextStyle.heading6,
              textAlign: TextAlign.center,
            ),
            const AuraText(
              child: _AppErrorText(
                LocaleKeys.common_error_message,
                maxLines: 2,
              ),
              textAlign: TextAlign.center,
              color: AuraColorVariant.onSurfaceVariant,
            ),
            ?action,
          ],
          spacing: AuraSpacing.sm,
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );
  }
}

class _AppErrorText extends StatelessWidget {
  const _AppErrorText(this.localeKey, {this.maxLines});

  final String localeKey;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      _translate(context),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
    );
  }

  String _translate(BuildContext context) {
    if (EasyLocalization.of(context) == null) {
      return localeKey;
    }

    return localeKey.tr(context: context);
  }
}
