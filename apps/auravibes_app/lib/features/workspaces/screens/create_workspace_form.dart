import 'dart:async';

import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/cloud_accounts/data/cloud_account_session.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_workspaces/providers/cloud_workspace_providers.dart';
import 'package:auravibes_app/features/cloud_workspaces/usecases/cloud_workspace_usecases.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_repository_providers.dart';
import 'package:auravibes_app/features/workspaces/usecases/create_workspace_use_case.dart';
import 'package:auravibes_app/features/workspaces/usecases/validate_workspace_name_use_case.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';

final _logger = Logger('create_workspace_form');

/// Form for creating a workspace.
class CreateWorkspaceForm extends ConsumerStatefulWidget {
  /// Creates a workspace form.
  const new({required this.onCreated, this.onAddCloudAccount, super.key});

  /// Called after workspace creation succeeds.
  final ValueChanged<WorkspaceEntity> onCreated;

  /// Called when a cloud account should be added.
  final VoidCallback? onAddCloudAccount;

  @override
  ConsumerState<CreateWorkspaceForm> createState() =>
      _CreateWorkspaceFormState();
}

class _CreateWorkspaceFormState extends ConsumerState<CreateWorkspaceForm>
    with _CreateWorkspaceFormActions {
  static const _localTarget = '';

  final _name = TextEditingController();
  String _targetAccountId = _localTarget;
  bool _isCreating = false;
  String? _errorText;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CreateWorkspaceAccountView(
      accounts: ref.watch(cloudAccountsProvider),
      name: _name,
      targetAccountId: _targetAccountId,
      errorText: _errorText,
      isCreating: _isCreating,
      onTargetAccountChanged: _setTargetAccount,
      onAddCloudAccount: widget.onAddCloudAccount,
      onCreate: _create,
    );
  }

  void _setTargetAccount(String? accountId) {
    if (accountId == null) return;
    setState(() => _targetAccountId = accountId);
  }

  Future<void> _create() async {
    if (_isCreating) return;

    final name = _name.text.trim();
    _startCreating();
    await _runCreate(name);
  }

  void _startCreating() {
    setState(() {
      _isCreating = true;
      _errorText = null;
    });
  }

  Future<void> _runCreate(String name) async {
    try {
      _handleCreatedWorkspace(await _validateAndCreateWorkspace(name));
    } on AppCloudWorkspaceException catch (error) {
      _setError(error.localizationKey.tr());
    } on WorkspaceException catch (error) {
      _setError(_workspaceError(error));
    } on Object catch (error, stackTrace) {
      _handleUnexpectedCreateError(error, stackTrace);
    } finally {
      _finishCreating();
    }
  }

  Future<WorkspaceEntity> _createLocalWorkspace(String name) =>
      ref.read(createWorkspaceUseCaseProvider).call(name: name);

  Future<WorkspaceEntity> _createCloudWorkspace(String name) async {
    final useCases = await ref.read(
      cloudWorkspaceUseCasesProvider(_targetAccountId).future,
    );
    if (useCases == null) {
      throw const AppCloudWorkspaceException(
        LocaleKeys.workspace_management_unexpected_error,
      );
    }

    return await useCases.create(name);
  }
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
    if (mounted) setState(() => _state._isCreating = false);
  }

  void _handleCreatedWorkspace(WorkspaceEntity workspace) {
    ref.invalidate(allWorkspacesProvider);
    if (_state._targetAccountId != _CreateWorkspaceFormState._localTarget) {
      ref.invalidate(cloudWorkspaceStateProvider(_state._targetAccountId));
    }
    if (mounted) widget.onCreated(workspace);
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
           if (accounts.isEmpty)
             _CloudAccountAction(onAddCloudAccount: onAddCloudAccount),
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
               value: account.userId,
               child: Text(account.email),
             ),
         ],
         value: targetAccountId,
         onChanged: onChanged,
         label: const TextLocale('workspace_management.target_label'),
         isEnabled: isEnabled,
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _CloudAccountAction extends StatelessWidget {
  const new({required this.onAddCloudAccount});

  final VoidCallback? onAddCloudAccount;

  @override
  Widget build(BuildContext context) {
    if (onAddCloudAccount case final onAdd?) {
      return AuraButton(
        onPressed: onAdd,
        child: const TextLocale(LocaleKeys.cloud_accounts_add),
        variant: .outlined,
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
