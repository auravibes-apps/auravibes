import 'dart:async';

import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_auth_target.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_accounts/widgets/cloud_account_auth_content.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/cloud_workspaces/widgets/cloud_workspace_connect_list.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_creation_draft.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_creation_draft_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_form.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A task-owned draft and callback auth flow that also works before first use.
class const WorkspaceSetupContent({
  required final String taskId,
  required final ValueChanged<WorkspaceEntity> onCreated,
  final VoidCallback? onReturn,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<WorkspaceSetupContent> createState() =>
      _WorkspaceSetupContentState();
}

class _WorkspaceSetupContentState extends ConsumerState<WorkspaceSetupContent> {
  final _exitGuard = DraftExitGuard();
  CloudAuthTarget? _auth;
  bool _busy = false;
  bool _creating = false;

  bool _completedTask = false;
  String? _error;

  bool get _pending => _busy || _creating;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(workspaceCreationDraftProvider(widget.taskId));
    _exitGuard.bind(
      isDirty: () =>
          !_completedTask && (draft.name.isNotEmpty || draft.target.isNotEmpty),
      isSaving: () => _pending && !_completedTask,
      onReturn: (_) => widget.onReturn?.call(),
    );
    if (_auth case final target?) {
      return DraftExitScope(
        guard: _exitGuard,
        child: CloudAccountAuthContent(
          onSignedIn: _signedIn,
          onCancel: () => setState(() => _auth = null),
          target: target,
          returnTaskLabel: 'workspace_setup.${draft.intent.name}'.tr(),
        ),
      );
    }
    final accounts = ref.watch(cloudAccountsProvider);

    final body = AuraColumn(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final intent in WorkspaceCreationIntent.values)
              AuraButton(
                onPressed: () => _choose(intent),
                child: TextLocale('workspace_setup.${intent.name}'),
                key: ValueKey('workspace_intent_${intent.name}'),
                variant: intent == draft.intent ? .primary : .outlined,
                disabled: _pending,
              ),
          ],
        ),
        TextLocale(
          draft.intent == .local
              ? 'workspace_setup.local_body'
              : 'intro_flow.choice.body',
        ),
        if (accounts.hasError)
          AuraButton(
            onPressed: () => ref.invalidate(cloudAccountsProvider),
            child: const TextLocale('workspace_management.cloud_retry'),
          ),
        if (draft.intent != .connect)
          CreateWorkspaceForm(
            onCreated: _completed,
            onAddCloudAccount: _addAccount,
            onCreatingChanged: (creating) =>
                setState(() => _creating = creating),
            canAddCloudAccount: true,
            onReturn: widget.onReturn,
            taskId: widget.taskId,
            key: ValueKey(draft.intent),
          )
        else ...[
          AuraButton(
            onPressed: _addAccount,
            child: const TextLocale('workspace_setup.add_account'),
          ),
          switch (accounts) {
            AsyncData(:final value) => AuraColumn(
              children: [
                for (final account in value)
                  _WorkspaceDiscovery(
                    account: account,
                    accounts: value,
                    onConnect: (workspace) =>
                        unawaited(_connect(account, workspace)),
                    onOpen: _completed,
                    onInvite: (invite, {required accept}) => unawaited(
                      _respondToInvite(account, invite, accept: accept),
                    ),
                    onSignIn: () => setState(
                      () => _auth = .new(
                        serverUrl: account.key.serverUrl,
                        accountId: account.userId,
                        email: account.email,
                      ),
                    ),
                  ),
                if (value.isEmpty)
                  const TextLocale('workspace_setup.sign_in_connect'),
              ],
            ),
            AsyncError() => const TextLocale('cloud_accounts.load_error'),
            AsyncLoading() => const Center(child: AuraSpinner()),
          },
        ],
        if (_busy) const Center(child: AuraSpinner()),
        if (_error case final error?) TextLocale(error),
      ],
      spacing: .md,
      crossAxisAlignment: .stretch,
    );

    return draft.intent == .connect
        ? DraftExitScope(guard: _exitGuard, child: body)
        : body;
  }

  void _choose(WorkspaceCreationIntent intent) {
    if (_pending) return;
    final accounts =
        ref.read(cloudAccountsProvider).asData?.value ??
        const <CloudAccountSession>[];
    final draft = ref.read(workspaceCreationDraftProvider(widget.taskId));
    final account = accounts.firstOrNull;
    final target = switch (intent) {
      .local => '',
      _ when draft.target.isNotEmpty => draft.target,
      _ when account != null => CloudAccountIdentity.accountIdentity(
        account.serverUrl,
        account.userId,
      ),
      _ => '__cloud__',
    };
    ref
        .read(workspaceCreationDraftProvider(widget.taskId).notifier)
        .update(intent: intent, target: target);
    if (intent != .local && accounts.isEmpty) _addAccount();
  }

  void _addAccount() {
    if (_pending) return;
    final draft = ref.read(workspaceCreationDraftProvider(widget.taskId));
    if (draft.intent == .local) {
      ref
          .read(workspaceCreationDraftProvider(widget.taskId).notifier)
          .update(intent: .cloud, target: '__cloud__');
    }
    setState(() => _auth = const CloudAuthTarget());
  }

  void _signedIn(CloudAccountSession account) {
    ref
        .read(workspaceCreationDraftProvider(widget.taskId).notifier)
        .update(
          target: CloudAccountIdentity.accountIdentity(
            account.serverUrl,
            account.userId,
          ),
        );
    setState(() => _auth = null);
  }

  void _completed(WorkspaceEntity workspace) {
    _completedTask = true;
    ref.invalidate(workspaceCreationDraftProvider(widget.taskId));
    widget.onCreated(workspace);
  }

  Future<void> _respondToInvite(
    CloudAccountSession account,
    PendingWorkspaceInviteSummary invite, {
    required bool accept,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final usecases = await ref.read(
        cloudWorkspaceUseCasesProvider(account.key).future,
      );
      if (usecases == null) {
        throw const AppCloudWorkspaceException('cloud_errors.unavailable');
      }
      if (accept) {
        final workspace = await usecases.acceptInvite(invite);
        ref.invalidate(allWorkspacesProvider);
        if (mounted) _completed(workspace);
      } else {
        await usecases.declineInvite(invite);
      }
      ref.invalidate(cloudWorkspaceStateProvider(account.key));
    } on Object catch (error) {
      if (error is CloudWorkspaceException &&
          CheckCloudAccountUsecase.requiresSignIn(error)) {
        ref.invalidate(cloudAccountHealthProvider(account.key));
      }
      if (mounted) {
        setState(() => _error = 'workspace_management.cloud_load_error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect(
    CloudAccountSession account,
    CloudWorkspaceSummary workspace,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final usecases = await ref.read(
        cloudWorkspaceUseCasesProvider(account.key).future,
      );
      if (usecases == null) {
        throw const AppCloudWorkspaceException(
          'cloud_accounts.origin_unresolved',
        );
      }
      final connected = await usecases.attach(workspace);
      ref.invalidate(allWorkspacesProvider);
      if (mounted) _completed(connected);
    } on AppCloudWorkspaceException catch (error) {
      if (mounted) setState(() => _error = error.localizationKey);
    } on Object {
      if (mounted) {
        setState(() => _error = 'workspace_management.cloud_load_error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class const _WorkspaceDiscovery({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final ValueChanged<CloudWorkspaceSummary> onConnect,
  required final ValueChanged<WorkspaceEntity> onOpen,
  required final void Function(
    PendingWorkspaceInviteSummary, {
    required bool accept,
  })
  onInvite,
  required final VoidCallback onSignIn,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cloudWorkspaceStateProvider(account.key));

    return AuraColumn(
      children: [
        Text('${account.email} (${account.key.serverUrl})'),
        switch (state) {
          AsyncData(value: final value?) when value.authenticationRequired =>
            AuraButton(
              onPressed: onSignIn,
              child: const TextLocale('cloud_accounts.session_expired'),
            ),
          AsyncData(value: final value?) => AuraColumn(
            children: [
              for (final invite in value.pendingInvites)
                AuraColumn(
                  children: [
                    Text(invite.workspaceName),
                    Wrap(
                      children: [
                        AuraButton(
                          onPressed: () => onInvite(invite, accept: true),
                          child: const TextLocale(
                            'workspace_management.cloud_accept',
                          ),
                        ),
                        AuraButton(
                          onPressed: () => onInvite(invite, accept: false),
                          child: const TextLocale(
                            'workspace_management.cloud_decline',
                          ),
                          variant: .outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              if (value.workspaces.isEmpty)
                const TextLocale('cloud_accounts.no_workspaces'),
              CloudWorkspaceConnectList(
                account: account,
                accounts: accounts,
                localWorkspaces:
                    ref.watch(allWorkspacesProvider).asData?.value ?? const [],
                workspaces: value.workspaces,
                onConnect: onConnect,
                onOpen: onOpen,
              ),
            ],
          ),
          AsyncLoading() => const Center(child: AuraSpinner()),
          AsyncError() || AsyncData(value: null) => AuraColumn(
            children: [
              const TextLocale('workspace_management.cloud_load_error'),
              AuraButton(
                onPressed: () => _retry(ref),
                child: const TextLocale('workspace_management.cloud_retry'),
              ),
            ],
          ),
        },
      ],
      crossAxisAlignment: .stretch,
    );
  }

  void _retry(WidgetRef ref) {
    ref
      ..invalidate(cloudAccountHealthProvider(account.key))
      ..invalidate(cloudWorkspaceStateProvider(account.key));
  }
}
