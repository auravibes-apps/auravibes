import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app_error_widget');

class const AppErrorWidget<T extends Object>({
  required final T error,
  required final StackTrace stackTrace,
  final Widget? action,
  super.key,
}) extends StatefulWidget {
  @override
  State<AppErrorWidget<T>> createState() => _AppErrorWidgetState<T>();
}

class _AppErrorWidgetState<T extends Object> extends State<AppErrorWidget<T>> {
  @override
  void initState() {
    super.initState();
    _logger.severe('Displaying error UI', widget.error, widget.stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AuraColumn(
        children: [
          const AuraIcon(Icons.error_outline, size: .large, tint: .error),
          const AuraText(
            child: _AppErrorText(LocaleKeys.common_error_title),
            style: .heading6,
            textAlign: .center,
          ),
          AuraText(
            child: _AppErrorText(switch (widget.error) {
              UnsupportedWorkspaceCapabilityException(:final localizationKey) =>
                localizationKey,
              CloudAppException(:final localizationKey) => localizationKey,
              _ => LocaleKeys.common_error_message,
            }),
            textAlign: .center,
          ),
          ?widget.action,
        ],
        spacing: .sm,
        mainAxisSize: .min,
        padding: .base,
      ),
    );
  }
}

class const _AppErrorText(final String localeKey) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(_translate(context), overflow: .ellipsis, maxLines: 2);
  }

  String _translate(BuildContext context) {
    if (EasyLocalization.of(context) == null) {
      return localeKey;
    }

    return localeKey.tr(context: context);
  }
}
