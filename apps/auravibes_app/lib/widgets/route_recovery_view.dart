import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

/// Safe localized feedback shared by workspace and child-conversation gates.
class RouteRecoveryView extends StatelessWidget {
  const new({
    required this.messageKey,
    this.onRetry,
    this.onReturn,
    this.returnLabelKey,
    this.retryLabelKey,
    this.isLoading = false,
    super.key,
  });

  final String messageKey;
  final VoidCallback? onRetry;
  final VoidCallback? onReturn;
  final String? returnLabelKey;
  final String? retryLabelKey;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => AuraScreen(
    child: _RouteRecoveryBody(
      messageKey: messageKey,
      onRetry: onRetry,
      onReturn: onReturn,
      returnLabelKey: returnLabelKey,
      retryLabelKey: retryLabelKey,
      isLoading: isLoading,
    ),
  );
}

class _RouteRecoveryBody extends StatelessWidget {
  const new({
    required this.messageKey,
    required this.onRetry,
    required this.onReturn,
    required this.returnLabelKey,
    required this.retryLabelKey,
    required this.isLoading,
  });

  final String messageKey;
  final VoidCallback? onRetry;
  final VoidCallback? onReturn;
  final String? returnLabelKey;
  final String? retryLabelKey;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _RouteRecoveryMessageColumn(
        messageKey: messageKey,
        onRetry: onRetry,
        onReturn: onReturn,
        returnLabelKey: returnLabelKey,
        retryLabelKey: retryLabelKey,
        isLoading: isLoading,
      ),
    ),
  );
}

class _RouteRecoveryMessageColumn extends StatelessWidget {
  const new({
    required this.messageKey,
    required this.onRetry,
    required this.onReturn,
    required this.returnLabelKey,
    required this.retryLabelKey,
    required this.isLoading,
  });

  final String messageKey;
  final VoidCallback? onRetry;
  final VoidCallback? onReturn;
  final String? returnLabelKey;
  final String? retryLabelKey;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _RouteRecoveryMessage(messageKey: messageKey, isLoading: isLoading),
      if (onRetry != null || onReturn != null)
        _RouteRecoveryActions(
          onRetry: onRetry,
          retryLabelKey: retryLabelKey,
          onReturn: onReturn,
          returnLabelKey: returnLabelKey,
        ),
    ],
  );
}

class const _RouteRecoveryMessage({
  required final String messageKey,
  required final bool isLoading,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (isLoading) const ExcludeSemantics(child: AuraSpinner()),
      Semantics(child: TextLocale(messageKey), liveRegion: true),
    ],
    mainAxisSize: .min,
  );
}

class const _RouteRecoveryActions({
  required final VoidCallback? onRetry,
  required final String? retryLabelKey,
  required final VoidCallback? onReturn,
  required final String? returnLabelKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      if (onRetry case final retry?)
        _RouteRecoveryAction(
          onPressed: retry,
          labelKey: retryLabelKey ?? LocaleKeys.route_state_retry,
        ),
      if (onReturn case final returnAction?)
        _RouteRecoveryAction(
          onPressed: returnAction,
          labelKey: returnLabelKey ?? LocaleKeys.route_state_return_workspaces,
        ),
    ],
    mainAxisSize: .min,
  );
}

class _RouteRecoveryAction extends StatelessWidget {
  const new({required this.onPressed, required this.labelKey});

  final VoidCallback onPressed;
  final String labelKey;

  @override
  Widget build(BuildContext context) =>
      AuraButton(onPressed: onPressed, child: TextLocale(labelKey));
}
