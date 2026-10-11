import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/features/workspaces/widgets/workspace_sign_in_recovery.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/workspace_navigation.dart';
import 'package:auravibes_app/widgets/route_recovery_view.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Keeps app-scoped recovery destinations reachable under expired access.
class const WorkspaceAccessGate({
  required final String workspaceId,
  required final WorkspaceSession session,
  required final Widget child,
  required final VoidCallback onChooseWorkspace,
  super.key,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = GoRouterState.of(context).uri;
    if (WorkspaceNavigation.isAppScoped(uri) || session.cloud == null) {
      return child;
    }

    return _WorkspaceAvailabilityGate(
      workspaceId: workspaceId,
      session: session,
      child: child,
      onChooseWorkspace: onChooseWorkspace,
    );
  }
}

class const _WorkspaceAvailabilityGate({
  required final String workspaceId,
  required final WorkspaceSession session,
  required final Widget child,
  required final VoidCallback onChooseWorkspace,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(workspaceAvailabilityProvider(workspaceId));

    return _WorkspaceAvailabilityStateView(
      availability: availability,
      child: child,
      onAuthenticationRequired: _signInRecovery,
      onRetry: () => _retry(ref),
      onReturn: onChooseWorkspace,
    );
  }

  Widget _signInRecovery() => WorkspaceSignInRecovery(
    workspaceId: workspaceId,
    session: session,
    onReturn: onChooseWorkspace,
  );

  void _retry(WidgetRef ref) {
    final cloud = session.cloud;
    if (cloud != null) {
      ref.invalidate(
        cloudAccountHealthProvider(
          CloudAccountKeyFactory.fromIdentity(cloud.serverUrl, cloud.accountId),
        ),
      );
    }
    ref.invalidate(workspaceAvailabilityProvider(workspaceId));
  }
}

class const _WorkspaceAvailabilityStateView({
  required final AsyncValue<WorkspaceAvailability> availability,
  required final Widget child,
  required final Widget Function() onAuthenticationRequired,
  required final VoidCallback onRetry,
  required final VoidCallback onReturn,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      switch ((value: availability.value, loading: availability.isLoading)) {
        (value: WorkspaceAvailable(), loading: _) => child,
        (value: WorkspaceAuthenticationRequired(), loading: _) =>
          onAuthenticationRequired(),
        (value: _, loading: true) => const RouteRecoveryView(
          messageKey: LocaleKeys.route_state_workspace_loading,
          isLoading: true,
        ),
        _ => RouteRecoveryView(
          messageKey: LocaleKeys.route_state_workspace_error,
          onRetry: onRetry,
          onReturn: onReturn,
        ),
      };
}
