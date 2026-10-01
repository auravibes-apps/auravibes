import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/serverpod_auth_store.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/notifiers/workspace_creation_draft_notifier.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_use_case.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/router/draft_exit_guard.dart';
import 'package:auravibes_app/widgets/draft_exit_scope.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
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
    this.canAddCloudAccount = false,
    this.onReturn,
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

  /// Safe return when this form was opened directly.
  final VoidCallback? onReturn;

  @override
  ConsumerState<CreateWorkspaceForm> createState() =>
      _CreateWorkspaceFormState();
}

class _CreateWorkspaceFormState extends ConsumerState<CreateWorkspaceForm>
    with _CreateWorkspaceFormActions, _CreateWorkspaceFormDraftActions {
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
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.taskId.isNotEmpty) {
      final taskId = widget.taskId;
      final draft = ref.read(workspaceCreationDraftProvider(taskId));
      _name.text = draft.name;
      _targetAccountId = draft.target;
      _isDirty = draft.name.isNotEmpty || draft.target.isNotEmpty;
    }
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

    return _CreateWorkspaceFormView(
      guard: _exitGuard,
      accounts: ref.watch(cloudAccountsProvider),
      name: _name,
      targetAccountId: _targetAccountId,
      errorText: _errorText,
      isCreating: _isCreating,
      onTargetAccountChanged: _setTargetAccount,
      onAddCloudAccount: widget.canAddCloudAccount
          ? widget.onAddCloudAccount
          : null,
      onCreate: _create,
    );
  }

  void _updateDirty(bool isDirty) {
    if (_isDirty == isDirty) return;

    setState(() => _isDirty = isDirty);
  }

  void _setTargetAccount(String? accountId) {
    if (_isCreating || accountId == null) return;
    _saveTargetDraft(accountId);
    setState(() {
      _targetAccountId = accountId;
      _isDirty = _name.text.isNotEmpty || accountId != _localTarget;
    });
  }

  Future<void> _create() async {
    if (_isCreating) return;

    final name = _name.text.trim();
    setState(() {
      _isCreating = true;
      _errorText = null;
    });
    widget.onCreatingChanged(true);
    await _runCreate(name);
  }
}

class _CreateWorkspaceFormView extends StatelessWidget {
  const new({
    required this.guard,
    required this.accounts,
    required this.name,
    required this.targetAccountId,
    required this.errorText,
    required this.isCreating,
    required this.onTargetAccountChanged,
    required this.onAddCloudAccount,
    required this.onCreate,
  });

  final DraftExitGuard guard;
  final AsyncValue<List<CloudAccountSession>> accounts;
  final TextEditingController name;
  final String targetAccountId;
  final String? errorText;
  final bool isCreating;
  final ValueChanged<String?> onTargetAccountChanged;
  final VoidCallback? onAddCloudAccount;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) => DraftExitScope(
    guard: guard,
    child: _CreateWorkspaceAccountView(
      accounts: accounts,
      name: name,
      targetAccountId: targetAccountId,
      errorText: errorText,
      isCreating: isCreating,
      onTargetAccountChanged: onTargetAccountChanged,
      onAddCloudAccount: onAddCloudAccount,
      onCreate: onCreate,
    ),
  );
}

