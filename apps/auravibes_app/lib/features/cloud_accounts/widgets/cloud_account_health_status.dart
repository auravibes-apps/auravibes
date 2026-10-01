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
    final value = health.value;
    final needsSignIn = !health.isLoading && value?.status == .needsSignIn;
    final label = health.isLoading
        ? LocaleKeys.cloud_accounts_status_checking
        : switch (value?.status) {
            .verified => LocaleKeys.cloud_accounts_status_verified,
            .needsSignIn => LocaleKeys.cloud_accounts_status_needs_sign_in,
            .unknown || null => LocaleKeys.cloud_accounts_status_unknown,
          };

    return AuraColumn(
      children: [
        Text(account.serverUrl),
        Text(
          label.tr(
            namedArgs: {'time': value?.checkedAt?.toLocal().toString() ?? ''},
          ),
        ),
        AuraButton(
          onPressed: () => _checkOrSignIn(context, ref, needsSignIn),
          child: TextLocale(
            needsSignIn
                ? LocaleKeys.cloud_accounts_sign_in_again
                : LocaleKeys.cloud_accounts_verify,
          ),
          key: ValueKey(
            'account_health_${account.serverUrl}_${account.accountId}',
          ),
          variant: .outlined,
          disabled: health.isLoading,
        ),
      ],
      spacing: .xs,
      crossAxisAlignment: .start,
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
