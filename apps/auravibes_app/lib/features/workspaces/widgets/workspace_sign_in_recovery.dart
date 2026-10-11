import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/task_return.dart';
import 'package:auravibes_app/router/workspace_route.dart';
import 'package:auravibes_app/widgets/route_recovery_view.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Shared exact-account recovery for session and child-conversation failures.
class const WorkspaceSignInRecovery({
  required final String workspaceId,
  required final WorkspaceSession? session,
  required final VoidCallback onReturn,
  final String? returnLabelKey,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      _WorkspaceSignInRecoveryBody(
        workspaceId: workspaceId,
        session: session,
        onReturn: onReturn,
        returnLabelKey: returnLabelKey,
      );
}

class const _WorkspaceSignInRecoveryBody({
  required final String workspaceId,
  required final WorkspaceSession? session,
  required final VoidCallback onReturn,
  required final String? returnLabelKey,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(cloudAccountsProvider);
    final onRetry = _signInAction(context, ref);

    return _WorkspaceSignInRecoveryView(
      onRetry: onRetry,
      onReturn: onReturn,
      returnLabelKey: returnLabelKey,
    );
  }

  VoidCallback? _signInAction(BuildContext context, WidgetRef ref) {
    final cloud = session?.cloud;
    if (cloud == null) return null;
    final uri = GoRouterState.of(context).uri;

    return () =>
        context.go(_workspaceLoginLocation(ref, uri, workspaceId, cloud));
  }
}

class const _WorkspaceSignInRecoveryView({
  required final VoidCallback? onRetry,
  required final VoidCallback onReturn,
  required final String? returnLabelKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RouteRecoveryView(
    messageKey: LocaleKeys.route_state_sign_in,
    onRetry: onRetry,
    onReturn: onReturn,
    returnLabelKey: returnLabelKey,
    retryLabelKey: LocaleKeys.cloud_accounts_sign_in_again,
  );
}

String _workspaceLoginLocation(
  WidgetRef ref,
  Uri uri,
  String workspaceId,
  CloudWorkspaceRef cloud,
) {
  final key = CloudAccountKeyFactory.fromIdentity(
    cloud.serverUrl,
    cloud.accountId,
  );
  final route = CloudAccountLoginRoute(
    workspaceId: workspaceId,
    returnPath: TaskReturn.validate(uri.toString(), workspaceId: workspaceId),
  ).location;

  return _loginLocation(route, key, _accountEmail(ref, key));
}

String? _accountEmail(WidgetRef ref, CloudAccountKey key) => ref
    .read(cloudAccountsProvider)
    .value
    ?.where((account) => account.key == key)
    .firstOrNull
    ?.email;

String _loginLocation(String location, CloudAccountKey key, String? email) {
  final uri = Uri.parse(location);

  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'serverUrl': key.serverUrl,
          'accountId': key.accountId,
          'email': ?email,
        },
      )
      .toString();
}