mixin _CreateWorkspaceFormActions on ConsumerState<CreateWorkspaceForm> {
  _CreateWorkspaceFormState get _state => this as _CreateWorkspaceFormState;

  void _setError(String errorText) {
    if (mounted) setState(() => _state._errorText = errorText);
  }

  void _handleUnexpectedCreateError(Object error, StackTrace stackTrace) {
    _logger.severe('Create workspace failed', error.runtimeType, stackTrace);
    _setError(LocaleKeys.workspace_management_unexpected_error.tr());
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

  Future<WorkspaceEntity> _validateAndCreateWorkspace(String name) {
    _validateName(name);

    return _createWorkspace(name);
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
      onReturn: (_) => widget.onReturn?.call(),
      confirm: (_) => _confirmDiscard(context),
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

    if (widget.taskId.isNotEmpty) {
      ref
          .read(workspaceCreationDraftProvider(widget.taskId).notifier)
          .update(name: name);
    }
    state._updateDirty(
      name.isNotEmpty ||
          state._targetAccountId != _CreateWorkspaceFormState._localTarget,
    );
  }

  void _saveTargetDraft(String accountId) {
    if (widget.taskId.isEmpty) return;
    ref
        .read(workspaceCreationDraftProvider(widget.taskId).notifier)
        .update(target: accountId, intent: accountId.isEmpty ? .local : .cloud);
  }

  Future<void> _runCreate(String name) async {
    try {
      _draftState._handleCreatedWorkspace(
        await _draftState._validateAndCreateWorkspace(name),
      );
    } on AppCloudWorkspaceException catch (error) {
      _draftState._setError(error.localizationKey.tr());
    } on WorkspaceException catch (error) {
      _draftState._setError(_workspaceError(error));
    } on Object catch (error, stackTrace) {
      _draftState._handleUnexpectedCreateError(error, stackTrace);
    } finally {
      _draftState._finishCreating();
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

class _CreateWorkspaceAccountView extends StatelessWidget {
  new({
    required AsyncValue<List<CloudAccountSession>> accounts,
    required TextEditingController name,
    required String targetAccountId,
    required String? errorText,
    required bool isCreating,
    required ValueChanged<String?> onTargetAccountChanged,
    required VoidCallback? onAddCloudAccount,
    required Future<void> Function() onCreate,
  }) : _child = switch (accounts) {
         AsyncData(:final value) => _CreateWorkspaceLoaded(
           accounts: value,
           name: name,
           targetAccountId: targetAccountId,
           errorText: errorText,
           isCreating: isCreating,
           onTargetAccountChanged: onTargetAccountChanged,
           onAddCloudAccount: onAddCloudAccount,
           onCreate: onCreate,
         ),
         final accounts => _CreateWorkspaceAccountState(accounts),
       };

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _CreateWorkspaceLoaded extends StatelessWidget {
  new({
    required List<CloudAccountSession> accounts,
    required TextEditingController name,
    required String targetAccountId,
    required String? errorText,
    required bool isCreating,
    required ValueChanged<String?> onTargetAccountChanged,
    required VoidCallback? onAddCloudAccount,
    required Future<void> Function() onCreate,
  }) : _child = AuraColumn(
         children: [
           _WorkspaceNameField(
             name: name,
             errorText: errorText,
             isCreating: isCreating,
             onCreate: onCreate,
           ),
           _WorkspaceTargetSelector(
             accounts: accounts,
             targetAccountId: targetAccountId,
             onChanged: onTargetAccountChanged,
             isEnabled: !isCreating,
           ),
           _CloudAccountAction(
             onAddCloudAccount: onAddCloudAccount,
             isCreating: isCreating,
           ),
           _CreateWorkspaceButton(isCreating: isCreating, onCreate: onCreate),
         ],
         spacing: .md,
         crossAxisAlignment: .stretch,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceNameField extends StatelessWidget {
  new({
    required TextEditingController name,
    required String? errorText,
    required bool isCreating,
    required Future<void> Function() onCreate,
  }) : _child = AuraInput(
         controller: name,
         placeholder: Text(
           LocaleKeys.workspace_management_name_placeholder.tr(),
         ),
         label: Text(LocaleKeys.workspace_management_name_label.tr()),
         error: errorText == null ? null : Text(errorText),
         state: errorText == null ? .normal : .error,
         textInputAction: .done,
         enabled: !isCreating,
         onSubmitted: (_) => unawaited(onCreate()),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _WorkspaceTargetSelector extends StatelessWidget {
  new({
    required List<CloudAccountSession> accounts,
    required String targetAccountId,
    required ValueChanged<String?> onChanged,
    required bool isEnabled,
  }) : _child = AuraDropdownSelector<String>(
         options: [
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
         value:
             accounts.any(
                   (account) =>
                       CloudAccountIdentity.accountIdentity(
                         account.serverUrl,
                         account.userId,
                       ) ==
                       targetAccountId,
                 ) ||
                 targetAccountId.isEmpty
             ? targetAccountId
             : null,
         onChanged: onChanged,
         label: const TextLocale('workspace_management.target_label'),
         isEnabled: isEnabled,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _CloudAccountAction extends StatelessWidget {
  const new({required this.onAddCloudAccount, required this.isCreating});

  final VoidCallback? onAddCloudAccount;
  final bool isCreating;

  @override
  Widget build(BuildContext context) {
    if (onAddCloudAccount case final onAdd?) {
      return AuraButton(
        onPressed: onAdd,
        child: const TextLocale('workspace_setup.add_account'),
        variant: .outlined,
        disabled: isCreating,
      );
    }

    return const TextLocale('workspace_management.cloud_add_hint');
  }
}

class _CreateWorkspaceButton extends StatelessWidget {
  const new({required this.isCreating, required this.onCreate});

  final bool isCreating;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: () => unawaited(onCreate()),
    child: const TextLocale(LocaleKeys.workspace_management_create_button),
    key: const Key('intro_create_workspace_button'),
    isLoading: isCreating,
    disabled: isCreating,
  );
}

class _CreateWorkspaceAccountState extends StatelessWidget {
  const new(this.accounts);

  final AsyncValue<List<CloudAccountSession>> accounts;

  @override
  Widget build(BuildContext context) => switch (accounts) {
    AsyncLoading() => const Center(child: AuraSpinner()),
    AsyncError() => const Center(
      child: TextLocale(LocaleKeys.cloud_accounts_load_error),
    ),
    AsyncData() => const SizedBox.shrink(),
  };
}
