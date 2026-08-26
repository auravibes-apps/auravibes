import 'package:auravibes_app/features/workspaces/models/workspace_capabilities.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _logger = Logger('app_error_widget');

class AppErrorWidget<T extends Object> extends StatefulWidget {
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
          const AuraIcon(
            Icons.error_outline,
            size: AuraIconSize.large,
            tint: AuraTint.error,
          ),
          const AuraText(
            child: _AppErrorText(LocaleKeys.common_error_title),
            style: AuraTextStyle.heading6,
            textAlign: TextAlign.center,
          ),
          AuraText(
            child: _AppErrorText(switch (widget.error) {
              UnsupportedWorkspaceCapabilityException(:final localizationKey) =>
                localizationKey,
              CloudAppException(:final localizationKey) => localizationKey,
              _ => LocaleKeys.common_error_message,
            }),
            textAlign: TextAlign.center,
          ),
          ?widget.action,
        ],
        spacing: AuraSpacing.sm,
        mainAxisSize: MainAxisSize.min,
        padding: AuraEdgeInsetsGeometry.base,
      ),
    );
  }
}

class _AppErrorText extends StatelessWidget {
  const _AppErrorText(this.localeKey);

  final String localeKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      _translate(context),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }

  String _translate(BuildContext context) {
    if (EasyLocalization.of(context) == null) {
      return localeKey;
    }

    return localeKey.tr(context: context);
  }
}
