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
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AuraColumn(
          children: [
            if (isLoading) const ExcludeSemantics(child: AuraSpinner()),
            Semantics(child: TextLocale(messageKey), liveRegion: true),
            if (onRetry case final retry?)
              AuraButton(
                onPressed: retry,
                child: TextLocale(
                  retryLabelKey ?? LocaleKeys.route_state_retry,
                ),
              ),
            if (onReturn case final returnAction?)
              AuraButton(
                onPressed: returnAction,
                child: TextLocale(
                  returnLabelKey ?? LocaleKeys.route_state_return_workspaces,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
