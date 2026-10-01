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
  static const _intentButtonSpacing = 8.0;

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
    _bindExitGuard(draft);
    if (_auth case final target?) {
      return _WorkspaceSetupAuthFlow(state: this, draft: draft, target: target);
    }

    return _WorkspaceSetupPage(
      state: this,
      draft: draft,
      accounts: ref.watch(cloudAccountsProvider),
    );
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

  void _signInAccount(CloudAccountSession account) {
    setState(
      () => _auth = .new(
        serverUrl: account.key.serverUrl,
        accountId: account.userId,
        email: account.email,
      ),
    );
  }

  void _setCloudActionError(String error) {
    if (mounted) setState(() => _error = error);
  }

  void _setCreating(bool creating) => setState(() => _creating = creating);

  void _cancelAuth() => setState(() => _auth = null);

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
      await _performInviteResponse(account, invite, accept: accept);
    } on Object catch (error) {
      _handleInviteFailure(account, error);
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
      await _performWorkspaceConnection(account, workspace);
    } on AppCloudWorkspaceException catch (error) {
      _setCloudActionError(error.localizationKey);
    } on Object {
      _setCloudActionError('workspace_management.cloud_load_error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

extension _WorkspaceSetupDraftActions on _WorkspaceSetupContentState {
  void _bindExitGuard(WorkspaceCreationDraft draft) {
    _exitGuard.bind(
      readers: (
        isDirty: () => !_completedTask && _draftHasChanges(draft),
        isSaving: _isSaving,
      ),
      onReturn: (_) => widget.onReturn?.call(),
    );
  }

  bool _draftHasChanges(WorkspaceCreationDraft draft) =>
      draft.name.isNotEmpty || draft.target.isNotEmpty;

  bool _isSaving() => _pending && !_completedTask;

  void _choose(WorkspaceCreationIntent intent) {
    if (_pending) return;
    final accounts = _availableCloudAccounts();
    final draft = ref.read(workspaceCreationDraftProvider(widget.taskId));
    _saveIntent(intent, _intentTarget(intent, draft, accounts));
    _maybeAddAccount(intent, accounts);
  }

  List<CloudAccountSession> _availableCloudAccounts() =>
      ref.read(cloudAccountsProvider).asData?.value ??
      const <CloudAccountSession>[];

  void _maybeAddAccount(
    WorkspaceCreationIntent intent,
    List<CloudAccountSession> accounts,
  ) {
    if (intent != .local && accounts.isEmpty) _addAccount();
  }

  String _intentTarget(
    WorkspaceCreationIntent intent,
    WorkspaceCreationDraft draft,
    List<CloudAccountSession> accounts,
  ) {
    if (intent == .local) return '';
    if (draft.target.isNotEmpty) return draft.target;
    final account = accounts.firstOrNull;
    if (account == null) return '__cloud__';

    return CloudAccountIdentity.accountIdentity(
      account.serverUrl,
      account.userId,
    );
  }

  void _saveIntent(WorkspaceCreationIntent intent, String target) {
    ref
        .read(workspaceCreationDraftProvider(widget.taskId).notifier)
        .update(intent: intent, target: target);
  }

  void _retry() => ref.invalidate(cloudAccountsProvider);

  void _completed(WorkspaceEntity workspace) {
    _completedTask = true;
    ref.invalidate(workspaceCreationDraftProvider(widget.taskId));
    widget.onCreated(workspace);
  }
}

extension _WorkspaceSetupCloudActions on _WorkspaceSetupContentState {
  void _connectFromAccount(
    CloudAccountSession account,
    CloudWorkspaceSummary workspace,
  ) => unawaited(_connect(account, workspace));

  void _respondFromAccount(
    CloudAccountSession account,
    PendingWorkspaceInviteSummary invite, {
    required bool accept,
  }) => unawaited(_respondToInvite(account, invite, accept: accept));

  Future<CloudWorkspaceUseCases?> _cloudUseCases(CloudAccountKey key) =>
      ref.read(cloudWorkspaceUseCasesProvider(key).future);

  Future<void> _performInviteResponse(
    CloudAccountSession account,
    PendingWorkspaceInviteSummary invite, {
    required bool accept,
  }) async {
    final usecases = await _cloudUseCases(account.key);
    if (usecases == null) {
      throw const AppCloudWorkspaceException('cloud_errors.unavailable');
    }
    await _applyInviteResponse(usecases, account, invite, accept);
  }

  Future<void> _applyInviteResponse(
    CloudWorkspaceUseCases usecases,
    CloudAccountSession account,
    PendingWorkspaceInviteSummary invite,
    bool accept,
  ) async {
    if (accept) {
      final workspace = await usecases.acceptInvite(invite);
      ref.invalidate(allWorkspacesProvider);
      if (mounted) _completed(workspace);
    } else {
      await usecases.declineInvite(invite);
    }
    ref.invalidate(cloudWorkspaceStateProvider(account.key));
  }

  void _handleInviteFailure(CloudAccountSession account, Object error) {
    if (error is CloudWorkspaceException &&
        CheckCloudAccountUsecase.requiresSignIn(error)) {
      ref.invalidate(cloudAccountHealthProvider(account.key));
    }
    _setCloudActionError('workspace_management.cloud_load_error');
  }

  Future<void> _performWorkspaceConnection(
    CloudAccountSession account,
    CloudWorkspaceSummary workspace,
  ) async {
    final usecases = await _cloudUseCases(account.key);
    if (usecases == null) {
      throw const AppCloudWorkspaceException(
        'cloud_accounts.origin_unresolved',
      );
    }
    final connected = await usecases.attach(workspace);
    ref.invalidate(allWorkspacesProvider);
    if (mounted) _completed(connected);
  }
}

class const _WorkspaceSetupPage({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationDraft draft,
  required final AsyncValue<List<CloudAccountSession>> accounts,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = _WorkspaceSetupBody(
      state: state,
      draft: draft,
      accounts: accounts,
    );
    if (draft.intent != .connect) return content;

    return DraftExitScope(guard: state._exitGuard, child: content);
  }
}

class const _WorkspaceSetupBody({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationDraft draft,
  required final AsyncValue<List<CloudAccountSession>> accounts,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _WorkspaceSetupChoices(state: state, draft: draft),
      _WorkspaceAccountStatus(state: state, accounts: accounts),
      _WorkspaceCreateOrConnect(state: state, draft: draft, accounts: accounts),
      if (state._busy) const Center(child: AuraSpinner()),
      if (state._error case final message?) TextLocale(message),
    ],
    spacing: .md,
    crossAxisAlignment: .stretch,
  );
}

class const _WorkspaceSetupChoices({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _WorkspaceIntentButtons(state: state, selected: draft.intent),
      TextLocale(
        draft.intent == .local
            ? 'workspace_setup.local_body'
            : 'intro_flow.choice.body',
      ),
    ],
    spacing: .md,
    crossAxisAlignment: .stretch,
  );
}

