import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/cloud_account_health_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_creation_draft.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_creation_draft_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/services/cloud_app_exception.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_use_case.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/setup_page_frame.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

final _logger = Logger('create_workspace_form');

/// Form for creating a workspace.
class CreateWorkspaceForm extends ConsumerStatefulWidget {
  /// Creates a workspace form.
  const new({
    required this.onCreated,
    required this.onAddCloudAccount,
    required this.onCreatingChanged,
    required this.onBack,
    required this.onSignInAccount,
    this.canAddCloudAccount = false,
    this.fixedIntent,
    this.onReturn,
    this.pageBuilder,
    this.taskId = '',
    super.key,
  });

  final String taskId;

  /// Keeps the task owner attached while creation is pending.
  final ValueChanged<bool> onCreatingChanged;

  /// Called after workspace creation succeeds.
  final ValueChanged<WorkspaceEntity> onCreated;

  /// Called when a cloud account should be added.
  final VoidCallback onAddCloudAccount;
  final bool canAddCloudAccount;

  /// Keeps a first-run creation form on its selected route.
  final WorkspaceCreationIntent? fixedIntent;

  /// Safe return when this form was opened directly.
  final VoidCallback? onReturn;
  final VoidCallback onBack;
  final SetupPageBuilder? pageBuilder;
  final ValueChanged<CloudAccountSession> onSignInAccount;

  @override
  ConsumerState<CreateWorkspaceForm> createState() =>
      _CreateWorkspaceFormState();
}

class _CreateWorkspaceFormState extends ConsumerState<CreateWorkspaceForm>
    with
        _CreateWorkspaceFormActions,
        _CreateWorkspaceFormDraftActions,
        _CreateWorkspaceSubmissionActions {
  static const _localTarget = '';
  static const _unsavedChangesTitle = TextLocale(
    LocaleKeys.workspace_management_unsaved_changes_title,
  );
  static const _unsavedChangesMessage = TextLocale(
    LocaleKeys.workspace_management_unsaved_changes_message,
  );
  static const _discardChangesActions = AuraConfirmDialogActions(
    confirmLabel: TextLocale(LocaleKeys.workspace_management_discard_changes),
    cancelLabel: TextLocale(LocaleKeys.workspace_management_keep_editing),
  );

  final _name = TextEditingController();
  String _targetAccountId = _localTarget;
  final _exitGuard = DraftExitGuard();
  bool _isCreating = false;
  bool _isDirty = false;
  WorkspaceValidationException? _nameError;
  Exception? _operationError;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
    _name.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _name
      ..removeListener(_onNameChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _bindExitGuard(context);

    final accounts = _watchCreationAccounts(ref, widget.fixedIntent);
    final content = _CreateWorkspaceFields(state: this, accounts: accounts);
    if (widget.pageBuilder != null) return content;

    return DraftExitScope(guard: _exitGuard, child: content);
  }

  void _restoreDraft() {
    if (widget.taskId.isNotEmpty) {
      final taskId = widget.taskId;
      final draft = ref.read(workspaceCreationDraftProvider(taskId));
      _name.text = draft.name;
      _targetAccountId = _draftTarget(widget.fixedIntent, draft.target);
      _isDirty = draft.name.isNotEmpty || draft.target.isNotEmpty;
    }
  }

  void _setTargetAccount(String? accountId) {
    if (_isCreating || accountId == null) return;
    _saveTargetDraft(accountId);
    setState(() {
      _targetAccountId = accountId;
      _operationError = null;
      _isDirty = _name.text.isNotEmpty || accountId != _localTarget;
    });
  }

  Future<void> _create() async {
    if (_isCreating) return;
    final name = _name.text.trim();
    _resetCreationErrors();
    if (!_submittedNameValid(name) || !_canCreateWithAccount()) return;
    setState(() => _isCreating = true);
    widget.onCreatingChanged(true);
    await _runCreate(name);
  }

  void _resetCreationErrors() => setState(() {
    _nameError = null;
    _operationError = null;
  });

  bool _canCreateWithAccount() {
    if (_targetAccountId == _localTarget) return true;
    final accounts = ref.read(cloudAccountsProvider);
    if (accounts.isLoading || accounts.hasError) {
      _setOperationError(
        const AppCloudWorkspaceException(LocaleKeys.cloud_accounts_load_error),
      );

      return false;
    }
    if (_accountForTarget(accounts.asData?.value ?? [], _targetAccountId) ==
        null) {
      _requestCloudAccount();

      return false;
    }

    return true;
  }
}

