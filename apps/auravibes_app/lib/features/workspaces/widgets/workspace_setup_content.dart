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
import 'package:auravibes_app/features/workspaces/models/workspace_setup_result.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_creation_draft_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/screens/create_workspace_form.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/setup_page_frame.dart';
import 'package:auravibes_app/widgets/setup_page_transition.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// A task-owned draft and callback auth flow that also works before first use.
class const WorkspaceSetupContent({
  required final String taskId,
  required final ValueChanged<WorkspaceSetupResult> onCompleted,
  final VoidCallback? onReturn,
  final bool showIntroRouteChooser = false,
  final SetupPageBuilder? pageBuilder,
  final ValueChanged<WorkspaceSetupStage>? onStageChanged,
  final ValueChanged<bool>? onPendingChanged,
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
  bool _introRouteSelected = false;
  bool _showConnectExisting = false;
  bool _busy = false;
  bool _creating = false;
  bool _authPending = false;
  bool _reverse = false;

  bool _completedTask = false;
  AppCloudWorkspaceException? _error;

  bool get _pending => _busy || _creating || _authPending;

  WorkspaceSetupStage get _stage {
    if (_auth != null) return .authentication;
    if (widget.showIntroRouteChooser && !_introRouteSelected) return .chooser;
    if (_showConnectExisting) return .discovery;

    return switch (ref
        .read(workspaceCreationDraftProvider(widget.taskId))
        .intent) {
      .local => .local,
      .cloud => .cloud,
      .connect => .discovery,
    };
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(workspaceCreationDraftProvider(widget.taskId));
    _bindExitGuard(draft);

    return _WorkspaceSetupView(state: this, draft: draft);
  }

  void _refresh(VoidCallback update) => setState(update);

  void _notifyStage() => widget.onStageChanged?.call(_stage);

  void _notifyPending() => widget.onPendingChanged?.call(_pending);

  void _addAccount() {
    if (_pending) return;
    _promoteCloudIntent();
    setState(() {
      _reverse = false;
      _auth = const CloudAuthTarget();
    });
    _notifyStage();
  }

  void _signedIn(CloudAccountSession account) {
    if (!_showConnectExisting) {
      ref
          .read(workspaceCreationDraftProvider(widget.taskId).notifier)
          .update(
            target: CloudAccountIdentity.accountIdentity(
              account.serverUrl,
              account.userId,
            ),
          );
    }
    setState(() {
      _auth = null;
      _authPending = false;
      _reverse = false;
    });
    _notifyPending();
    _notifyStage();
  }

  void _signInAccount(CloudAccountSession account) {
    if (_pending) return;
    setState(() {
      _reverse = false;
      _auth = .new(
        serverUrl: account.key.serverUrl,
        accountId: account.userId,
        email: account.email,
      );
    });
    _notifyStage();
  }
}

extension _WorkspaceSetupOperationActions on _WorkspaceSetupContentState {
  void _setCloudActionError(String error) {
    if (mounted) _refresh(() => _error = .new(error));
  }

  void _setCreating(bool creating) {
    if (!mounted) return;
    _refresh(() => _creating = creating);
    _notifyPending();
  }

  void _setAuthPending(bool pending) {
    if (!mounted) return;
    _refresh(() => _authPending = pending);
    _notifyPending();
  }

  Future<void> _respondToInvite(
    CloudAccountSession account,
    PendingWorkspaceInviteSummary invite, {
    required bool accept,
  }) async {
    if (_pending) return;
    _refresh(() {
      _busy = true;
      _error = null;
    });
    _notifyPending();
    try {
      await _performInviteResponse(account, invite, accept: accept);
    } on Object catch (error) {
      _handleInviteFailure(account, error);
    } finally {
      if (mounted) {
        _refresh(() => _busy = false);
        _notifyPending();
      }
    }
  }

  Future<void> _connect(
    CloudAccountSession account,
    CloudWorkspaceSummary workspace,
  ) async {
    if (_pending) return;
    _refresh(() {
      _busy = true;
      _error = null;
    });
    _notifyPending();
    try {
      await _performWorkspaceConnection(account, workspace);
    } on AppCloudWorkspaceException catch (error) {
      _setCloudActionError(error.localizationKey);
    } on Object {
      _setCloudActionError('workspace_management.cloud_load_error');
    } finally {
      if (mounted) {
        _refresh(() => _busy = false);
        _notifyPending();
      }
    }
  }
}

extension _WorkspaceSetupNavigation on _WorkspaceSetupContentState {
  void _returnWithinTask() {
    if (_pending) return;
    if (_auth != null) {
      _cancelAuth();
    } else if (_introRouteSelected) {
      _backToIntroRouteChooser();
    } else {
      widget.onReturn?.call();
    }
  }

  void _cancelAuth() {
    if (_pending) return;
    _refresh(() {
      _auth = null;
      _reverse = true;
    });
    _notifyStage();
  }

  void _openConnectExisting() {
    if (_pending) return;
    _refresh(() {
      _introRouteSelected = true;
      _showConnectExisting = true;
      _error = null;
      _reverse = false;
    });
    _notifyStage();
  }

  void _backToCreation() {
    if (_pending) return;
    if (widget.showIntroRouteChooser) {
      _backToIntroRouteChooser();

      return;
    }
    _refresh(() => _showConnectExisting = false);
    _notifyStage();
  }

  void _chooseIntroRoute(WorkspaceCreationIntent intent) {
    if (_pending) return;
    final draft = ref.read(workspaceCreationDraftProvider(widget.taskId));
    final accounts = _availableCloudAccounts();
    _saveIntent(intent, _introRouteTarget(intent, draft, accounts));
    _refresh(() {
      _introRouteSelected = true;
      _showConnectExisting = false;
      _error = null;
      _reverse = false;
    });
    _notifyStage();
  }

  void _backToIntroRouteChooser() {
    if (_pending) return;
    _refresh(() {
      _introRouteSelected = false;
      _showConnectExisting = false;
      _error = null;
      _reverse = true;
    });
    _notifyStage();
  }
}

extension _WorkspaceSetupDraftActions on _WorkspaceSetupContentState {
  void _bindExitGuard(WorkspaceCreationDraft draft) {
    _exitGuard.bind(
      readers: (
        isDirty: () => !_completedTask && _draftHasChanges(draft),
        isSaving: _isSaving,
      ),
      callbacks: .new(onReturn: (_) => widget.onReturn?.call()),
    );
  }

  bool _draftHasChanges(WorkspaceCreationDraft draft) =>
      draft.name.isNotEmpty || draft.target.isNotEmpty;

  bool _isSaving() => _pending && !_completedTask;
}

extension _WorkspaceSetupDraftSelection on _WorkspaceSetupContentState {
  void _promoteCloudIntent() {
    final draft = ref.read(workspaceCreationDraftProvider(widget.taskId));
    if (!_showConnectExisting && draft.intent == .local) {
      _saveIntent(.cloud, '__cloud__');
    }
  }

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
    if (draft.cloudTarget.isNotEmpty) return draft.cloudTarget;
    final account = accounts.firstOrNull;
    if (account == null) return '__cloud__';

    return CloudAccountIdentity.accountIdentity(
      account.serverUrl,
      account.userId,
    );
  }

  String _introRouteTarget(
    WorkspaceCreationIntent intent,
    WorkspaceCreationDraft draft,
    List<CloudAccountSession> accounts,
  ) {
    if (intent == .local) return '';
    final currentAccount = accounts
        .where((account) => _cloudAccountTarget(account) == draft.cloudTarget)
        .firstOrNull;
    final account = currentAccount ?? accounts.firstOrNull;
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

  void _completed(
    WorkspaceEntity workspace, {
    WorkspaceSetupOutcome outcome = .created,
  }) {
    _completedTask = true;
    ref.invalidate(workspaceCreationDraftProvider(widget.taskId));
    widget.onCompleted(.new(workspace: workspace, outcome: outcome));
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
      if (mounted) _completed(workspace, outcome: .joined);
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
    if (mounted) _completed(connected, outcome: .connected);
  }
}

class const _WorkspaceSetupView({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationDraft draft,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final content = _WorkspaceSetupCurrentPage(state: state, draft: draft);
    if (state.widget.pageBuilder == null) return content;

    return DraftExitScope(
      guard: state._exitGuard,
      child: SetupPageTransition(
        child: KeyedSubtree(key: ValueKey(state._stage), child: content),
        reverse: state._reverse,
      ),
      onBack: state._returnWithinTask,
    );
  }
}

class const _WorkspaceSetupCurrentPage({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationDraft draft,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (state._auth) {
      final target? => _WorkspaceSetupAuthFlow(
        state: state,
        draft: draft,
        target: target,
      ),
      null => _WorkspaceSetupPage(
        state: state,
        draft: draft,
        accounts: _watchSetupAccounts(ref, state, draft),
      ),
    };
  }
}

class _WorkspaceSetupPage extends StatelessWidget {
  new({
    required _WorkspaceSetupContentState state,
    required WorkspaceCreationDraft draft,
    required AsyncValue<List<CloudAccountSession>> accounts,
  }) : this._(
         state,
         state.widget.showIntroRouteChooser && !state._introRouteSelected
             ? _WorkspaceIntroRouteChooser(state: state)
             : _WorkspaceSetupBody(
                 state: state,
                 draft: draft,
                 accounts: accounts,
               ),
         state.widget.pageBuilder == null &&
             ((state.widget.showIntroRouteChooser &&
                     !state._introRouteSelected) ||
                 (!state.widget.showIntroRouteChooser
                     ? draft.intent == .connect
                     : state._showConnectExisting)),
       );
  new _(_WorkspaceSetupContentState state, Widget content, bool guarded)
    : _child = guarded
          ? DraftExitScope(guard: state._exitGuard, child: content)
          : content;
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}

class const _WorkspaceSetupBody({
  required final _WorkspaceSetupContentState state,
  required final WorkspaceCreationDraft draft,
  required final AsyncValue<List<CloudAccountSession>> accounts,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (state.widget.pageBuilder case final builder?) {
      if (!state._showConnectExisting) {
        return _WorkspaceCreateOrConnect(
          state: state,
          draft: draft,
          accounts: accounts,
        );
      }

      return _WorkspaceDiscoveryPage(
        state: state,
        accounts: accounts,
        builder: builder,
      );
    }

    return _WorkspaceSetupLegacyBody(
      state: state,
      draft: draft,
      accounts: accounts,
    );
  }
}

class _WorkspaceDiscoveryPage extends StatelessWidget {
  new({
    required _WorkspaceSetupContentState state,
    required AsyncValue<List<CloudAccountSession>> accounts,
    required SetupPageBuilder builder,
  }) : _child = builder(
         .new(
           key: const Key('intro_workspace_discovery'),
           heading: const AuraText(
             child: TextLocale('intro_flow.choice.cloud_connect_title'),
             style: .heading4,
           ),
           description: const TextLocale(
             'intro_flow.choice.cloud_connect_body',
           ),
           body: AuraColumn(
             children: [
               _WorkspaceConnectAccounts(
                 state: state,
                 accounts: accounts,
                 onBack: null,
               ),
               if (state._busy) const Center(child: AuraSpinner()),
               if (state._error case final error?)
                 TextLocale(error.localizationKey),
             ],
             spacing: .md,
           ),
           onBack: state._backToIntroRouteChooser,
           backKey: const Key('workspace_setup_back_to_creation_button'),
           pending: state._pending,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceSetupLegacyBody extends StatelessWidget {
  new({
    required _WorkspaceSetupContentState state,
    required WorkspaceCreationDraft draft,
    required AsyncValue<List<CloudAccountSession>> accounts,
  }) : _child = AuraColumn(
         children: [
           if (!state.widget.showIntroRouteChooser)
             _WorkspaceSetupChoices(state: state, draft: draft),
           if ((state.widget.showIntroRouteChooser) &&
               state._introRouteSelected &&
               !state._showConnectExisting)
             AuraButton(
               onPressed: state._backToIntroRouteChooser,
               child: const TextLocale(LocaleKeys.intro_flow_back),
               key: const Key('intro_back_to_route_chooser_button'),
               variant: .outlined,
               disabled: state._pending,
             ),
           if ((state.widget.showIntroRouteChooser) &&
               state._introRouteSelected &&
               !state._showConnectExisting)
             _WorkspaceIntroRouteDetails(intent: draft.intent),
           _WorkspaceAccountStatus(state: state, accounts: accounts),
           _WorkspaceCreateOrConnect(
             state: state,
             draft: draft,
             accounts: accounts,
           ),
           if ((state.widget.showIntroRouteChooser) &&
               state._introRouteSelected &&
               !state._showConnectExisting)
             AuraButton(
               onPressed: state._openConnectExisting,
               child: const TextLocale(
                 LocaleKeys.intro_flow_choice_cloud_connect_title,
               ),
               key: const Key('intro_connect_existing_button'),
               variant: .outlined,
               disabled: state._pending,
             ),
           if (state._busy) const Center(child: AuraSpinner()),
           if (state._error case final error?)
             TextLocale(error.localizationKey),
         ],
         spacing: .md,
         crossAxisAlignment: .stretch,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _WorkspaceIntroRouteChooser({
  required final _WorkspaceSetupContentState state,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final choices = _WorkspaceIntroChoices(state: state);
    final builder = state.widget.pageBuilder;
    if (builder == null) return choices;

    return builder(
      .new(
        key: const Key('intro_workspace_chooser'),
        heading: const AuraText(
          child: TextLocale('intro_flow.choice.title'),
          style: .heading4,
        ),
        description: const AuraText(
          child: TextLocale('intro_flow.choice.select_hint'),
          style: .caption,
        ),
        body: choices,
      ),
    );
  }
}

class _WorkspaceIntroChoices extends StatelessWidget {
  new({required _WorkspaceSetupContentState state})
    : _child = AuraColumn(
        children: [
          _WorkspaceIntroRouteOption(
            titleKey: LocaleKeys.workspace_setup_local,
            bodyKey: LocaleKeys.intro_flow_choice_local_body,
            buttonKey: const Key('intro_route_local_button'),
            onPressed: () => state._chooseIntroRoute(.local),
            isPending: state._pending,
          ),
          _WorkspaceIntroRouteOption(
            titleKey: LocaleKeys.workspace_setup_cloud,
            bodyKey: LocaleKeys.intro_flow_choice_cloud_create_body,
            buttonKey: const Key('intro_route_cloud_button'),
            onPressed: () => state._chooseIntroRoute(.cloud),
            isPending: state._pending,
          ),
          AuraButton(
            onPressed: state._openConnectExisting,
            child: const TextLocale('intro_flow.choice.cloud_connect_title'),
            key: const Key('intro_connect_existing_button'),
            variant: .ghost,
            disabled: state._pending,
          ),
          if (state._error case final error?) TextLocale(error.localizationKey),
        ],
        spacing: .md,
        crossAxisAlignment: .stretch,
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _WorkspaceIntroRouteOption({
  required final String titleKey,
  required final String bodyKey,
  required final Key buttonKey,
  required final VoidCallback onPressed,
  required final bool isPending,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      AuraButton(
        onPressed: onPressed,
        child: TextLocale(titleKey),
        key: buttonKey,
        variant: .outlined,
        disabled: isPending,
      ),
      TextLocale(bodyKey),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
  );
}

class const _WorkspaceIntroRouteDetails({
  required final WorkspaceCreationIntent intent,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => switch (intent) {
    .local => const AuraColumn(
      children: [
        TextLocale(LocaleKeys.intro_flow_choice_local_title),
        TextLocale(LocaleKeys.intro_flow_choice_local_body),
      ],
      spacing: .sm,
    ),
    .cloud => const AuraColumn(
      children: [
        TextLocale(LocaleKeys.intro_flow_choice_cloud_create_title),
        TextLocale(LocaleKeys.intro_flow_choice_cloud_create_body),
      ],
      spacing: .sm,
    ),
    .connect => const SizedBox.shrink(),
  };
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
    child: TextLocale(switch (intent) {
      .local => LocaleKeys.workspace_setup_local,
      .cloud => LocaleKeys.workspace_setup_cloud,
      .connect => LocaleKeys.workspace_setup_connect,
    }),
    key: ValueKey('workspace_intent_${intent.name}'),
    variant: isSelected ? .primary : .outlined,
    disabled: isPending,
  );
}

class _WorkspaceSetupAuthFlow extends StatelessWidget {
  new({
    required _WorkspaceSetupContentState state,
    required WorkspaceCreationDraft draft,
    required CloudAuthTarget target,
  }) : this._(
         state,
         CloudAccountAuthContent(
           onSignedIn: state._signedIn,
           onCancel: state._cancelAuth,
           target: target,
           returnTaskLabel: state._showConnectExisting
               ? 'workspace_setup.connect'.tr()
               : 'workspace_setup.${draft.intent.name}'.tr(),
           pageBuilder: state.widget.pageBuilder,
           onPendingChanged: state._setAuthPending,
         ),
       );
  new _(_WorkspaceSetupContentState state, Widget content)
    : _child = state.widget.pageBuilder != null
          ? content
          : DraftExitScope(guard: state._exitGuard, child: content);
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
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

class _WorkspaceCreateOrConnect extends StatelessWidget {
  new({
    required _WorkspaceSetupContentState state,
    required WorkspaceCreationDraft draft,
    required AsyncValue<List<CloudAccountSession>> accounts,
  }) : _child = switch (state.widget.showIntroRouteChooser
           ? state._showConnectExisting
           : draft.intent == .connect) {
         true => _WorkspaceConnectAccounts(
           state: state,
           accounts: accounts,
           onBack: state._showConnectExisting && !state._pending
               ? state._backToCreation
               : null,
         ),
         false => _WorkspaceCreationForm(state: state, draft: draft),
       };
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceCreationForm extends StatelessWidget {
  new({
    required _WorkspaceSetupContentState state,
    required WorkspaceCreationDraft draft,
  }) : _child = CreateWorkspaceForm(
         onCreated: state._completed,
         onAddCloudAccount: state._addAccount,
         onCreatingChanged: state._setCreating,
         onBack: state._backToIntroRouteChooser,
         onSignInAccount: state._signInAccount,
         canAddCloudAccount:
             !state.widget.showIntroRouteChooser || draft.intent == .cloud,
         fixedIntent: state.widget.showIntroRouteChooser ? draft.intent : null,
         onReturn: state.widget.onReturn,
         pageBuilder: state.widget.pageBuilder,
         taskId: state.widget.taskId,
         key: ValueKey(
           state.widget.showIntroRouteChooser
               ? (intent: draft.intent, target: draft.target)
               : draft.intent,
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceConnectAccounts extends StatelessWidget {
  new({
    required _WorkspaceSetupContentState state,
    required AsyncValue<List<CloudAccountSession>> accounts,
    required VoidCallback? onBack,
  }) : _child = AuraColumn(
         children: [
           if (onBack case final callback?)
             AuraButton(
               onPressed: callback,
               child: const TextLocale(
                 LocaleKeys.workspace_setup_back_to_creation,
               ),
               key: const Key('workspace_setup_back_to_creation_button'),
               variant: .outlined,
             ),
           _WorkspaceAddAccountButton(
             onPressed: state._addAccount,
             labelKey:
                 state.widget.showIntroRouteChooser &&
                     !(accounts.asData?.value.isNotEmpty ?? false)
                 ? LocaleKeys.cloud_accounts_add
                 : LocaleKeys.workspace_setup_add_account,
           ),
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

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _WorkspaceAddAccountButton({
  required final VoidCallback onPressed,
  required final String labelKey,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      AuraButton(onPressed: onPressed, child: TextLocale(labelKey));
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

class _WorkspaceDiscoveryData extends StatelessWidget {
  new({
    required CloudAccountSession account,
    required List<CloudAccountSession> accounts,
    required CloudWorkspaceViewState value,
    required _WorkspaceSetupContentState setupState,
  }) : _child = AuraColumn(
         children: [
           _WorkspaceDiscoveryInvites(
             account: account,
             invites: value.pendingInvites,
             setupState: setupState,
           ),
           if (value.workspaces.isEmpty) ...[
             const TextLocale('cloud_accounts.no_workspaces'),
             if (setupState.widget.showIntroRouteChooser)
               AuraButton(
                 onPressed: () => setupState._chooseIntroRoute(.cloud),
                 child: const TextLocale(
                   'intro_flow.choice.cloud_create_title',
                 ),
                 disabled: setupState._pending,
               ),
           ],
           _WorkspaceDiscoveryCloudList(
             account: account,
             accounts: accounts,
             workspaces: value.workspaces,
             setupState: setupState,
           ),
         ],
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
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
    disabled: setupState._pending,
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
      _WorkspaceDiscoveryConnectList(
        view: this,
        localWorkspaces:
            ref.watch(allWorkspacesProvider).asData?.value ?? const [],
      );
}

String _cloudAccountTarget(CloudAccountSession account) =>
    CloudAccountIdentity.accountIdentity(account.serverUrl, account.userId);

AsyncValue<List<CloudAccountSession>> _watchSetupAccounts(
  WidgetRef ref,
  _WorkspaceSetupContentState state,
  WorkspaceCreationDraft draft,
) => draft.intent == .local && !state._showConnectExisting
    ? const AsyncData([])
    : ref.watch(cloudAccountsProvider);

class _WorkspaceDiscoveryConnectList extends StatelessWidget {
  new({
    required _WorkspaceDiscoveryCloudList view,
    required List<WorkspaceEntity> localWorkspaces,
  }) : _child = CloudWorkspaceConnectList(
         account: view.account,
         accounts: view.accounts,
         localWorkspaces: localWorkspaces,
         workspaces: view.workspaces,
         onConnect: (workspace) =>
             view.setupState._connectFromAccount(view.account, workspace),
         onOpen: (workspace) =>
             view.setupState._completed(workspace, outcome: .connected),
         pending: view.setupState._pending,
       );
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}
