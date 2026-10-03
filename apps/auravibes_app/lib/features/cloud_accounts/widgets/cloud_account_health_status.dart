import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart'
    as cloud_health;
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class const CloudAccountHealthStatus({
  required final CloudAccountKey account,
  required final String workspaceId,
  required final String returnPath,
  final String? email,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(cloudAccountHealthProvider(account));
    final needsSignIn = _needsCloudAccountSignIn(health);

    return _CloudAccountHealthPanel(
      account: account,
      health: health,
      needsSignIn: needsSignIn,
      onPressed: () => _checkOrSignIn(context, ref, needsSignIn),
    );
  }

  void _checkOrSignIn(BuildContext context, WidgetRef ref, bool needsSignIn) {
    if (!needsSignIn) {
      ref.invalidate(cloudAccountHealthProvider(account));

      return;
    }
    final uri = Uri.parse(
      CloudAccountLoginRoute(
        workspaceId: workspaceId,
        returnPath: returnPath,
      ).location,
    );
    context.go(
      uri
          .replace(
            queryParameters: {
              ...uri.queryParameters,
              'serverUrl': account.serverUrl,
              'accountId': account.accountId,
              'email': ?email,
            },
          )
          .toString(),
    );
  }
}

bool _needsCloudAccountSignIn(
  AsyncValue<cloud_health.CloudAccountHealth> health,
) => !health.isLoading && health.value?.status == .needsSignIn;

class const _CloudAccountHealthPanel({
  required final CloudAccountKey account,
  required final AsyncValue<cloud_health.CloudAccountHealth> health,
  required final bool needsSignIn,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      Text(account.serverUrl),
      _CloudAccountHealthLabel(
        isLoading: health.isLoading,
        status: health.value?.status,
        checkedAt: health.value?.checkedAt,
      ),
      _CloudAccountHealthAction(
        account: account,
        isLoading: health.isLoading,
        needsSignIn: needsSignIn,
        onPressed: onPressed,
      ),
    ],
    spacing: .xs,
    crossAxisAlignment: .start,
  );
}

class const _CloudAccountHealthLabel({
  required final bool isLoading,
  required final cloud_health.CloudAccountHealthStatus? status,
  required final DateTime? checkedAt,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Text(
    _cloudAccountHealthLabel(
      isLoading,
      status,
    ).tr(namedArgs: {'time': checkedAt?.toLocal().toString() ?? ''}),
  );
}

String _cloudAccountHealthLabel(
  bool isLoading,
  cloud_health.CloudAccountHealthStatus? status,
) {
  if (isLoading) return LocaleKeys.cloud_accounts_status_checking;

  return switch (status) {
    .verified => LocaleKeys.cloud_accounts_status_verified,
    .needsSignIn => LocaleKeys.cloud_accounts_status_needs_sign_in,
    .unknown || null => LocaleKeys.cloud_accounts_status_unknown,
  };
}

class const _CloudAccountHealthAction({
  required final CloudAccountKey account,
  required final bool isLoading,
  required final bool needsSignIn,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: TextLocale(
      needsSignIn
          ? LocaleKeys.cloud_accounts_sign_in_again
          : LocaleKeys.cloud_accounts_verify,
    ),
    key: ValueKey('account_health_${account.serverUrl}_${account.accountId}'),
    variant: .outlined,
    disabled: isLoading,
  );
}