mixin _CreateWorkspaceFormActions on ConsumerState<CreateWorkspaceForm> {
  _CreateWorkspaceFormState get _state => this as _CreateWorkspaceFormState;

  bool _submittedNameValid(String name) {
    try {
      _validateName(name);

      return true;
    } on WorkspaceValidationException catch (error) {
      setState(() => _state._nameError = error);

      return false;
    }
  }

  void _requestCloudAccount() {
    if (widget.canAddCloudAccount) {
      widget.onAddCloudAccount();
    } else {
      _setOperationError(
        const AppCloudWorkspaceException(
          LocaleKeys.cloud_accounts_origin_unresolved,
        ),
      );
    }
  }

  void _setOperationError(Exception error) {
    if (mounted) setState(() => _state._operationError = error);
  }

  void _handleUnexpectedCreateError(Object error, StackTrace stackTrace) {
    _logger.severe('Create workspace failed', error.runtimeType, stackTrace);
    _setOperationError(
      const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_unexpected_error,
      ),
    );
  }

  void _validateName(String name) {
    ref.read(validateWorkspaceNameUseCaseProvider).call(name: name);
  }

  void _finishCreating() {
    if (!mounted) return;
    setState(() => _state._isCreating = false);
    widget.onCreatingChanged(false);
  }

  void _handleCreatedWorkspace(WorkspaceEntity workspace) {
    ref.invalidate(allWorkspacesProvider);
    if (workspace.cloudAccount case final account?) {
      ref.invalidate(cloudWorkspaceStateProvider(account));
    }
    if (mounted) {
      _state._isDirty = false;
      _state._isCreating = false;
      widget.onCreated(workspace);
    }
  }

  Future<WorkspaceEntity> _createWorkspace(String name) {
    if (_state._targetAccountId == _CreateWorkspaceFormState._localTarget) {
      return _state._createLocalWorkspace(name);
    }

    return _state._createCloudWorkspace(name);
  }
}

mixin _CreateWorkspaceFormDraftActions on ConsumerState<CreateWorkspaceForm> {
  _CreateWorkspaceFormState get _draftState =>
      this as _CreateWorkspaceFormState;

  void _bindExitGuard(BuildContext context) {
    _draftState._exitGuard.bind(
      readers: (
        isDirty: () => _draftState._isDirty,
        isSaving: () => _draftState._isCreating,
      ),
      callbacks: .new(
        confirm: (_) => _confirmDiscard(context),
        onReturn: (_) => widget.onReturn?.call(),
      ),
    );
  }

  Future<bool?> _confirmDiscard(BuildContext context) => AuraDialogs.confirm(
    context: context,
    title: _CreateWorkspaceFormState._unsavedChangesTitle,
    message: _CreateWorkspaceFormState._unsavedChangesMessage,
    actions: _CreateWorkspaceFormState._discardChangesActions,
    isDestructive: true,
  );

  void _onNameChanged() {
    if (!mounted) return;
    final state = _draftState;
    final name = state._name.text;

    _saveNameDraft(name);
    setState(() => _markNameChanged(name));
  }

  void _markNameChanged(String name) {
    final state = _draftState;
    state
      .._nameError = null
      .._isDirty =
          name.isNotEmpty ||
          state._targetAccountId != _CreateWorkspaceFormState._localTarget;
  }

  void _saveNameDraft(String name) {
    if (widget.taskId.isNotEmpty) {
      ref
          .read(workspaceCreationDraftProvider(widget.taskId).notifier)
          .update(name: name);
    }
  }

  void _saveTargetDraft(String accountId) {
    if (widget.taskId.isEmpty) return;
    ref
        .read(workspaceCreationDraftProvider(widget.taskId).notifier)
        .update(target: accountId, intent: accountId.isEmpty ? .local : .cloud);
  }
}