class const _WorkspaceAccountStatus({
  required final _WorkspaceSetupContentState state,
  required final AsyncValue<List<CloudAccountSession>> accounts,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => accounts.hasError
      ? _WorkspaceAccountsRetryButton(onPressed: state._retry)
      : const SizedBox.shrink();
}

class const _WorkspaceIntentButtons({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationIntent selected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: _WorkspaceSetupContentState._intentButtonSpacing,
    runSpacing: _WorkspaceSetupContentState._intentButtonSpacing,
    children: [
      for (final intent in WorkspaceCreationIntent.values)
        _WorkspaceIntentButton(
          intent: intent,
          isSelected: intent == selected,
          isPending: state._pending,
          onPressed: () => state._choose(intent),
        ),
    ],
  );
}

class const _WorkspaceIntentButton({
  required final WorkspaceCreationIntent intent,
  required final bool isSelected,
  required final bool isPending,
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: TextLocale('workspace_setup.${intent.name}'),
    key: ValueKey('workspace_intent_${intent.name}'),
    variant: isSelected ? .primary : .outlined,
    disabled: isPending,
  );
}

class const _WorkspaceSetupAuthFlow({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationDraft draft,
  required final CloudAuthTarget target,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DraftExitScope(
    guard: state._exitGuard,
    child: CloudAccountAuthContent(
      onSignedIn: state._signedIn,
      onCancel: state._cancelAuth,
      target: target,
      returnTaskLabel: 'workspace_setup.${draft.intent.name}'.tr(),
    ),
  );
}

class const _WorkspaceAccountsRetryButton({
  required final VoidCallback onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale('workspace_management.cloud_retry'),
  );
}

class const _WorkspaceCreateOrConnect({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationDraft draft,
  required final AsyncValue<List<CloudAccountSession>> accounts,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (draft.intent == .connect) {
      return _WorkspaceConnectAccounts(state: state, accounts: accounts);
    }

    return CreateWorkspaceForm(
      onCreated: state._completed,
      onAddCloudAccount: state._addAccount,
      onCreatingChanged: state._setCreating,
      canAddCloudAccount: true,
      onReturn: state.widget.onReturn,
      taskId: state.widget.taskId,
      key: ValueKey(draft.intent),
    );
  }
}

class const _WorkspaceConnectAccounts({
  required final _WorkspaceSetupContentState state,
  required final AsyncValue<List<CloudAccountSession>> accounts,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _WorkspaceAddAccountButton(onPressed: state._addAccount),
      switch (accounts) {
        AsyncData(:final value) => _WorkspaceDiscoveryList(
          accounts: value,
          state: state,
        ),
        AsyncError() => const TextLocale('cloud_accounts.load_error'),
        AsyncLoading() => const Center(child: AuraSpinner()),
      },
    ],
    spacing: .md,
  );
}

class const _WorkspaceAddAccountButton({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale('workspace_setup.add_account'),
  );
}

class const _WorkspaceDiscoveryList({
  required final List<CloudAccountSession> accounts,
  required final _WorkspaceSetupContentState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final account in accounts)
        _WorkspaceDiscovery(account: account, accounts: accounts, state: state),
      if (accounts.isEmpty) const TextLocale('workspace_setup.sign_in_connect'),
    ],
  );
}