mixin _CreateWorkspaceSubmissionActions on ConsumerState<CreateWorkspaceForm> {
  _CreateWorkspaceFormState get _draftState =>
      this as _CreateWorkspaceFormState;
  Future<void> _runCreate(String name) async {
    try {
      _draftState._handleCreatedWorkspace(
        await _draftState._createWorkspace(name),
      );
    } on Object catch (error, stackTrace) {
      _handleCreationFailure(error, stackTrace);
    } finally {
      _draftState._finishCreating();
    }
  }

  void _handleCreationFailure(Object error, StackTrace stackTrace) {
    switch (error) {
      case WorkspaceValidationException():
        if (mounted) setState(() => _draftState._nameError = error);
      case CloudWorkspaceException():
        _handleCloudWorkspaceError(error);
      case AppCloudWorkspaceException() ||
          CloudAppException() ||
          WorkspaceException():
        _draftState._setOperationError(error as Exception);
      default:
        _draftState._handleUnexpectedCreateError(error, stackTrace);
    }
  }

  void _handleCloudWorkspaceError(CloudWorkspaceException error) {
    _invalidateCloudAccountHealth(error);
    try {
      CloudAppErrors.translateException(error, .workspace);
    } on CloudAppException catch (translated) {
      _draftState._setOperationError(translated);
    }
  }

  void _invalidateCloudAccountHealth(CloudWorkspaceException error) {
    final account = _accountForTarget(
      ref.read(cloudAccountsProvider).asData?.value ?? [],
      _draftState._targetAccountId,
    );
    if (account != null && CheckCloudAccountUsecase.requiresSignIn(error)) {
      ref.invalidate(cloudAccountHealthProvider(account.key));
    }
  }

  Future<WorkspaceEntity> _createLocalWorkspace(String name) =>
      ref.read(createWorkspaceUseCaseProvider).call(name: name);

  Future<WorkspaceEntity> _createCloudWorkspace(String name) async {
    final account = await _targetCloudAccount();
    final useCases = await _requiredCloudWorkspaceUseCases(account.key);

    return await useCases.create(name);
  }

  Future<CloudAccountSession> _targetCloudAccount() async {
    final accounts = await ref.read(cloudAccountsProvider.future);
    final account = _accountForTarget(accounts, _draftState._targetAccountId);
    if (account == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.cloud_accounts_origin_unresolved,
      );
    }

    return account;
  }

  Future<CloudWorkspaceUseCases> _requiredCloudWorkspaceUseCases(
    CloudAccountKey key,
  ) async {
    final useCases = await ref.read(cloudWorkspaceUseCasesProvider(key).future);
    if (useCases == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_unexpected_error,
      );
    }

    return useCases;
  }
}

AsyncValue<List<CloudAccountSession>> _watchCreationAccounts(
  WidgetRef ref,
  WorkspaceCreationIntent? intent,
) => intent == .local ? const AsyncData([]) : ref.watch(cloudAccountsProvider);

CloudAccountSession? _accountForTarget(
  List<CloudAccountSession> accounts,
  String targetAccountId,
) => accounts
    .where(
      (item) =>
          CloudAccountIdentity.accountIdentity(item.serverUrl, item.userId) ==
          targetAccountId,
    )
    .firstOrNull;

String _workspaceError(WorkspaceException error) {
  final key = error.localizationKey;
  if (key == null) return error.message;

  return key.tr(
    namedArgs: {
      'min': '${ValidateWorkspaceNameUseCase.minLength}',
      'max': '${ValidateWorkspaceNameUseCase.maxLength}',
    },
  );
}

class _CreateWorkspaceFields extends StatelessWidget {
  new({
    required _CreateWorkspaceFormState state,
    required AsyncValue<List<CloudAccountSession>> accounts,
  }) : this._(_workspaceCreationView(state, accounts));
  new _(_WorkspaceCreationView data)
    : _child = switch (data.state.widget.pageBuilder) {
        null => AuraColumn(
          children: [
            _WorkspaceCreationInputs(data: data),
            _WorkspaceCreationAction(data: data),
          ],
          spacing: .md,
          crossAxisAlignment: .stretch,
        ),
        final builder => builder(
          .new(
            key: ValueKey((
              task: 'intro_workspace_name',
              intent: data.state.widget.fixedIntent,
            )),
            heading: AuraText(
              child: TextLocale(
                data.cloud
                    ? 'intro_flow.workspace.cloud_title'
                    : 'intro_flow.workspace.local_title',
              ),
              style: .heading4,
            ),
            description: const TextLocale('intro_flow.workspace.body'),
            body: _WorkspaceCreationInputs(data: data),
            actions: _WorkspaceCreationAction(data: data),
            onBack: data.state.widget.onBack,
            backKey: const Key('intro_back_to_route_chooser_button'),
            pending: data.state._isCreating,
          ),
        ),
      };
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}

_WorkspaceCreationView _workspaceCreationView(
  _CreateWorkspaceFormState state,
  AsyncValue<List<CloudAccountSession>> accounts,
) {
  final loaded = accounts.asData?.value ?? const [];
  final account = _accountForTarget(loaded, state._targetAccountId);
  final cloud = state._targetAccountId.isNotEmpty;

  return (
    state: state,
    accounts: accounts,
    loaded: loaded,
    account: account,
    cloud: cloud,
    needsSignIn: cloud && account == null,
  );
}

typedef _WorkspaceCreationView = ({
  _CreateWorkspaceFormState state,
  AsyncValue<List<CloudAccountSession>> accounts,
  List<CloudAccountSession> loaded,
  CloudAccountSession? account,
  bool cloud,
  bool needsSignIn,
});

class _WorkspaceCreationInputs extends StatelessWidget {
  new({required _WorkspaceCreationView data})
    : _child = AuraColumn(
        children: [
          _WorkspaceNameInput(state: data.state),
          const AuraText(
            child: TextLocale('intro_flow.workspace.name_helper'),
            style: .caption,
          ),
          if (data.state.widget.fixedIntent != .local)
            _WorkspaceCloudAccountInputs(data: data),
          if (data.state._operationError case final error?)
            _WorkspaceOperationError(
              error: error,
              onRetry: () => unawaited(data.state._create()),
              pending: data.state._isCreating,
              onSignIn: switch (data.account) {
                final account? => () => data.state.widget.onSignInAccount(
                  account,
                ),
                _ => null,
              },
            ),
        ],
        spacing: .sm,
        crossAxisAlignment: .stretch,
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceNameInput extends StatelessWidget {
  new({required _CreateWorkspaceFormState state})
    : _child = AuraInput(
        key: const Key('intro_workspace_name_field'),
        controller: state._name,
        placeholder: const TextLocale('workspace_management.name_placeholder'),
        label: const TextLocale('workspace_management.name_label'),
        error: switch (state._nameError) {
          null => null,
          final error => Text(_workspaceError(error)),
        },
        state: state._nameError == null ? .normal : .error,
        textInputAction: .done,
        enabled: !state._isCreating,
        onSubmitted: (_) => unawaited(state._create()),
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceCloudAccountInputs extends StatelessWidget {
  new({required _WorkspaceCreationView data})
    : _child = AuraColumn(
        children: [
          _WorkspaceTargetSelector(
            accounts: data.loaded,
            targetAccountId: data.state._targetAccountId,
            fixedIntent: data.state.widget.fixedIntent,
            onChanged: data.state._setTargetAccount,
            isEnabled: !data.state._isCreating,
          ),
          if (data.state.widget.fixedIntent == null || !data.needsSignIn)
            _CloudAccountAction(
              labelKey: LocaleKeys.workspace_setup_add_account,
              onAddCloudAccount: data.state.widget.canAddCloudAccount
                  ? data.state.widget.onAddCloudAccount
                  : null,
              isCreating: data.state._isCreating,
            ),
          if (data.accounts.isLoading || data.accounts.hasError)
            _CreateWorkspaceAccountState(data.accounts),
        ],
        spacing: .sm,
        crossAxisAlignment: .stretch,
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceCreationAction extends StatelessWidget {
  new({required _WorkspaceCreationView data})
    : _child = _CreateWorkspaceButton(
        isCreating: data.state._isCreating,
        canCreate:
            !data.cloud ||
            (!data.accounts.isLoading &&
                !data.accounts.hasError &&
                (!data.needsSignIn || data.state.widget.canAddCloudAccount)),
        onCreate: data.state._create,
        needsSignIn: data.needsSignIn && data.state.widget.canAddCloudAccount,
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceOperationError extends StatelessWidget {
  new({
    required Exception error,
    required VoidCallback onRetry,
    required bool pending,
    VoidCallback? onSignIn,
  }) : _child = Semantics(
         child: AuraCard(
           child: AuraColumn(
             children: [
               TextLocale(_workspaceOperationErrorKey(error)),
               Wrap(
                 spacing: 8,
                 children: [
                   AuraButton(
                     onPressed: onRetry,
                     child: const TextLocale('route_state.retry'),
                     variant: .ghost,
                     disabled: pending,
                   ),
                   if (onSignIn case final callback?)
                     AuraButton(
                       onPressed: callback,
                       child: const TextLocale(
                         'workspace_management.cloud_login',
                       ),
                       variant: .ghost,
                       disabled: pending,
                     ),
                 ],
               ),
             ],
             spacing: .sm,
           ),
           key: const Key('workspace_operation_error'),
           style: .border,
           tint: .error,
         ),
         liveRegion: true,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceTargetSelector extends StatelessWidget {
  new({
    required List<CloudAccountSession> accounts,
    required String targetAccountId,
    required WorkspaceCreationIntent? fixedIntent,
    required ValueChanged<String?> onChanged,
    required bool isEnabled,
  }) : _child = fixedIntent == .cloud && accounts.isEmpty
           ? const SizedBox.shrink()
           : AuraDropdownSelector<String>(
               options: [
                 if (fixedIntent != .cloud)
                   const AuraDropdownOption(
                     value: _CreateWorkspaceFormState._localTarget,
                     child: TextLocale('workspace_management.local_target'),
                   ),
                 for (final account in accounts)
                   AuraDropdownOption(
                     value: CloudAccountIdentity.accountIdentity(
                       account.serverUrl,
                       account.userId,
                     ),
                     child: Text('${account.email} (${account.key.serverUrl})'),
                   ),
               ],
               value: switch (targetAccountId) {
                 '' when fixedIntent != .cloud => '',
                 final target
                     when accounts.any(
                       (account) =>
                           CloudAccountIdentity.accountIdentity(
                             account.serverUrl,
                             account.userId,
                           ) ==
                           target,
                     ) =>
                   target,
                 _ => null,
               },
               onChanged: onChanged,
               label: const TextLocale('workspace_management.target_label'),
               isEnabled: isEnabled,
             );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _CloudAccountAction extends StatelessWidget {
  const new({
    required this.labelKey,
    required this.onAddCloudAccount,
    required this.isCreating,
  });

  final String labelKey;
  final VoidCallback? onAddCloudAccount;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    if (onAddCloudAccount case final onAdd?) {
      return AuraButton(
        onPressed: onAdd,
        child: TextLocale(labelKey),
        variant: .outlined,
        disabled: isCreating,
      );
    }

    return const TextLocale('workspace_management.cloud_add_hint');
  }
}

class _CreateWorkspaceButton extends StatelessWidget {
  const new({
    required this.isCreating,
    required this.canCreate,
    required this.onCreate,
    required this.needsSignIn,
  });

  final bool isCreating;
  final bool canCreate;
  final bool needsSignIn;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(onCreate()),
    child: TextLocale(
      needsSignIn
          ? 'workspace_setup.sign_in_continue'
          : LocaleKeys.workspace_management_create_button,
    ),
    key: needsSignIn
        ? const Key('intro_sign_in_to_continue_button')
        : const Key('intro_create_workspace_button'),
    isLoading: isCreating,
    disabled: isCreating || !canCreate,
  );
}

class _CreateWorkspaceAccountState extends ConsumerWidget {
  const new(this.accounts);

  final AsyncValue<List<CloudAccountSession>> accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (accounts) {
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncError() => AuraColumn(
      children: [
        const TextLocale(LocaleKeys.cloud_accounts_load_error),
        AuraButton(
          onPressed: () => ref.invalidate(cloudAccountsProvider),
          child: const TextLocale('route_state.retry'),
          key: const Key('workspace_accounts_retry_button'),
          variant: .outlined,
        ),
      ],
    ),
    AsyncData() => const SizedBox.shrink(),
  };
}

String _workspaceOperationErrorKey(Exception error) => switch (error) {
  AppCloudWorkspaceException(:final localizationKey) => localizationKey,
  CloudAppException(:final localizationKey) => localizationKey,
  WorkspaceException(:final localizationKey) =>
    localizationKey ?? LocaleKeys.workspace_management_unexpected_error,
  _ => LocaleKeys.workspace_management_unexpected_error,
};

String _draftTarget(WorkspaceCreationIntent? intent, String target) =>
    switch (intent) {
      .local => '',
      .cloud => target.isEmpty ? '__cloud__' : target,
      _ => target,
    };