class const _WorkspaceDiscovery({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final _WorkspaceSetupContentState state,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => AuraColumn(
    children: [
      Text('${account.email} (${account.key.serverUrl})'),
      _WorkspaceDiscoveryContent(
        account: account,
        accounts: accounts,
        state: ref.watch(cloudWorkspaceStateProvider(account.key)),
        setupState: state,
        onRetry: () => _retry(ref),
      ),
    ],
    crossAxisAlignment: .stretch,
  );

  void _retry(WidgetRef ref) {
    ref
      ..invalidate(cloudAccountHealthProvider(account.key))
      ..invalidate(cloudWorkspaceStateProvider(account.key));
  }
}

class const _WorkspaceDiscoveryContent({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final AsyncValue<CloudWorkspaceViewState?> state,
  required final _WorkspaceSetupContentState setupState,
  required final VoidCallback onRetry,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (state) {
    AsyncData(value: final value?) => _WorkspaceDiscoveryReady(
      account: account,
      accounts: accounts,
      value: value,
      setupState: setupState,
    ),
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncError() ||
    AsyncData(value: null) => _WorkspaceDiscoveryError(onRetry: onRetry),
  };
}

class const _WorkspaceDiscoveryReady({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final CloudWorkspaceViewState value,
  required final _WorkspaceSetupContentState setupState,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => value.authenticationRequired
      ? _WorkspaceDiscoverySignIn(
          onPressed: () => setupState._signInAccount(account),
        )
      : _WorkspaceDiscoveryData(
          account: account,
          accounts: accounts,
          value: value,
          setupState: setupState,
        );
}

class const _WorkspaceDiscoverySignIn({required final VoidCallback onPressed})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: const TextLocale('cloud_accounts.session_expired'),
  );
}

class const _WorkspaceDiscoveryError({required final VoidCallback onRetry})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const TextLocale('workspace_management.cloud_load_error'),
      AuraButton(
        onPressed: onRetry,
        child: const TextLocale('workspace_management.cloud_retry'),
      ),
    ],
  );
}

class const _WorkspaceDiscoveryData({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final CloudWorkspaceViewState value,
  required final _WorkspaceSetupContentState setupState,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _WorkspaceDiscoveryInvites(
        account: account,
        invites: value.pendingInvites,
        setupState: setupState,
      ),
      if (value.workspaces.isEmpty)
        const TextLocale('cloud_accounts.no_workspaces'),
      _WorkspaceDiscoveryCloudList(
        account: account,
        accounts: accounts,
        workspaces: value.workspaces,
        setupState: setupState,
      ),
    ],
  );
}

class const _WorkspaceDiscoveryInvites({
  required final CloudAccountSession account,
  required final List<PendingWorkspaceInviteSummary> invites,
  required final _WorkspaceSetupContentState setupState,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final invite in invites)
        _WorkspaceDiscoveryInvite(
          invite: invite,
          account: account,
          setupState: setupState,
        ),
    ],
  );
}

class const _WorkspaceDiscoveryInvite({
  required final PendingWorkspaceInviteSummary invite,
  required final CloudAccountSession account,
  required final _WorkspaceSetupContentState setupState,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      Text(invite.workspaceName),
      Wrap(
        children: [
          _WorkspaceDiscoveryInviteButton(
            invite: invite,
            account: account,
            setupState: setupState,
            accept: true,
          ),
          _WorkspaceDiscoveryInviteButton(
            invite: invite,
            account: account,
            setupState: setupState,
            accept: false,
          ),
        ],
      ),
    ],
  );
}

class const _WorkspaceDiscoveryInviteButton({
  required final PendingWorkspaceInviteSummary invite,
  required final CloudAccountSession account,
  required final _WorkspaceSetupContentState setupState,
  required final bool accept,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () =>
        setupState._respondFromAccount(account, invite, accept: accept),
    child: TextLocale(
      accept
          ? 'workspace_management.cloud_accept'
          : 'workspace_management.cloud_decline',
    ),
    variant: accept ? .primary : .outlined,
  );
}

class const _WorkspaceDiscoveryCloudList({
  required final CloudAccountSession account,
  required final List<CloudAccountSession> accounts,
  required final List<CloudWorkspaceSummary> workspaces,
  required final _WorkspaceSetupContentState setupState,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      CloudWorkspaceConnectList(
        account: account,
        accounts: accounts,
        localWorkspaces:
            ref.watch(allWorkspacesProvider).asData?.value ?? const [],
        workspaces: workspaces,
        onConnect: (workspace) =>
            setupState._connectFromAccount(account, workspace),
        onOpen: setupState._completed,
      );
}
